local addonName, addon = ...
addon.Tests = {}
local tests = addon.Tests

-- One pass over the merchant window, so a build can be checked on each client without clicking through it by hand.
-- /kevutest at an open vendor sets each state through the addon's own functions (filter, page, search, grid size), checks
-- what the frames show (the slots and their items, the page controls, Blizzard's hidden slots, the skins and icons of the
-- plugin addons that are on) and takes a screenshot of each state, with the step named in a banner above the window.
-- Steps that need the mouse (a tooltip, the tabs) wait for the player: the routine never clicks or hovers by itself.
-- The filter, search and grid size are put back at the end; /kevutest again stops early. The last 10 runs are kept in
-- KrowiEVU_Debug.Tests.Runs, which the game writes on the next /reload or logout; .claude/tools/Read-GameTests.ps1
-- prints them with the screenshot of each step.

local prefix = '|cFF1D92C2KEVU test:|r '
local SETTLE = 1.5 -- Seconds from a state change to its screenshot, for item data and plugin skins
local AFTER_SHOT = 1 -- Seconds from a screenshot to the next step
local MOUSE_WAIT = 30 -- Seconds a step that needs the mouse waits
local MOUSE_SETTLE = 0.8 -- Seconds from the mouse action to its screenshot
local KEEP_RUNS = 10

local container = addon.Gui.MerchantItemsContainer
local merchantItemSlot = addon.Gui.MerchantItemSlot
local paging = addon.Gui.Paging
local filters = addon.Filters

local running, armed, startPending, run, current, counts, saved, skins, banner, waitingFor, waitTimer, restTimer
local runToken = 0 -- Bumped by every start, so a stopped run's timers do nothing in the next one
local hookedButtons = {} -- The addon's item buttons, hooked for the tooltip step
local steps

-- [[ Results ]] --
local function Add(status, text)
    counts[status] = counts[status] + 1
    tinsert(current.Lines, status .. ' ' .. text)
end

local function Note(text)
    tinsert(current.Lines, 'INFO ' .. text)
end

local function Join(list)
    return table.concat(list, ',')
end

-- [[ Environment ]] --
local ADDONS = { 'ElvUI', 'GW2_UI', 'EllesmereUI', 'EllesmereUIBlizzardSkin', 'CanIMogIt', 'Auctionator', 'Krowi_Vendorer', 'Plumber' }
local PLUGINS = { 'ElvUI', 'GW2_UI', 'EllesmereUI', 'EllesmereUIItemLevel', 'CanIMogIt' }

-- Which plugin addons have their merchant skin or icons on, read the way the plugins read it
local function GetSkinStates()
    local states = {}
    local elv = ElvUI and ElvUI[1]
    local elvBlizzard = elv and elv.private and elv.private.skins and elv.private.skins.blizzard
    states.ElvUI = elvBlizzard and elvBlizzard.enable and elvBlizzard.merchant and true or false
    local gw = GW2_ADDON
    states.GW2_UI = gw and gw.settings and gw.settings.skins and gw.settings.skins.merchant and gw.settings.skins.merchant.enabled and true or false
    states.EllesmereUI = addon.Util.IsMainline and EllesmereUI and C_AddOns.IsAddOnLoaded('EllesmereUIBlizzardSkin')
        and type(EllesmereUI.GetBlizzWindowStyle) == 'function' and EllesmereUI.GetBlizzWindowStyle('merchant') ~= 'off'
        and not (EllesmereUIDB and EllesmereUIDB.merchantShowAsList) and true or false
    states.EllesmereUIItemLevel = addon.Util.IsMainline and EllesmereUI and C_AddOns.IsAddOnLoaded('EllesmereUIBlizzardSkin')
        and EllesmereUIDB and EllesmereUIDB.merchantShowItemLevel == true or false
    states.CanIMogIt = CIMI_AddToFrame and MerchantFrame_CIMIUpdateIcon and true or false
    return states
end

local function RecordEnvironment()
    local version, build = GetBuildInfo()
    run.Client = version .. ' (' .. build .. ')'
    run.Version = addon.Metadata.Version
    run.Locale = GetLocale()
    local npcName = UnitName('npc')
    if not (issecretvalue and issecretvalue(npcName)) and npcName then
        run.Vendor = npcName
    end
    -- Only recorded: setting a CVar from addon code runs every CVAR_UPDATE handler tainted, Blizzard's status bars included
    run.ScreenshotQuality = C_CVar.GetCVar('screenshotQuality')
    run.Items = GetMerchantNumItems()
    local profile = addon.Options.db.profile
    run.Options = ('%dx%d, %s, Bulk Purchase %s'):format(profile.NumRows, profile.NumColumns, profile.Direction, profile.BulkPurchase.Enabled and 'on' or 'off')
    run.Addons = {}
    for _, name in ipairs(ADDONS) do
        if C_AddOns.IsAddOnLoaded(name) then
            tinsert(run.Addons, name .. ' ' .. tostring(C_AddOns.GetAddOnMetadata(name, 'Version')))
        end
    end
    run.Plugins = {}
    for _, name in ipairs(PLUGINS) do
        if skins[name] then
            tinsert(run.Plugins, name)
        end
    end
end

-- [[ Checks ]] --
local function GetGrid()
    local profile = addon.Options.db.profile
    local indices = container:GetIndices()
    local perPage = profile.NumRows * profile.NumColumns
    return indices, perPage, paging:GetPage(), math.max(1, math.ceil(#indices / perPage))
end

local function GetItemSlot(i)
    return _G['KrowiEVU_MerchantItem' .. i]
end

local function CheckGrid()
    local indices, perPage, page, numPages = GetGrid()
    local first = (page - 1) * perPage
    Note(('%d of %d items in the list, page %d of %d, %d slots a page'):format(#indices, GetMerchantNumItems(), page, numPages, perPage))
    if page > numPages then
        Add('FAIL', ('page %d is past the last page, %d'):format(page, numPages))
    end

    local shown, filled, wrong = 0, 0, {}
    for i = 1, perPage do
        local itemSlot = GetItemSlot(i)
        if itemSlot and itemSlot:IsShown() then
            shown = shown + 1
            local index = indices[first + i]
            if index then
                filled = filled + 1
                local info = merchantItemSlot.GetItemInfo(index)
                if itemSlot.ItemButton:GetID() ~= index or (info and info.name and itemSlot.Name:GetText() ~= info.name) then
                    tinsert(wrong, i)
                end
            end
        end
    end
    local expected = math.max(0, math.min(perPage, #indices - first))
    if shown == perPage and filled == expected and #wrong == 0 then
        Add('PASS', ('grid: %d slots shown, %d with the right item'):format(shown, filled))
    else
        Add('FAIL', ('grid: %d of %d slots shown, %d of %d filled, a wrong item in slots %s'):format(shown, perPage, filled, expected, #wrong > 0 and Join(wrong) or 'none'))
    end

    local extra = {}
    local i = perPage + 1
    while GetItemSlot(i) do
        if GetItemSlot(i):IsShown() then
            tinsert(extra, i)
        end
        i = i + 1
    end
    if #extra > 0 then
        Add('FAIL', 'slots past the grid shown: ' .. Join(extra))
    end
end

local function CheckBlizzardHidden()
    local shown = {}
    for i = 1, BUYBACK_ITEMS_PER_PAGE do
        local itemSlot = _G['MerchantItem' .. i]
        if itemSlot and itemSlot:IsShown() then
            tinsert(shown, i)
        end
    end
    if MerchantPrevPageButton:IsShown() or MerchantNextPageButton:IsShown() or MerchantPageText:IsShown() then
        tinsert(shown, 'page controls')
    end
    if #shown == 0 then
        Add('PASS', 'Blizzard\'s merchant slots and page controls hidden')
    else
        Add('FAIL', 'Blizzard\'s merchant widgets shown: ' .. Join(shown))
    end
end

local function CheckPaging()
    local indices, perPage, page, numPages = GetGrid()
    local shouldShow = #indices > perPage
    local prevButton, nextButton, pageText = KrowiEVU_MerchantPrevPageButton, KrowiEVU_MerchantNextPageButton, KrowiEVU_MerchantPageText
    local ok = pageText:IsShown() == shouldShow and prevButton:IsShown() == shouldShow and nextButton:IsShown() == shouldShow
    local text = pageText:GetText()
    if ok and shouldShow then
        local expectedText = addon.Util.IsMainline and MERCHANT_PAGE_NUMBER:format(page, numPages) or PAGE_NUMBER:format(page)
        ok = text == expectedText and (not not prevButton:IsEnabled()) == (page > 1) and (not not nextButton:IsEnabled()) == (page < numPages)
    end
    Add(ok and 'PASS' or 'FAIL', 'page controls ' .. (shouldShow and ('shown, "' .. tostring(text) .. '"') or 'hidden'))
end

-- Whether a weapon or armour slot shows its item level, as the EllesmereUI plugin writes it on the item button; nil when the
-- slot's item has none to show
local function ShowsItemLevel(button, link)
    local classId = select(6, C_Item.GetItemInfoInstant(link))
    if classId ~= Enum.ItemClass.Weapon and classId ~= Enum.ItemClass.Armor then
        return nil
    end
    local itemLevel = C_Item.GetDetailedItemLevelInfo(link)
    if not itemLevel or itemLevel <= 0 then
        return nil
    end
    for _, region in ipairs({ button:GetRegions() }) do
        if region:IsObjectType('FontString') and region:IsShown() and region:GetText() == tostring(itemLevel) then
            return true
        end
    end
    return false
end

local function CheckPlugins()
    local indices, perPage, page = GetGrid()
    local first = (page - 1) * perPage
    local missing = {}
    for _, name in ipairs(PLUGINS) do
        missing[name] = {}
    end
    local itemLevelSlots = 0
    for i = 1, perPage do
        local itemSlot = GetItemSlot(i)
        if itemSlot and itemSlot:IsShown() then
            local button = itemSlot.ItemButton
            local index = indices[first + i]
            local link = index and GetMerchantItemLink(index)
            if skins.EllesmereUIItemLevel and link then
                local shows = ShowsItemLevel(button, link)
                if shows ~= nil then
                    itemLevelSlots = itemLevelSlots + 1
                    if not shows then
                        tinsert(missing.EllesmereUIItemLevel, i)
                    end
                end
            end
            if skins.ElvUI and not itemSlot.backdrop then
                tinsert(missing.ElvUI, i)
            end
            if skins.GW2_UI and not (button.icon and button.icon.backdrop) then
                tinsert(missing.GW2_UI, i)
            end
            if skins.EllesmereUI and button.IconBorder:GetAlpha() > 0 then
                tinsert(missing.EllesmereUI, i)
            end
            if skins.CanIMogIt and not button.CanIMogItOverlay then
                tinsert(missing.CanIMogIt, i)
            end
        end
    end
    for _, name in ipairs(PLUGINS) do
        if name == 'EllesmereUIItemLevel' and skins[name] then
            if itemLevelSlots == 0 then
                Note('EllesmereUI item levels: no weapon or armour on this page')
            elseif #missing[name] == 0 then
                Add('PASS', ('EllesmereUI item level on all %d weapon and armour slots'):format(itemLevelSlots))
            else
                Add('FAIL', 'EllesmereUI item level missing on slots ' .. Join(missing[name]))
            end
        elseif skins[name] then
            if #missing[name] == 0 then
                Add('PASS', name .. ' on every shown slot')
            else
                Add('FAIL', name .. ' missing on slots ' .. Join(missing[name]))
            end
        end
    end
    if (skins.ElvUI or skins.GW2_UI) and KrowiEVU_MerchantNextPageButton:IsShown() then
        local _, relativeTo = KrowiEVU_MerchantNextPageButton:GetPoint(1)
        Add(relativeTo == KrowiEVU_MerchantPageText and 'PASS' or 'FAIL', 'next page button placed by the skin, next to the page text')
    end
end

local function CheckMerchantTab()
    CheckGrid()
    CheckBlizzardHidden()
    CheckPaging()
    CheckPlugins()
end

local function CheckTooltip()
    -- The item under the mouse at the screenshot, whichever slot the mouse entered first
    local hovered = GameTooltip:IsShown() and GameTooltip:GetOwner()
    if not (hovered and hookedButtons[hovered]) then
        Add('SKIP', 'tooltip: no item tooltip under the mouse at the screenshot')
        return
    end
    local _, link = GameTooltip:GetItem()
    local title = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
    if issecretvalue and (issecretvalue(link) or issecretvalue(title)) then
        Add('SKIP', 'tooltip: its item is a secret value here')
        return
    end
    local tooltipItemId = link and tonumber(link:match('item:(%d+)'))
    local slotItemId = GetMerchantItemID(hovered:GetID())
    local slotName = hovered:GetParent().Name:GetText()
    -- A recipe's tooltip reports the item it teaches through GetItem, so the title counts as well
    local matches = (tooltipItemId and tooltipItemId == slotItemId) or (title and title == slotName)
    Add(matches and 'PASS' or 'FAIL', ('tooltip "%s" (item %s) for the slot "%s" (item %s)'):format(tostring(title), tostring(tooltipItemId), tostring(slotName), tostring(slotItemId)))
end

-- This addon's Lua errors in this session, also from before the run (the first draw, a plugin), as BugGrabber caught them
local function CheckErrors()
    if not (BugGrabber and type(BugGrabber.GetDB) == 'function' and type(BugGrabber.GetSessionId) == 'function') then
        Note('no BugGrabber, so Lua errors are not checked')
        return
    end
    local session = BugGrabber:GetSessionId()
    local found = {}
    for _, err in ipairs(BugGrabber:GetDB()) do
        if err.session == session and ((type(err.message) == 'string' and err.message:find(addonName, 1, true))
            or (type(err.stack) == 'string' and err.stack:find(addonName, 1, true))) then
            tinsert(found, err)
        end
    end
    if #found == 0 then
        Add('PASS', 'no Lua error from this addon this session (BugGrabber)')
        return
    end
    for _, err in ipairs(found) do
        Add('FAIL', ('Lua error x%d: %s'):format(err.counter or 1, tostring(err.message):sub(1, 300)))
    end
end

local function CheckBuyback()
    local shown = {}
    local i = 1
    while GetItemSlot(i) do
        if GetItemSlot(i):IsShown() then
            tinsert(shown, i)
        end
        i = i + 1
    end
    if #shown == 0 and not paging:IsShown() then
        Add('PASS', 'the addon\'s slots and page controls hidden')
    else
        Add('FAIL', 'the addon\'s widgets shown: slots ' .. (#shown > 0 and Join(shown) or 'none') .. (paging:IsShown() and ', page controls' or ''))
    end

    local hidden = {}
    for j = 1, BUYBACK_ITEMS_PER_PAGE do
        if not _G['MerchantItem' .. j]:IsShown() then
            tinsert(hidden, j)
        end
    end
    Add(#hidden == 0 and 'PASS' or 'FAIL', ('Blizzard\'s %d buyback slots shown'):format(BUYBACK_ITEMS_PER_PAGE) .. (#hidden > 0 and (', hidden: ' .. Join(hidden)) or ''))

    local _, relativeTo, _, x, y = MerchantItem1:GetPoint(1)
    local placed = relativeTo == MerchantFrame and math.abs(x - container.FirstOffsetX) < 0.5 and math.abs(y - container.FirstOffsetY) < 0.5
    Add(placed and 'PASS' or 'FAIL', ('buyback slot 1 at %s, %s from the window\'s top left'):format(tostring(x), tostring(y)))
end

-- [[ Choices ]] --
local CUSTOM_FILTERS = { 'TRANSMOG', 'MOUNTS', 'PETS', 'TOYS', 'RECIPES', 'TRANSMOG_SETS', 'ILLUSIONS', 'HOUSING' }

-- The custom filter that keeps the most items while still leaving some out
local function PickFilter()
    local total = GetMerchantNumItems()
    local bestFilter, bestName, bestCount
    for _, name in ipairs(CUSTOM_FILTERS) do
        local filter = _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_' .. name]
        local count = 0
        local ok = pcall(function()
            for i = 1, total do
                local itemId = GetMerchantItemID(i)
                if itemId and filters:Validate(filter, itemId) then
                    count = count + 1
                end
            end
        end)
        if ok and count > 0 and count < total and (not bestCount or count > bestCount) then
            bestFilter, bestName, bestCount = filter, name, count
        end
    end
    return bestFilter, bestName, bestCount
end

-- A word from the item names that matches the most items while still leaving some out
local function PickSearchWord()
    local names = {}
    for i = 1, GetMerchantNumItems() do
        local info = merchantItemSlot.GetItemInfo(i)
        if info and info.name then
            tinsert(names, info.name:lower())
        end
    end
    local bestWord, bestCount
    for i = 1, math.min(#names, 20) do
        for word in names[i]:gmatch('[^%s%p]+') do
            if #word >= 4 then
                local count = 0
                for _, name in ipairs(names) do
                    if name:find(word, 1, true) then
                        count = count + 1
                    end
                end
                if count < #names and (not bestCount or count > bestCount) then
                    bestWord, bestCount = word, count
                end
            end
        end
    end
    return bestWord or (names[1] and names[1]:sub(1, 3))
end

-- [[ Settings ]] --
-- What the options button runs after a grid change
local function ApplyGrid()
    addon.Gui.OptionsButton.UpdateView()
end

local function RestoreGrid()
    local profile = addon.Options.db.profile
    if profile.NumRows ~= saved.Rows or profile.NumColumns ~= saved.Columns then
        profile.NumRows, profile.NumColumns = saved.Rows, saved.Columns
        ApplyGrid()
    end
end

local function Restore()
    RestoreGrid()
    if saved.Filter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] then
        KrowiEVU_SearchBox:SetText(saved.Search)
    end
    KrowiEVU_FilterButton:SetFilter(saved.Filter)
    KrowiEVU_Filters.LastFilter = saved.LastFilter
end

-- [[ Steps ]] --
steps = {
    {
        Name = 'all',
        Text = 'filter All, page 1',
        Run = function()
            KrowiEVU_FilterButton:SetFilter(LE_LOOT_FILTER_ALL)
        end,
    },
    {
        Name = 'page-2',
        Text = 'filter All, page 2',
        Run = function()
            if not (KrowiEVU_MerchantNextPageButton:IsShown() and KrowiEVU_MerchantNextPageButton:IsEnabled()) then
                return 'the list fits on one page'
            end
            KrowiEVU_MerchantNextPageButton:Click()
        end,
    },
    {
        Name = 'filter',
        Run = function()
            local filter, name, count = PickFilter()
            if not filter then
                return 'no custom filter leaves out part of this vendor'
            end
            current.Name = 'filter-' .. name:lower()
            current.Text = ('filter %s (%d items)'):format(name:lower(), count)
            KrowiEVU_FilterButton:SetFilter(filter)
        end,
    },
    {
        Name = 'search',
        Run = function()
            local word = PickSearchWord()
            if not word then
                return 'no item names loaded'
            end
            current.Name = 'search'
            current.Text = 'search "' .. word .. '"'
            KrowiEVU_SearchBox:SetText(word)
            KrowiEVU_FilterButton:SetFilter(_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'])
        end,
    },
    {
        -- A larger grid from the last page: new slots that the plugins have to skin, and a page to move back
        Name = 'grid',
        Run = function()
            KrowiEVU_FilterButton:SetFilter(LE_LOOT_FILTER_ALL)
            container:Update()
            local _, _, _, numPages = GetGrid()
            paging:SetPage(numPages)
            local profile = addon.Options.db.profile
            profile.NumRows, profile.NumColumns = saved.Rows + 1, saved.Columns + 1
            ApplyGrid()
            current.Name = ('grid-%dx%d'):format(profile.NumRows, profile.NumColumns)
            current.Text = ('filter All, %dx%d grid, from page %d'):format(profile.NumRows, profile.NumColumns, numPages)
        end,
    },
    {
        Name = 'grid-back',
        Run = function()
            RestoreGrid()
            current.Text = ('filter All, %dx%d grid again'):format(saved.Rows, saved.Columns)
        end,
    },
    {
        Name = 'tooltip',
        Text = 'hover over an item and keep the mouse still',
        Wait = 'hover',
        Check = CheckTooltip,
    },
    {
        Name = 'buyback',
        Text = 'click the Buyback tab',
        Wait = 'buyback',
        Check = CheckBuyback,
    },
    {
        Name = 'merchant',
        Text = 'click the Merchant tab',
        Wait = 'merchant',
    },
}

-- [[ Runner ]] --
local RunStep, Stop

-- C_Timer.After for the current run only
local function After(seconds, func)
    local token = runToken
    C_Timer.After(seconds, function()
        if running and token == runToken then
            func()
        end
    end)
end

local function NextStep()
    RunStep(current.Step + 1)
end

local function Capture()
    if not running then
        return
    end
    local step = steps[current.Step]
    local ok, err = pcall(step.Check or CheckMerchantTab)
    if not ok then
        Add('FAIL', 'test error: ' .. tostring(err))
    end
    current.Time = date('%H:%M:%S')
    Screenshot()
    After(AFTER_SHOT, NextStep)
end

local function Continue(delay)
    waitingFor = nil
    if waitTimer then
        waitTimer:Cancel()
        waitTimer = nil
    end
    After(delay or MOUSE_SETTLE, Capture)
end

local function Wait(what)
    if what == 'merchant' and MerchantFrame.selectedTab == 1 then
        Note('already on the Merchant tab')
        After(SETTLE, Capture)
        return
    end
    waitingFor = what
    waitTimer = C_Timer.NewTimer(MOUSE_WAIT, function()
        waitTimer = nil
        waitingFor = nil
        Add('SKIP', ('not done within %d s'):format(MOUSE_WAIT))
        NextStep()
    end)
end

-- The screenshot waits until the mouse has rested on one item: on its way there it enters other slots first
local function OnItemButtonEnter(self)
    if waitingFor ~= 'hover' or not self.link then
        return
    end
    if restTimer then
        restTimer:Cancel()
    end
    restTimer = C_Timer.NewTimer(MOUSE_SETTLE, function()
        restTimer = nil
        if waitingFor == 'hover' then
            Continue(0)
        end
    end)
end

local function HookItemSlots()
    local i = 1
    while GetItemSlot(i) do
        local button = GetItemSlot(i).ItemButton
        if not hookedButtons[button] then
            hookedButtons[button] = true
            button:HookScript('OnEnter', OnItemButtonEnter)
        end
        i = i + 1
    end
end

local blizzardHooked
local function HookBlizzard()
    if blizzardHooked then
        return
    end
    blizzardHooked = true
    hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function()
        if waitingFor == 'buyback' then
            Continue()
        end
    end)
    hooksecurefunc('MerchantFrame_UpdateMerchantInfo', function()
        if waitingFor == 'merchant' and MerchantFrame.selectedTab == 1 then
            Continue()
        end
    end)
end

local function SetBanner(text)
    banner.Text:SetText(('Extended Vendor UI test %d/%d: %s'):format(current.Step, #steps, text))
end

RunStep = function(n)
    if not running then
        return
    end
    local step = steps[n]
    if not step then
        Stop()
        return
    end
    current = { Step = n, Name = step.Name, Lines = {} }
    tinsert(run.Steps, current)
    local ok, skip = true, nil
    if step.Run then
        ok, skip = pcall(step.Run)
    end
    if not ok then
        Add('FAIL', 'test error: ' .. tostring(skip))
        skip = 'the step failed'
    end
    current.Text = current.Text or step.Text
    SetBanner(skip and ('skipped, ' .. skip) or current.Text or current.Name)
    if skip then
        if ok then
            Add('SKIP', skip)
        end
        After(0, NextStep)
    elseif step.Wait then
        if step.Wait == 'hover' then
            HookItemSlots()
        end
        Wait(step.Wait)
    else
        After(SETTLE, Capture)
    end
end

local function GetBanner()
    if banner then
        return banner
    end
    banner = CreateFrame('Frame', nil, UIParent)
    banner:SetFrameStrata('DIALOG')
    banner:SetSize(520, 26)
    banner:SetPoint('BOTTOM', MerchantFrame, 'TOP', 0, 6)
    local background = banner:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints()
    background:SetColorTexture(0, 0, 0, 0.85)
    banner.Text = banner:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    banner.Text:SetPoint('CENTER')
    banner:SetScript('OnEvent', function(_, event)
        if event == 'MERCHANT_SHOW' then
            banner:UnregisterEvent('MERCHANT_SHOW')
            armed = nil
            startPending = true -- /kevutest still cancels until the start
            C_Timer.After(SETTLE, function() -- After the window's first draw
                if startPending then
                    startPending = nil
                    tests.Start()
                end
            end)
        elseif event == 'MERCHANT_CLOSED' then
            Stop('the vendor window closed')
        elseif event == 'PLAYER_REGEN_DISABLED' then
            Stop('combat started')
        elseif event == 'SCREENSHOT_SUCCEEDED' then
            current.Screenshot = true
        elseif event == 'SCREENSHOT_FAILED' then
            current.Screenshot = false
        end
    end)
    banner:Hide()
    return banner
end

Stop = function(reason)
    if not running then
        return
    end
    running = false
    waitingFor = nil
    if waitTimer then
        waitTimer:Cancel()
        waitTimer = nil
    end
    if restTimer then
        restTimer:Cancel()
        restTimer = nil
    end
    banner:UnregisterAllEvents()
    banner:Hide()
    run.Stopped = reason
    local ok, err = pcall(Restore)
    if not ok then
        run.RestoreError = tostring(err)
        print(prefix .. '|cFFFF0000could not put the settings back:|r ' .. tostring(err))
    end
    current = { Step = #run.Steps + 1, Name = 'errors', Text = 'Lua errors this session', Lines = {} }
    tinsert(run.Steps, current)
    ok, err = pcall(CheckErrors)
    if not ok then
        Add('FAIL', 'test error: ' .. tostring(err))
    end
    run.Passed, run.Failed, run.Skipped = counts.PASS, counts.FAIL, counts.SKIP

    for _, step in ipairs(run.Steps) do
        for _, line in ipairs(step.Lines) do
            if line:find('^FAIL') then
                print(prefix .. '|cFFFF0000' .. step.Name .. ': ' .. line .. '|r')
            end
        end
    end
    print(prefix .. ('%s%d passed, %d failed, %d skipped. /reload to save the results.'):format(reason and (reason .. '; ') or '', counts.PASS, counts.FAIL, counts.SKIP))
end

function tests.Start()
    if running then
        return
    end
    if InCombatLockdown() then
        print(prefix .. 'not in combat')
        return
    end
    if not MerchantFrame:IsShown() then
        armed = true
        GetBanner():RegisterEvent('MERCHANT_SHOW')
        print(prefix .. 'starts when you open a vendor; /kevutest again cancels')
        return
    end
    if MerchantFrame.selectedTab ~= 1 then
        print(prefix .. 'switch to the Merchant tab, then /kevutest again')
        return
    end
    if GetMerchantNumItems() == 0 then
        print(prefix .. 'this vendor sells nothing')
        return
    end

    HookBlizzard()
    skins = GetSkinStates()
    counts = { PASS = 0, FAIL = 0, SKIP = 0 }
    local profile = addon.Options.db.profile
    saved = {
        Filter = filters:GetFilter(),
        Search = KrowiEVU_SearchBox:GetText(),
        LastFilter = KrowiEVU_Filters.LastFilter,
        Rows = profile.NumRows,
        Columns = profile.NumColumns,
    }

    run = { Time = date('%Y-%m-%d %H:%M:%S'), Steps = {} }
    RecordEnvironment()
    -- Kept as a history: Krowi runs several in a row (one per skin addon, a reload between each) before they are read
    KrowiEVU_Debug = KrowiEVU_Debug or {}
    KrowiEVU_Debug.Tests = KrowiEVU_Debug.Tests or {}
    local runs = KrowiEVU_Debug.Tests.Runs or { KrowiEVU_Debug.Tests.LastRun } -- LastRun: the one run kept before Runs
    KrowiEVU_Debug.Tests.LastRun = nil
    KrowiEVU_Debug.Tests.Runs = runs
    tinsert(runs, run)
    while #runs > KEEP_RUNS do
        tremove(runs, 1)
    end

    GetBanner():Show()
    banner:RegisterEvent('MERCHANT_CLOSED')
    banner:RegisterEvent('PLAYER_REGEN_DISABLED')
    banner:RegisterEvent('SCREENSHOT_SUCCEEDED')
    banner:RegisterEvent('SCREENSHOT_FAILED')
    running = true
    runToken = runToken + 1
    print(prefix .. ('%d steps, about 15 s, then three that need the mouse; /kevutest again stops it'):format(#steps))
    RunStep(1)
end

SLASH_KEVUTEST1 = '/kevutest'
SlashCmdList.KEVUTEST = function()
    if running then
        Stop('stopped with /kevutest')
    elseif armed or startPending then
        armed, startPending = nil, nil
        banner:UnregisterEvent('MERCHANT_SHOW')
        print(prefix .. 'cancelled')
    else
        tests.Start()
    end
end
local addonName, addon = ...
if addon.NotLoaded then return end
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
local hookedTokens = {} -- The token banner's buttons, hooked for the currency step
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
local ADDONS = { 'ElvUI', 'GW2_UI', 'EllesmereUI', 'EllesmereUIBlizzardSkin', 'CanIMogIt', 'TransmogLootHelper', 'Auctionator', 'Krowi_Vendorer', 'Plumber', 'Scrap' }
local PLUGINS = { 'ElvUI', 'GW2_UI', 'EllesmereUI', 'EllesmereUIItemLevel', 'CanIMogIt', 'TransmogLootHelper' }

-- The Krowi_Util client flags and the ones each client's WOW_PROJECT_ID should make true; the expansion flags follow the
-- Retail patch, so they are recorded but not checked
local CLIENT_FLAGS = { 'IsMainline', 'IsForever', 'IsModern', 'IsMistsClassic', 'IsCataClassic', 'IsWrathClassic', 'IsBCCClassic', 'IsClassicEra', 'IsClassicWithAchievements' }
local EXPANSION_FLAGS = { 'IsTheWarWithin', 'IsMidnight' }
local EXPECTED_FLAGS = {
    [1] = { IsMainline = true, IsModern = true }, -- Retail
    [19] = { IsMistsClassic = true, IsClassicWithAchievements = true }, -- Mists Classic
    [11] = { IsWrathClassic = true, IsClassicWithAchievements = true }, -- Titan Reforged
    [5] = { IsBCCClassic = true }, -- TBC Anniversary
    [2] = { IsClassicEra = true }, -- Classic Era
    [18] = { IsClassicEra = true, IsForever = true, IsModern = true }, -- WoW Forever: a 1.x build that runs Retail's interface
}

-- Which plugin addons have their merchant skin or icons on, read the way the plugins read it
local function GetSkinStates()
    local states = {}
    -- The ElvUI and GW2_UI plugins do nothing on WoW Forever (Plugins/ElvUI.lua, GW2_UI.lua), so no skin is expected there
    local elv = not addon.Util.IsForever and ElvUI and ElvUI[1]
    local elvBlizzard = elv and elv.private and elv.private.skins and elv.private.skins.blizzard
    states.ElvUI = elvBlizzard and elvBlizzard.enable and elvBlizzard.merchant and true or false
    local gw = not addon.Util.IsForever and GW2_ADDON
    states.GW2_UI = gw and gw.settings and gw.settings.skins and gw.settings.skins.merchant and gw.settings.skins.merchant.enabled and true or false
    states.EllesmereUI = addon.Util.IsMainline and EllesmereUI and C_AddOns.IsAddOnLoaded('EllesmereUIBlizzardSkin')
        and type(EllesmereUI.GetBlizzWindowStyle) == 'function' and EllesmereUI.GetBlizzWindowStyle('merchant') ~= 'off'
        and not (EllesmereUIDB and EllesmereUIDB.merchantShowAsList) and true or false
    states.EllesmereUIItemLevel = addon.Util.IsMainline and EllesmereUI and C_AddOns.IsAddOnLoaded('EllesmereUIBlizzardSkin')
        and EllesmereUIDB and EllesmereUIDB.merchantShowItemLevel == true or false
    states.CanIMogIt = CIMI_AddToFrame and MerchantFrame_CIMIUpdateIcon and true or false
    -- Its overlay can be off in its own settings, which are private; then this check fails and says so
    states.TransmogLootHelper = TransmogLootHelper and C_AddOns.IsAddOnLoaded('TransmogLootHelper') and true or false
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
    run.Flags = {}
    for _, list in ipairs({ CLIENT_FLAGS, EXPANSION_FLAGS }) do
        for _, name in ipairs(list) do
            if addon.Util[name] then
                tinsert(run.Flags, name)
            end
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
    if MerchantPageTurnIndicatorLeft and (MerchantPageTurnIndicatorLeft:IsShown() or MerchantPageTurnIndicatorRight:IsShown()) then
        tinsert(shown, 'gamepad page arrows') -- WoW Forever's gamepad interface style
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
        local expectedText = addon.Util.IsModern and MERCHANT_PAGE_NUMBER:format(page, numPages) or PAGE_NUMBER:format(page)
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
            if skins.TransmogLootHelper and index and not button.TLHOverlay then
                tinsert(missing.TransmogLootHelper, i)
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

-- 'currency:<id>' or 'item:<id>' from a cost link, so links that differ only in their colour or level still match
local function GetCostKey(link)
    return link:match('(currency:%d+)') or link:match('(item:%d+)')
end

local function GetCostName(key)
    local kind, id = key:match('^(%a+):(%d+)$')
    if kind == 'currency' then
        local info = C_CurrencyInfo.GetCurrencyInfo(tonumber(id))
        return (info and info.name or key) .. ' (' .. key .. ')'
    end
    return (C_Item.GetItemInfo(tonumber(id)) or key) .. ' (' .. key .. ')'
end

-- How much of a cost the player has, the way the token banner reads it
local function GetHaveAmount(key)
    local kind, id = key:match('^(%a+):(%d+)$')
    if kind == 'currency' then
        local info = C_CurrencyInfo.GetCurrencyInfo(tonumber(id))
        return info and info.quantity
    end
    return C_Item.GetItemCount(tonumber(id), true, false, true, true)
end

-- The currencies Blizzard's own row shows for this vendor
local function GetVendorCurrencies()
    if C_MerchantFrame and C_MerchantFrame.GetMerchantCurrencies then
        return C_MerchantFrame.GetMerchantCurrencies() or {}
    end
    return GetMerchantCurrencies and { GetMerchantCurrencies() } or {}
end

-- The token banner against the costs of the items in the list, worked out here the way the banner should: each cost shown
-- once and nothing left from an earlier vendor or list, the token banner options followed. With the whole vendor in the
-- list, also every currency Blizzard's own row shows.
local function CheckTokenBanner()
    -- Shown is not enough: the banner is a child of Blizzard's MerchantMoneyInset, which another addon can hide (Plumber's
    -- Merchant Price before 1.9.7 moved it into a hidden frame of its own)
    if KrowiEVU_TokenBanner:IsVisible() then
        Add('PASS', 'token banner visible')
    else
        Add('FAIL', 'token banner not visible')
    end

    local options = addon.Options.db.profile.TokenBanner
    local indices = container:GetIndices()
    local gold, costs = 0, {}
    for _, index in ipairs(indices) do
        local info = merchantItemSlot.GetItemInfo(index)
        if info and info.price and info.price > 0 then -- Gold, also next to a currency (live MerchantFrame.lua:307)
            gold = gold + info.price
        end
        for costIndex = 1, GetMerchantItemCostInfo(index) or 0 do
            local texture, value, link = GetMerchantItemCostItem(index, costIndex)
            local key = texture and value and link and GetCostKey(link)
            if key then
                costs[key] = (costs[key] or 0) + value
            end
        end
    end

    local shownGold, shown = false, {}
    local i = 1
    while _G['KrowiEVU_TokenBannerToken' .. i] do
        local token = _G['KrowiEVU_TokenBannerToken' .. i]
        if token:IsShown() then
            if token.IsGold then
                shownGold = true
                -- Gold total off: only the gold the player has
                if not options.GoldTotal then
                    local text = token.Text:GetText()
                    Add(text and token.Have and text:find(token.Have, 1, true) == 1 and 'PASS' or 'FAIL', ('Gold total off: the gold token shows "%s", the gold you have is "%s"'):format(tostring(text), tostring(token.Have)))
                end
            elseif token.Link then
                local key = GetCostKey(token.Link) or token.Link
                shown[key] = (shown[key] or 0) + 1
            end
        end
        i = i + 1
    end

    local costNames, missing, extra = {}, {}, {}
    for key, value in next, costs do
        tinsert(costNames, GetCostName(key) .. ' x' .. value)
        if options.HideNone and key:find('^currency:') and GetHaveAmount(key) == 0 then -- Hide currencies you have none of
            if shown[key] then
                tinsert(extra, GetCostName(key) .. ', which you have none of')
            end
        elseif shown[key] ~= 1 then
            tinsert(missing, GetCostName(key) .. (shown[key] and (' shown ' .. shown[key] .. ' times') or ''))
        end
    end
    for key in next, shown do
        if not costs[key] then
            tinsert(extra, GetCostName(key))
        end
    end
    table.sort(costNames)
    Note(('costs of the %d items in the list: gold %d%s'):format(#indices, gold, #costNames > 0 and (', ' .. table.concat(costNames, ', ')) or ''))
    if (gold > 0) ~= shownGold then
        tinsert(gold > 0 and missing or extra, 'gold')
    end
    if #missing == 0 and #extra == 0 then
        Add('PASS', 'token banner: every cost of the list, nothing else')
    else
        Add('FAIL', ('token banner: missing %s; shown but should not be %s'):format(#missing > 0 and table.concat(missing, ', ') or 'none', #extra > 0 and table.concat(extra, ', ') or 'none'))
    end

    if #indices == GetMerchantNumItems() then
        local notCosts = {}
        for _, currencyId in ipairs(GetVendorCurrencies()) do
            if not costs['currency:' .. currencyId] then
                tinsert(notCosts, GetCostName('currency:' .. currencyId))
            end
        end
        if #notCosts > 0 then
            Add('FAIL', 'token banner: Blizzard\'s currency row would show ' .. table.concat(notCosts, ', ') .. ', which no item in the list costs')
        end
    end
end

-- The server sends the vendor's list for the merchant filter it was given; the addon's own filters must not lose items
-- there that filter All gets (the count under All is taken in the step that sets it)
local function CheckServerList()
    local filter = filters:GetFilter()
    local count = GetMerchantNumItems()
    if filter == LE_LOOT_FILTER_ALL then
        run.ServerAll = count
        return
    end
    Note(('the server sends %d items for filter %s'):format(count, tostring(filter)))
    if filter >= _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_NEW_RANGE'] and run.ServerAll then
        Add(count >= run.ServerAll and 'PASS' or 'FAIL', ('server list for the addon\'s filter %d: %d items, %d for All'):format(filter, count, run.ServerAll))
    end
end

-- Hide collected, Housing: decor the player owns anywhere (in storage, placed or not yet redeemed) is hidden, the rest shown
local function CheckHousing()
    if not addon.Util.IsMainline or filters:GetFilter() ~= LE_LOOT_FILTER_ALL then
        return
    end
    local inList = {}
    for _, index in ipairs(container:GetIndices()) do
        inList[index] = true
    end
    local profile = filters.db.profile
    local decor, wrong = 0, {}
    for index = 1, GetMerchantNumItems() do
        local itemId = GetMerchantItemID(index)
        local entry = itemId and filters.IsHousing(itemId) and C_HousingCatalog.GetCatalogEntryInfoByItem(itemId)
        if entry then
            decor = decor + 1
            local stored, placed, redeemable = entry.totalNumStored or 0, entry.totalNumPlaced or 0, entry.remainingRedeemable or 0
            local shown = inList[index] or false
            if placed > 0 then
                Note(('decor %s: %d stored, %d placed, %d to redeem, %s'):format(entry.name, stored, placed, redeemable, shown and 'shown' or 'hidden'))
            end
            if profile.HideCollected.Housing and (stored + placed + redeemable >= profile.HousingQuantity) == shown then
                tinsert(wrong, ('%s (%d owned, %s)'):format(entry.name, stored + placed + redeemable, shown and 'shown' or 'hidden'))
            end
        end
    end
    if decor == 0 then
        return
    end
    if not profile.HideCollected.Housing then
        Note(('%d decor items; Hide collected, Housing is off'):format(decor))
    elseif #wrong == 0 then
        Add('PASS', ('Hide collected, Housing: %d decor items, owned ones (%d or more) hidden'):format(decor, profile.HousingQuantity))
    else
        Add('FAIL', 'Hide collected, Housing wrong for ' .. table.concat(wrong, ', '))
    end
end

-- The recipe record behind Hide collected, Recipes my other characters know, under filter All
local function CheckRecipes()
    if not addon.Util.IsModern or filters:GetFilter() ~= LE_LOOT_FILTER_ALL then
        return
    end
    local inList = {}
    for _, index in ipairs(container:GetIndices()) do
        inList[index] = true
    end
    local recipes, byOthers, wrong = 0, 0, {}
    for index = 1, GetMerchantNumItems() do
        local itemId = GetMerchantItemID(index)
        if itemId and filters.IsRecipe(itemId) then
            recipes = recipes + 1
            if filters.IsRecipeKnownByOtherCharacter(itemId) then
                byOthers = byOthers + 1
                if filters.db.profile.HideCollected.RecipesOtherCharacters and inList[index] then
                    tinsert(wrong, (C_Item.GetItemInfo(itemId)) or tostring(itemId))
                end
            end
        end
    end
    if recipes == 0 then
        return
    end
    local characters = 0
    for _ in next, filters.db.global.KnownRecipes or {} do
        characters = characters + 1
    end
    Note(('%d recipes; %d known by another of the %d characters recorded'):format(recipes, byOthers, characters))
    if filters.db.profile.HideCollected.RecipesOtherCharacters then
        Add(#wrong == 0 and 'PASS' or 'FAIL', 'Recipes my other characters know: ' .. (#wrong == 0 and 'none of theirs shown' or ('shown ' .. table.concat(wrong, ', '))))
    end
end

-- The illusions the account has, by lower-case name, from the collection itself: no API maps an item to its illusion, so
-- this backs up the filter's tooltip check where the names match
local function GetCollectedIllusionsByName()
    local byName = {}
    if not (C_TransmogCollection and C_TransmogCollection.GetIllusions) then
        return byName
    end
    for _, illusion in ipairs(C_TransmogCollection.GetIllusions() or {}) do
        local name = C_TransmogCollection.GetIllusionStrings(illusion.sourceID)
        if name and not (issecretvalue and issecretvalue(name)) then
            byName[name:lower()] = illusion.isCollected
        end
    end
    return byName
end

local function DescribeTooltipLines(itemId)
    local tooltipInfo = C_TooltipInfo.GetItemByID(itemId)
    if not tooltipInfo then
        return 'no tooltip data'
    end
    local lines = {}
    for _, line in ipairs(tooltipInfo.lines) do
        local text = line.leftText
        if issecretvalue and issecretvalue(text) then
            text = '<secret>'
        end
        tinsert(lines, ('%s:%s'):format(tostring(line.type), tostring(text):sub(1, 40)))
    end
    return table.concat(lines, ' | ')
end

-- Hide collected, Illusions under filter All, which the step turned on: an illusion the filter finds collected (Blizzard's
-- Already known line) is hidden, the rest shown. The tooltip lines of the first few are noted, since only the game shows
-- what Blizzard puts there (illusions-hide-collected)
local MAX_TOOLTIP_NOTES = 4
local function CheckIllusions()
    local inList = {}
    for _, index in ipairs(container:GetIndices()) do
        inList[index] = true
    end
    local byName = GetCollectedIllusionsByName()
    local illusions, collected, matched, noted, wrong, disagree = 0, 0, 0, 0, {}, {}
    for index = 1, GetMerchantNumItems() do
        local itemId = GetMerchantItemID(index)
        if itemId and filters.IsIllusion(itemId) then
            illusions = illusions + 1
            local isCollected = filters.IsIllusionCollected(itemId)
            local shown = inList[index] or false
            local info = merchantItemSlot.GetItemInfo(index)
            local name = info and info.name or tostring(itemId)
            if isCollected then
                collected = collected + 1
            end
            if isCollected == shown and #wrong < 10 then
                tinsert(wrong, ('%s (%s, %s)'):format(name, isCollected and 'collected' or 'not collected', shown and 'shown' or 'hidden'))
            end
            -- Item names read "Illusion: Mongoose"; the collection may name it either way
            local inCollection = byName[name:lower()]
            if inCollection == nil then
                inCollection = byName[name:lower():match(':%s*(.+)$') or '']
            end
            if inCollection ~= nil then
                matched = matched + 1
                if inCollection ~= isCollected then
                    tinsert(disagree, ('%s (collection: %s, tooltip: %s)'):format(name, tostring(inCollection), tostring(isCollected)))
                end
            end
            if noted < MAX_TOOLTIP_NOTES then
                noted = noted + 1
                Note(('%s (item %d, %s, collected by name: %s): %s'):format(name, itemId, isCollected and 'Already known' or 'not known', tostring(inCollection), DescribeTooltipLines(itemId)))
            end
        end
    end
    Note(('%d consumables of type Other (what the Illusions filter takes as illusions), %d Already known, %d found in the collection by name'):format(illusions, collected, matched))
    Add(#wrong == 0 and 'PASS' or 'FAIL', 'Hide collected, Illusions: ' .. (#wrong == 0 and 'Already known ones hidden, the rest shown' or ('wrong for ' .. table.concat(wrong, ', '))))
    if #disagree > 0 then
        Add('FAIL', 'Illusions: the tooltip and the collection disagree for ' .. table.concat(disagree, ', '))
    elseif matched > 0 then
        Add('PASS', ('Illusions: the tooltip agrees with the collection for the %d found there by name'):format(matched))
    end
end

-- Retail's new-player tutorial points its buy arrow at Blizzard's hidden MerchantItem2 (live Blizzard_TutorialTutorials.lua
-- :2397); with Direction Rows the addon's slot 2 sits in the same place (tutorial-buy-arrow)
local function CheckTutorialArrow()
    if not addon.Util.IsModern then
        return
    end
    local slot = GetItemSlot(2)
    local left, top = MerchantItem2:GetLeft(), MerchantItem2:GetTop()
    local slotLeft, slotTop = slot and slot:GetLeft(), slot and slot:GetTop()
    if not (left and top and slotLeft and slotTop) then
        Add('SKIP', 'tutorial arrow: MerchantItem2 or the addon\'s slot 2 has no position')
        return
    end
    local same = math.abs(left - slotLeft) < 1 and math.abs(top - slotTop) < 1
    local text = ('tutorial arrow: MerchantItem2 at %.0f, %.0f, the addon\'s slot 2 at %.0f, %.0f'):format(left, top, slotLeft, slotTop)
    if addon.Options.db.profile.Direction == 'Columns' then
        Note(text .. ', Direction Columns')
    else
        Add(same and 'PASS' or 'FAIL', text)
    end
end

-- Bulk Purchase's room in the bags for the vendor's first item, worked out as a shift-click does, without buying. Bag 5 is
-- Retail's reagent bag, whose slot the lookup before 24.2 asked for as Bag4Slot, which does not exist
local function CheckBulkPurchase()
    local index, itemId
    for i = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(i)
        local id = link and tonumber(link:match('item:(%d+)'))
        if id then
            index, itemId = i, id
            break
        end
    end
    if not index then
        Add('SKIP', 'Bulk Purchase: no item at this vendor')
        return
    end
    local bags = {}
    for bag = 0, addon.Util.IsModern and 5 or 4 do
        local free, bagType = C_Container.GetContainerNumFreeSlots(bag)
        local text = ('%d: %s free, type %s'):format(bag, tostring(free), tostring(bagType))
        if bag > 0 then
            -- WoW Forever's 1.x build may have no bag 5
            local ok, slot = pcall(C_Container.ContainerIDToInventoryID, bag)
            if not ok then
                text = text .. ', no slot: ' .. tostring(slot)
            else
                text = text .. (', slot %s %s'):format(tostring(slot), slot and GetInventoryItemID('player', slot) and 'with a bag' or 'empty')
            end
        end
        tinsert(bags, text)
    end
    Note('bags ' .. table.concat(bags, '; '))
    if addon.Util.IsModern and C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo then
        local ok, slot = pcall(C_PaperDollInfo.GetInventorySlotInfo, 'Bag4Slot')
        Note('the lookup before 24.2 for bag 5, Bag4Slot: ' .. (ok and ('slot ' .. tostring(slot)) or ('error ' .. tostring(slot))))
    end
    local mixin = KrowiEVU_BulkPurchaseMixin
    local savedIndex = mixin.itemIndex
    mixin.itemIndex = index
    local ok, fit, stack = pcall(mixin.GetFreeBagSpace, mixin, itemId)
    mixin.itemIndex = savedIndex
    if ok then
        Add('PASS', ('Bulk Purchase: room for %s of item %d (stack %s)'):format(tostring(fit), itemId, tostring(stack)))
    else
        Add('FAIL', 'Bulk Purchase bag space: ' .. tostring(fit))
    end
end

-- A click on a currency in the token banner opens the character window on its tab with currencies: Currency on Retail,
-- Forever and Mists, PvP on TBC; Era has neither, so nothing opens (classic-currency-click)
local characterShownBefore
local function CheckCurrencyClick()
    if characterShownBefore then
        Add('SKIP', 'currency click: the character window was open before the click')
        return
    end
    local subframes = CHARACTERFRAME_SUBFRAMES or {}
    local getCurrencyListSize = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize or GetCurrencyListSize
    local expected
    if addon.Util.IsModern or tContains(subframes, 'TokenFrame') then
        expected = getCurrencyListSize() > 0 and 'TokenFrame' or nil
    elseif tContains(subframes, 'PVPFrame') then
        expected = 'PVPFrame'
    end
    local shown = CharacterFrame:IsShown()
    if not expected then
        Add(shown and 'FAIL' or 'PASS', 'currency click: ' .. (shown and 'the character window opened, though there is no tab to open' or 'nothing opens, as there is no tab to open'))
        return
    end
    local tab = _G[expected]
    local tabShown = tab and tab:IsVisible() or false
    Add(shown and tabShown and 'PASS' or 'FAIL', ('currency click: the character window %s, %s %s'):format(shown and 'opened' or 'did not open', expected, tabShown and 'shown' or 'not shown'))
end

-- The best armor each class wears (Cloth 1, Leather 2, Mail 3, Plate 4), and the one it wears before level 40 where the
-- client has the old proficiencies; written out here so the check does not use the filter's own proficiency spells
local CLASS_ARMOR = {
    WARRIOR = { 4, 3 }, PALADIN = { 4, 3 }, DEATHKNIGHT = { 4, 4 },
    HUNTER = { 3, 2 }, SHAMAN = { 3, 2 }, EVOKER = { 3, 3 },
    ROGUE = { 2, 2 }, DRUID = { 2, 2 }, MONK = { 2, 2 }, DEMONHUNTER = { 2, 2 },
    MAGE = { 1, 1 }, PRIEST = { 1, 1 }, WARLOCK = { 1, 1 },
}

-- The Gear options against every weapon and armor piece of the vendor: none that breaks one is in the list
local function CheckGear()
    local gear = filters.db.profile.Gear
    local best = filters:GetBestArmorSubClass()
    Note('best armor known: ' .. (best and C_Item.GetItemSubClassInfo(Enum.ItemClass.Armor, best) or 'cloth only, or no armor proficiency found'))
    -- Retail learns every proficiency at once; WoW Forever's rules are unknown, so only noted there
    local classArmor = CLASS_ARMOR[select(2, UnitClass('player'))]
    if classArmor and not addon.Util.IsForever then
        local expected = (addon.Util.IsMainline or UnitLevel('player') >= 40) and classArmor[1] or classArmor[2]
        local actual = best or 1
        Add(actual == expected and 'PASS' or 'FAIL', ('best armor %d for this class and level, %d found from the proficiencies (1 cloth to 4 plate)'):format(expected, actual))
    end
    local inList = {}
    for _, index in ipairs(container:GetIndices()) do
        inList[index] = true
    end
    local pieces, hidden, wrong = 0, 0, {}
    for index = 1, GetMerchantNumItems() do
        local itemId = GetMerchantItemID(index)
        local _, _, _, equipLoc, _, classId, subClassId = C_Item.GetItemInfoInstant(itemId or 0)
        if itemId and (classId == Enum.ItemClass.Armor or classId == Enum.ItemClass.Weapon) then
            pieces = pieces + 1
            local info = merchantItemSlot.GetItemInfo(index)
            local quality = C_Item.GetItemQualityByID(itemId)
            local breaks = (gear.UsableOnly and info and info.name and not info.isUsable)
                or (best and gear.HideSubOptimalArmor and classId == Enum.ItemClass.Armor and subClassId >= 1 and subClassId < best and equipLoc ~= 'INVTYPE_CLOAK')
                or (gear.MinQuality > 0 and quality and quality < gear.MinQuality)
            if not inList[index] then
                hidden = hidden + 1
            elseif breaks then
                tinsert(wrong, info and info.name or tostring(itemId))
            end
        end
    end
    if pieces == 0 then
        Add('SKIP', 'Gear: this vendor sells no weapons or armor')
        return
    end
    Add(#wrong == 0 and 'PASS' or 'FAIL', ('Gear: %d of %d weapon and armor pieces hidden'):format(hidden, pieces) .. (#wrong > 0 and ('; shown though they should not be: ' .. table.concat(wrong, ', ')) or ''))
end

-- Scrap's merchant button on the Classic clients (#80, Plugins/Scrap.lua): inside the window, and Blizzard's repair-all
-- button with this addon's one anchor, not Scrap's second
local function CheckScrap()
    local button = not addon.Util.IsModern and C_AddOns.IsAddOnLoaded('Scrap') and Scrap and Scrap.Merchant
    if not (button and button:IsVisible()) then
        return
    end
    local placed = KrowiEVU.PluginsApi.Plugins.Scrap.LastPlaced
    if placed then
        Note(('Scrap had anchored its button to %s and the repair-all button had %d anchor(s), before the plugin placed them'):format(tostring(placed.ScrapAnchor), placed.RepairAllPoints))
    end
    local left, right, frameLeft, frameRight = button:GetLeft(), button:GetRight(), MerchantFrame:GetLeft(), MerchantFrame:GetRight()
    if not (left and right and frameLeft and frameRight) then
        Add('SKIP', 'Scrap: its button has no position')
        return
    end
    local scale, frameScale = button:GetEffectiveScale(), MerchantFrame:GetEffectiveScale()
    local inside = left * scale >= frameLeft * frameScale - 1 and right * scale <= frameRight * frameScale + 1
    Add(inside and 'PASS' or 'FAIL', 'Scrap: its button is ' .. (inside and 'inside' or 'outside') .. ' the window')
    if MerchantRepairAllButton:IsShown() then
        local points = MerchantRepairAllButton:GetNumPoints()
        Add(points == 1 and 'PASS' or 'FAIL', ('Scrap: the repair-all button has %d anchor(s)'):format(points))
    end
end

local function CheckMerchantTab()
    CheckGrid()
    CheckBlizzardHidden()
    CheckPaging()
    CheckPlugins()
    CheckTokenBanner()
    CheckServerList()
    CheckHousing()
    CheckRecipes()
    CheckScrap()
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

-- Krowi_Util's client flags against the ones this client's project id should give, so every client's run shows that a
-- Krowi_Util change kept the flags other addons read
local function CheckClientFlags()
    local expected = EXPECTED_FLAGS[WOW_PROJECT_ID]
    if not expected then
        Note(('no expected client flags for project %s'):format(tostring(WOW_PROJECT_ID)))
        return
    end
    local wrong = {}
    for _, name in ipairs(CLIENT_FLAGS) do
        local value = addon.Util[name]
        if (value and true or false) ~= (expected[name] or false) then
            tinsert(wrong, name .. '=' .. tostring(value))
        end
    end
    if #wrong == 0 then
        Add('PASS', ('client flags for project %d: %s'):format(WOW_PROJECT_ID, table.concat(run.Flags, ', ')))
    else
        Add('FAIL', ('client flags for project %d wrong: %s'):format(WOW_PROJECT_ID, Join(wrong)))
    end
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

-- The Gear and token banner options the steps change
local function RestoreOptions()
    local gear = filters.db.profile.Gear
    gear.UsableOnly, gear.HideSubOptimalArmor, gear.MinQuality = saved.Gear.UsableOnly, saved.Gear.HideSubOptimalArmor, saved.Gear.MinQuality
    local tokenBanner = addon.Options.db.profile.TokenBanner
    tokenBanner.GoldTotal, tokenBanner.HideNone = saved.GoldTotal, saved.HideNone
    filters.db.profile.HideCollected.Illusions = saved.HideIllusions
end

local function Restore()
    RestoreOptions()
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
        -- Before the test changes anything: the vendor's first draw when /kevutest was typed before opening it
        Name = 'opened',
        Text = 'the window as it opened',
        Run = function()
            Note(run.OnOpen and 'started as the vendor opened: this is the first draw' or 'started at an open vendor: not its first draw')
        end,
    },
    {
        Name = 'all',
        Text = 'filter All, page 1',
        Run = function()
            KrowiEVU_FilterButton:SetFilter(LE_LOOT_FILTER_ALL)
        end,
        Check = function()
            CheckMerchantTab()
            CheckTutorialArrow()
            CheckBulkPurchase()
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
        Name = 'gear',
        Text = 'filter All, Gear: only usable items, no sub-optimal armor, Uncommon or better',
        Run = function()
            local gear = filters.db.profile.Gear
            gear.UsableOnly, gear.HideSubOptimalArmor, gear.MinQuality = true, true, 2
            KrowiEVU_FilterButton:SetFilter(LE_LOOT_FILTER_ALL)
        end,
        Check = function()
            CheckMerchantTab()
            CheckGear()
        end,
    },
    {
        Name = 'banner-options',
        Text = 'filter All, Gold total off, Hide currencies you have none of on',
        Run = function()
            RestoreOptions()
            local tokenBanner = addon.Options.db.profile.TokenBanner
            tokenBanner.GoldTotal, tokenBanner.HideNone = false, true
            KrowiEVU_FilterButton:SetFilter(LE_LOOT_FILTER_ALL)
        end,
    },
    {
        Name = 'illusions',
        Text = 'filter All, Hide collected: Illusions on',
        Run = function()
            if not addon.Util.IsModern then
                return 'the Illusions filter is Retail and Forever only'
            end
            local found
            for index = 1, GetMerchantNumItems() do
                local itemId = GetMerchantItemID(index)
                if itemId and filters.IsIllusion(itemId) then
                    found = true
                    break
                end
            end
            if not found then
                return 'this vendor sells no consumables of type Other, where the Illusions filter looks'
            end
            RestoreOptions()
            filters.db.profile.HideCollected.Illusions = true
            KrowiEVU_FilterButton:SetFilter(LE_LOOT_FILTER_ALL)
        end,
        Check = function()
            CheckMerchantTab()
            CheckIllusions()
        end,
    },
    {
        -- The options button's Hide message shows this arrow, from the addon's own Media folder (options-button-arrow)
        Name = 'arrow',
        Run = function()
            current.Text = 'the arrow in the options button\'s Hide message: ' .. ('{arrow}'):K_ReplaceVarsWithMenu()
        end,
        Check = function()
            Note('the banner shows the arrow; a missing file shows a green square or nothing')
        end,
    },
    {
        Name = 'currency',
        Text = 'click a currency in the token banner',
        Wait = 'currency',
        Run = function()
            local i, found = 1, false
            while _G['KrowiEVU_TokenBannerToken' .. i] do
                local token = _G['KrowiEVU_TokenBannerToken' .. i]
                found = found or (token:IsShown() and token.IsCurrency) or false
                i = i + 1
            end
            if not found then
                return 'the token banner shows no currency at this vendor'
            end
            characterShownBefore = CharacterFrame:IsShown()
        end,
        Check = CheckCurrencyClick,
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

-- After the token's own click, which opens the character window
local function OnTokenClick(self)
    if waitingFor == 'currency' and self.IsCurrency then
        Continue()
    end
end

local function HookTokens()
    local i = 1
    while _G['KrowiEVU_TokenBannerToken' .. i] do
        local token = _G['KrowiEVU_TokenBannerToken' .. i]
        if not hookedTokens[token] then
            hookedTokens[token] = true
            token:HookScript('OnClick', OnTokenClick)
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
        elseif step.Wait == 'currency' then
            HookTokens()
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
                    tests.Start(true)
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
    current = { Step = #run.Steps + 1, Name = 'client', Text = 'Krowi_Util client flags', Lines = {} }
    tinsert(run.Steps, current)
    ok, err = pcall(CheckClientFlags)
    if not ok then
        Add('FAIL', 'test error: ' .. tostring(err))
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

-- onOpen: started by the vendor window opening, so the first step sees its first draw
function tests.Start(onOpen)
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
        Gear = CopyTable(filters.db.profile.Gear),
        GoldTotal = profile.TokenBanner.GoldTotal,
        HideNone = profile.TokenBanner.HideNone,
        HideIllusions = filters.db.profile.HideCollected.Illusions,
    }

    run = { Time = date('%Y-%m-%d %H:%M:%S'), Steps = {}, OnOpen = onOpen }
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
    local mouseSteps = 0
    for _, step in ipairs(steps) do
        if step.Wait then
            mouseSteps = mouseSteps + 1
        end
    end
    print(prefix .. ('%d steps, about 30 s, then %d that need the mouse; /kevutest again stops it'):format(#steps, mouseSteps))
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
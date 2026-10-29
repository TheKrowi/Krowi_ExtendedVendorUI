-- [[ Namespaces ]] --
local addonName, addon = ...

-- [[ Version data ]] --
local version = (GetBuildInfo())
local major = string.match(version, '(%d+)%.(%d+)%.(%d+)(%w?)')
addon.IsWrathClassic = major == '3'
addon.IsDragonflightRetail = major == '10'

-- [[ EllesmereUI's merchant list mode ]] --
-- That mode replaces the merchant grid with EllesmereUI's own list of every item, which this addon can neither filter nor lay out.
-- Then the addon loads nothing: every later file returns at its top, and a notice says why when a vendor opens (Krowi, 2026-10-21).
-- EllesmereUI switches the mode only with a reload, and the TOC's OptionalDeps load it first, so its settings are known here.
local function IsEllesmereUIListModeOn()
    if not (addon.Util.IsModern and EllesmereUI and not EUI_CLIENT_BLOCKED and C_AddOns.IsAddOnLoaded('EllesmereUIBlizzardSkin')
        and EllesmereUIDB and EllesmereUIDB.merchantShowAsList == true) then
        return false
    end
    if type(EllesmereUI.GetBlizzWindowStyle) ~= 'function' then
        return true
    end
    local ok, style = pcall(EllesmereUI.GetBlizzWindowStyle, 'merchant')
    return not ok or style ~= 'off'
end

-- [[ WoW Forever's gamepad interface ]] --
-- Forever's gamepad navigation picks up every button in the vendor window, this addon's item slots too, reads the fields the
-- addon's code gave them (buttonContext, count) and rebuilds the gamepad bindings from them, which then run tainted: blocked
-- actions in combat, and after Buyback the Buy button on Blizzard's hidden first slot (taint review of 2026-10-22). With that
-- style on the addon loads nothing and Blizzard's window stays (Krowi, 2026-10-22). The style changes without a reload, so a
-- switch to it is announced at the next vendor and takes effect with the next reload.
local function IsForeverGamepadStyleOn()
    if not (addon.Util.IsForever and InputUtil and InputUtil.IsGamepadUIEnabled) then
        return false
    end
    local ok, isOn = pcall(InputUtil.IsGamepadUIEnabled) -- Read at load on a beta client; a failure must not stop the addon
    return ok and isOn and true or false
end

-- [[ Notice window ]] --
-- For the not-loaded notices below
local notice, noticeText
local function ShowNotice(text)
    if not notice then
        notice = CreateFrame('Frame', 'KrowiEVU_Notice', UIParent, 'BasicFrameTemplateWithInset')
        notice:SetWidth(420)
        notice:SetPoint('TOP', 0, -135)
        notice:SetFrameStrata('DIALOG')
        notice:SetToplevel(true)
        notice:EnableMouse(true)
        notice.TitleText:SetText(addon.Metadata.Title)
        -- The template's close button calls HideUIPanel, which runs tainted from here and refuses in combat; a vendor can be
        -- opened in combat (taint review of 2026-10-25)
        notice.CloseButton:SetScript('OnClick', function()
            notice:Hide()
        end)
        noticeText = notice:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
        noticeText:SetPoint('TOP', 0, -40)
        noticeText:SetWidth(380)
        -- Without the tooltip variant's OnLeave, which hides the shared tooltip whoever owns it, tainted
        local okay = CreateFrame('Button', nil, notice, 'UIPanelButtonNoTooltipTemplate')
        okay:SetSize(120, 22)
        okay:SetPoint('BOTTOM', 0, 14)
        okay:SetText(OKAY)
        okay:SetScript('OnClick', function()
            notice:Hide()
        end)
    end
    noticeText:SetText(text)
    notice:SetHeight(noticeText:GetStringHeight() + 96)
    notice:Show()
end

if IsEllesmereUIListModeOn() then
    addon.NotLoaded = 'EllesmereUIListMode'
    addon.NotLoadedText = addon.L['Plugin_EllesmereUI_ListModeNotLoaded']
elseif IsForeverGamepadStyleOn() then
    addon.NotLoaded = 'ForeverGamepad'
    addon.NotLoadedText = addon.L['ForeverGamepadNotLoaded']
end

if addon.NotLoaded then
    -- At the first vendor and from the addon compartment (Icon.lua)
    function addon.ShowNotLoadedNotice()
        if addon.NotLoaded == 'ForeverGamepad' then
            print(addon.NotLoadedText) -- A window could need the mouse to close; the text names the addon
            return
        end
        ShowNotice(addon.NotLoadedText)
    end

    local noticeHelper = CreateFrame('Frame')
    noticeHelper:RegisterEvent('MERCHANT_SHOW')
    noticeHelper:SetScript('OnEvent', function(self)
        self:UnregisterEvent('MERCHANT_SHOW') -- Once a session
        addon.ShowNotLoadedNotice()
    end)
    return
end

if addon.Util.IsForever then
    local styleHelper = CreateFrame('Frame')
    styleHelper:RegisterEvent('MERCHANT_SHOW')
    styleHelper:SetScript('OnEvent', function(self)
        if IsForeverGamepadStyleOn() then
            self:UnregisterEvent('MERCHANT_SHOW') -- Once a session
            print(addon.L['ForeverGamepadReload']) -- The text names the addon
        end
    end)
end

-- [[ Load addon ]] --
local loadHelper = CreateFrame('Frame')
loadHelper:RegisterEvent('ADDON_LOADED')

function loadHelper:OnEvent(event, arg1, arg2)
    if event == 'ADDON_LOADED' then
        if arg1 == addonName then -- This always needs to load
            KrowiEVU.PluginsApi:InjectPluginOptions()
            addon.Options:Load(true)

            KrowiEVU.PluginsApi:LoadPlugins()

            addon.Gui.MerchantItemsContainer:LoadMaxNumItemSlots()

            addon.Gui.FilterButton:Load()
            addon.Gui.SearchBox:Load()
            addon.Gui.OptionsButton:Load()
            -- if addon.Util.IsMainline then
                addon.Gui.TokenBanner:Load()
            -- end

            addon.Icon:Load()

            addon.Gui.BulkPurchase:Load()

            addon.Api.Load()

            if addon.Util.IsMainline then
                C_HousingCatalog.CreateCatalogSearcher() -- Pre-load the housing catalog searcher to prevent lag when first used
            end
        end
    end
end
loadHelper:SetScript('OnEvent', loadHelper.OnEvent)
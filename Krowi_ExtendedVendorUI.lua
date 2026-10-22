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

if IsEllesmereUIListModeOn() then
    addon.NotLoaded = 'EllesmereUIListMode'

    local notice
    function addon.ShowNotLoadedNotice()
        if not notice then
            notice = CreateFrame('Frame', 'KrowiEVU_NotLoadedNotice', UIParent, 'BasicFrameTemplateWithInset')
            notice:SetWidth(420)
            notice:SetPoint('TOP', 0, -135)
            notice:SetFrameStrata('DIALOG')
            notice:SetToplevel(true)
            notice:EnableMouse(true)
            notice.TitleText:SetText(addon.Metadata.Title)
            local text = notice:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
            text:SetPoint('TOP', 0, -40)
            text:SetWidth(380)
            text:SetText(addon.L['Plugin_EllesmereUI_ListModeNotLoaded'])
            local okay = CreateFrame('Button', nil, notice, 'UIPanelButtonTemplate')
            okay:SetSize(120, 22)
            okay:SetPoint('BOTTOM', 0, 14)
            okay:SetText(OKAY)
            okay:SetScript('OnClick', function()
                notice:Hide()
            end)
            notice:SetHeight(text:GetStringHeight() + 96)
        end
        notice:Show()
    end

    local noticeHelper = CreateFrame('Frame')
    noticeHelper:RegisterEvent('MERCHANT_SHOW')
    noticeHelper:SetScript('OnEvent', function(self)
        self:UnregisterEvent('MERCHANT_SHOW') -- Once a session
        addon.ShowNotLoadedNotice()
    end)
    return
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
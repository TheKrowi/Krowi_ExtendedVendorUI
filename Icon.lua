local _, addon = ...
if addon.NotLoaded then
    -- The addon compartment entry from the TOC stays, so it says why the addon is off (Krowi_ExtendedVendorUI.lua). Krowi_Util's own
    -- tooltip, as its Icon.lua uses: Blizzard calls these insecurely, which would taint GameTooltip.
    _G[addon.Metadata.Prefix .. '_OnAddonCompartmentEnter'] = function(_, menuButtonFrame)
        Krowi_Tooltip:SetOwner(menuButtonFrame, 'ANCHOR_NONE')
        Krowi_Tooltip:SetPoint('TOPRIGHT', menuButtonFrame, 'BOTTOMRIGHT', 0, 0)
        Krowi_Tooltip:SetText(addon.Metadata.Title)
        Krowi_Tooltip:AddLine(addon.L['Plugin_EllesmereUI_ListModeNotLoaded'], 1, 1, 1, true)
        Krowi_Tooltip:Show()
    end
    _G[addon.Metadata.Prefix .. '_OnAddonCompartmentLeave'] = function()
        Krowi_Tooltip:Hide()
    end
    _G[addon.Metadata.Prefix .. '_OnAddonCompartmentClick'] = function()
        addon.ShowNotLoadedNotice()
    end
    return
end
local icon = addon.Icon

local instructionsFormat = '%s: %s'
function icon.SetMoreTooltipContent(tooltip)
    tooltip:AddLine(string.format(instructionsFormat, addon.Util.L['Left-Click'], addon.L['Icon Left click']):SetColorTpInstr())
    tooltip:AddLine(string.format(instructionsFormat, addon.Util.L['Right-Click'], addon.L['Icon Right click']):SetColorTpInstr())
end

function icon.OnLeftClick()
    KrowiEVU_OptionsButton:ShowPopup()
end

function icon.OnRightClick()
    addon.Options:Open()
end
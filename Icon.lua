local _, addon = ...
if addon.NotLoaded then
    -- The addon compartment entry from the TOC stays, so it says why the addon is off (Krowi_ExtendedVendorUI.lua)
    _G[addon.Metadata.Prefix .. '_OnAddonCompartmentEnter'] = function(_, menuButtonFrame)
        GameTooltip:SetOwner(menuButtonFrame, 'ANCHOR_NONE')
        GameTooltip:SetPoint('TOPRIGHT', menuButtonFrame, 'BOTTOMRIGHT', 0, 0)
        GameTooltip:SetText(addon.Metadata.Title)
        GameTooltip:AddLine(addon.L['Plugin_EllesmereUI_ListModeNotLoaded'], 1, 1, 1, true)
        GameTooltip:Show()
    end
    _G[addon.Metadata.Prefix .. '_OnAddonCompartmentLeave'] = function()
        GameTooltip:Hide()
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
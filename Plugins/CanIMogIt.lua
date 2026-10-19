local _, addon = ...
local canIMogIt = {}
local pluginName = 'CanIMogIt'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, canIMogIt)

function canIMogIt:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc']:K_ReplaceVars(addon.L[L_Prefix .. 'Name']), function()
        return C_AddOns.IsAddOnLoaded(pluginName)
    end)
end

-- CanIMogIt puts its overlay only on Blizzard's MerchantItemN (CanIMogIt/Overlay/Merchant.lua), so the addon's slots get theirs here,
-- through the same public functions, and are refreshed on every draw. The overlay reads the item button's link.
function canIMogIt:OnItemSlotUpdated(slot)
    if not (CIMI_AddToFrame and MerchantFrame_CIMIUpdateIcon) then
        return
    end
    local itemButton = slot.ItemButton
    if not itemButton.CanIMogItOverlay then
        CIMI_AddToFrame(itemButton, MerchantFrame_CIMIUpdateIcon)
    end
    if itemButton.CanIMogItOverlay then
        MerchantFrame_CIMIUpdateIcon(itemButton.CanIMogItOverlay)
    end
end
local _, addon = ...
local transmogLootHelper = {}
local pluginName = 'TransmogLootHelper'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, transmogLootHelper)

function transmogLootHelper:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc']:K_ReplaceVars(addon.L[L_Prefix .. 'Name']), function()
        return C_AddOns.IsAddOnLoaded(pluginName)
    end)
end

-- Transmog Loot Helper (12.1.5-02 and later) draws its overlay on this addon's slots itself, when a vendor opens and whenever
-- its public UpdateOverlay runs, so each draw asks for one. Empty slots have hasItem false, not nil, or TLH would retry
-- every frame (Gui/MerchantItemSlot.lua).
function transmogLootHelper:OnItemSlotsUpdated()
    if TransmogLootHelper and type(TransmogLootHelper.UpdateOverlay) == 'function' then
        TransmogLootHelper:UpdateOverlay()
    end
end

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
-- its public UpdateOverlay runs, so each draw asks for one. Not for an empty list: TLH then retries every frame until the
-- first slot has an item.
function transmogLootHelper:OnItemSlotsUpdated()
    if #addon.Gui.MerchantItemsContainer:GetIndices() == 0 then
        return
    end
    if TransmogLootHelper and type(TransmogLootHelper.UpdateOverlay) == 'function' then
        TransmogLootHelper:UpdateOverlay()
    end
end

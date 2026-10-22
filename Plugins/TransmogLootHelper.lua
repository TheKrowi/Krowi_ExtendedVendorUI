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

function transmogLootHelper:OnItemSlotsUpdated()
    if TransmogLootHelper and type(TransmogLootHelper.UpdateOverlay) == "function" then
        TransmogLootHelper:UpdateOverlay()
    end
end

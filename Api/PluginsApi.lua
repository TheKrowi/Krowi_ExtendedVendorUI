--[[ Plugins
A plugin is a table registered with KrowiEVU.PluginsApi:RegisterPlugin(name, plugin). Extended Vendor UI calls these optional methods on it:
    plugin:InjectOptions()                  at ADDON_LOADED, to add an entry to the Plugins options page
    plugin:Load()                           at ADDON_LOADED, after the options
    plugin:LoadLocalization(L)              while the locale loads
    plugin:OnEvent(event, ...)              for events registered with KrowiEVU.PluginsApi:RegisterEvent(event)
    plugin:OnItemSlotCreated(slot)          when an item slot of the merchant tab is created
    plugin:OnFirstDraw()                    once, right before the merchant tab is first drawn; addons that skin at
                                            PLAYER_LOGIN or later are ready by then, and the page controls exist
    plugin:OnItemSlotUpdated(slot, index)   after an item slot of the merchant tab is drawn
    plugin:OnItemSlotsUpdated()             after the whole merchant page is drawn
slot is the frame KrowiEVU_MerchantItem<N>, built from Blizzard's MerchantItemTemplate, so it has the same children as
MerchantItemN (slot.ItemButton, slot.Name, <name>MoneyFrame, <name>AltCurrencyFrame) and slot.ItemButton carries the same
fields Blizzard sets (link, price, extendedCost). index is the vendor's real index, as slot.ItemButton:GetID() returns,
and nil for an empty slot. Errors in these four methods are reported and do not stop the merchant window.
]]

local _, addon = ...
KrowiEVU.PluginsApi = {}
local pluginsApi = KrowiEVU.PluginsApi
pluginsApi.Plugins = {}

function pluginsApi:RegisterPlugin(pluginName, plugin)
    self.Plugins[pluginName] = plugin
end

local loadHelper = CreateFrame('Frame')
function loadHelper:OnEvent(event, arg1, arg2)
    if addon.NotLoaded then -- Plugins of an addon that did not load (Krowi_ExtendedVendorUI.lua) get no events
        return
    end
    for _, plugin in next, pluginsApi.Plugins do
        if type(plugin.OnEvent) == 'function' then
            plugin:OnEvent(event, arg1, arg2)
        end
    end
end
loadHelper:SetScript('OnEvent', loadHelper.OnEvent)

function pluginsApi:RegisterEvent(event)
    if addon.NotLoaded then
        return
    end
    loadHelper:RegisterEvent(event)
end

function pluginsApi:LoadPluginLocalization(L)
    for _, plugin in next, self.Plugins do
        if type(plugin.LoadLocalization) == 'function' then
            plugin:LoadLocalization(L)
        end
    end
end

function pluginsApi:InjectPluginOptions()
    for _, plugin in next, self.Plugins do
        if type(plugin.InjectOptions) == 'function' then
            plugin:InjectOptions()
        end
    end
end

function pluginsApi:LoadPlugins()
    for _, plugin in next, self.Plugins do
        if type(plugin.Load) == 'function' then
            plugin:Load()
        end
    end
end

function pluginsApi:CallPlugins(method, ...)
    for _, plugin in next, self.Plugins do
        local func = plugin[method]
        if type(func) == 'function' then
            local ok, err = pcall(func, plugin, ...)
            if not ok then
                geterrorhandler()(err)
            end
        end
    end
end
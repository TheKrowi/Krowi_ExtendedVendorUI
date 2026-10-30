local _, addon = ...
if addon.Util.IsModern then
    return -- On Retail and Forever Scrap sits on Sell All Junk, which this addon places itself
end

local scrap = {}
local pluginName = 'Scrap'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, scrap)

function scrap:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc']:K_ReplaceVars(addon.L[L_Prefix .. 'Name']), function()
        return C_AddOns.IsAddOnLoaded(pluginName)
    end)
end

-- Scrap's merchant button (Scrap 12.1, addons/merchant/button.lua, UpdatePosition). Where Blizzard has no Sell All Junk button,
-- so on every Classic client, Scrap puts it left of MerchantRepairItemButton, which this addon moves to the left edge of its
-- buttons inset: the button ends up outside the window. With guild repair Scrap also gives MerchantRepairAllButton a second
-- anchor, which stretches it against this addon's own (#80). So after each of Scrap's placements, this addon's repair layout
-- again and Scrap's button right of the last repair button. At a vendor without repair Scrap's own place, left of the buyback
-- item, is inside the window; only this plugin's anchor from an earlier vendor has to go.
local function Place(button)
    local scrapAnchor
    for i = 1, button:GetNumPoints() do
        local point, relativeTo = button:GetPoint(i)
        if point == 'RIGHT' then
            scrapAnchor = relativeTo and relativeTo.GetName and relativeTo:GetName()
        end
    end
    scrap.LastPlaced = { ScrapAnchor = scrapAnchor, RepairAllPoints = MerchantRepairAllButton:GetNumPoints() } -- For /kevutest
    addon.Gui.MerchantFrame.UpdateRepairButtons()
    if not MerchantRepairAllButton:IsShown() then
        button:ClearPoint('LEFT')
        return
    end
    local last = MerchantGuildBankRepairButton:IsShown() and MerchantGuildBankRepairButton or MerchantRepairAllButton
    button:ClearAllPoints()
    button:SetPoint('LEFT', last, 'RIGHT', 8, 0)
end

-- Scrap calls the method through self, so the hook runs for its MERCHANT_SHOW and its MerchantFrame_UpdateRepairButtons hook
-- alike
local function Hook()
    local button = Scrap and Scrap.Merchant
    if scrap.Hooked or not (button and type(button.UpdatePosition) == 'function') then
        return
    end
    scrap.Hooked = true
    hooksecurefunc(button, 'UpdatePosition', Place)
end

-- The button is in Scrap_Merchant, which Scrap loads on demand when a vendor opens (addons/main/main.lua, MERCHANT_SHOW)
function scrap:Load()
    if C_AddOns.IsAddOnLoaded('Scrap_Merchant') then
        Hook()
        return
    end
    KrowiEVU.PluginsApi:RegisterEvent('ADDON_LOADED')
end

function scrap:OnEvent(event, addOnName)
    if event == 'ADDON_LOADED' and addOnName == 'Scrap_Merchant' then
        Hook()
    end
end
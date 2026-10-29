local _, addon = ...
local scrap = {}
local pluginName = 'Scrap'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, scrap)

function scrap:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc']:K_ReplaceVars(addon.L[L_Prefix .. 'Name']), function()
        return C_AddOns.IsAddOnLoaded(pluginName)
    end)
end

-- Scrap's merchant button (Scrap 12.1.3, addons/merchant/button.lua, UpdatePosition). Where Blizzard has no Sell All Junk
-- button, so on every Classic client, Scrap puts it left of MerchantRepairItemButton, which this addon moves to the left edge
-- of its buttons inset: the button ends up outside the window. With guild repair Scrap also gives MerchantRepairAllButton a
-- second anchor, which stretches it against this addon's own (#80). So after each of Scrap's placements, this addon's repair
-- layout again and Scrap's button right of the last repair button. At a vendor without repair Scrap's own place, left of the
-- buyback item, is inside the window. On Retail and Forever Scrap sits on Sell All Junk, which this addon places itself.
local function Place(button)
    local _, relativeTo = button:GetPoint(1)
    scrap.LastPlaced = { -- What Scrap had done, for /kevutest
        ScrapAnchor = relativeTo and relativeTo.GetName and relativeTo:GetName(),
        RepairAllPoints = MerchantRepairAllButton:GetNumPoints(),
    }
    addon.Gui.MerchantFrame.UpdateRepairButtons()
    if not MerchantRepairAllButton:IsShown() then
        return
    end
    local last = MerchantGuildBankRepairButton:IsShown() and MerchantGuildBankRepairButton or MerchantRepairAllButton
    button:ClearAllPoints()
    button:SetPoint('LEFT', last, 'RIGHT', 8, 0)
end

function scrap:Load()
    if addon.Util.IsModern then
        return
    end
    KrowiEVU.PluginsApi:RegisterEvent('PLAYER_LOGIN')
end

-- Scrap loads after this addon, so its button exists from PLAYER_LOGIN on; Scrap reaches its method through self, so the hook
-- runs for its MERCHANT_SHOW and its MerchantFrame_UpdateRepairButtons hook alike
function scrap:OnEvent(event)
    if event ~= 'PLAYER_LOGIN' or self.Hooked then
        return
    end
    local button = C_AddOns.IsAddOnLoaded(pluginName) and Scrap and Scrap.Merchant
    if not (button and type(button.UpdatePosition) == 'function') then
        return
    end
    self.Hooked = true
    hooksecurefunc(button, 'UpdatePosition', Place)
end
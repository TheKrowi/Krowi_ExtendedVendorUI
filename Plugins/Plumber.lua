local _, addon = ...
if not addon.Util.IsModern then
    return -- Plumber's Merchant Price only loads on Retail and WoW Forever
end

local plumber = {}
local pluginName = 'Plumber'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, plumber)

-- Plumber's Merchant Price (Plumber 1.9.6, Modules/MerchantPrice.lua) moves Blizzard's MerchantMoneyInset, the token banner's
-- parent, into a hidden frame of its own and shows its own coin box, which reads only Blizzard's MerchantItemN and so shows
-- nothing but gold next to this addon's slots. The addon does not work around it (Krowi, 2026-10-25; Plumber #533): it says
-- so once a session at a vendor, and on the Plugins page.

function plumber:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc']:K_ReplaceVars(addon.L[L_Prefix .. 'Name']), function()
        return C_AddOns.IsAddOnLoaded(pluginName)
    end)
end

-- Only while the bar is really gone, so a Plumber that leaves it in place stops the notice by itself
function plumber:IsHidingTokenBanner()
    return C_AddOns.IsAddOnLoaded(pluginName) and type(PlumberDB) == 'table' and PlumberDB.MerchantPrice == true
        and MerchantMoneyInset:GetParent() ~= MerchantFrame or false
end

function plumber:Load()
    local noticeHelper = CreateFrame('Frame')
    noticeHelper:RegisterEvent('MERCHANT_SHOW')
    noticeHelper:SetScript('OnEvent', function(helper)
        if not plumber:IsHidingTokenBanner() then
            return -- Checked again at the next vendor
        end
        helper:UnregisterEvent('MERCHANT_SHOW') -- Once a session
        plumber.NoticeShown = true
        local text = addon.L[L_Prefix .. 'MerchantPriceHidesTokenBanner']
        print(text) -- The text names the addon
        if not addon.IsForeverGamepadStyleOn() then -- A window could need the mouse to close
            addon.ShowNotice(text)
        end
    end)
end
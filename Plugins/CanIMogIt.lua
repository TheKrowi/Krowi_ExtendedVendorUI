local _, addon = ...;
local canIMogIt = {};
KrowiEVU.PluginsApi:RegisterPlugin("CanIMogIt", canIMogIt);

function canIMogIt:InjectOptions()
    addon.InjectOptions:AddPluginTable("CanIMogIt", addon.L["Can I Mog It"], addon.L["Can I Mog It Desc"]:K_ReplaceVars(addon.L["Can I Mog It"]), function()
        return C_AddOns.IsAddOnLoaded("CanIMogIt");
    end);
end

function canIMogIt:Load()
    if MerchantFrame_CIMIOnClick then
        hooksecurefunc("MerchantFrame_SetFilter", function()
            C_Timer.After(0.1, function()
                MerchantFrame_CIMIOnClick();
            end);
        end);
    end
end
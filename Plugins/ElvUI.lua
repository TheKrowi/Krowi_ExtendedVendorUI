local _, addon = ...;
local plugins = addon.Plugins;
plugins.ElvUI = {};
local elvUI = plugins.ElvUI;
tinsert(plugins.Plugins, elvUI);

local function IsLoaded()
    return ElvUI ~= nil;
end

function elvUI.Load()
    if not IsLoaded() then
        return;
    end

    for i = 1, 12, 1 do
        _G["MerchantItem" .. i].PointXY = function() end;
    end
end
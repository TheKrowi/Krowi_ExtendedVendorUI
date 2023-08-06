local _, addon = ...;

local function SetTooltipContent(tooltip)
    tooltip:AddLine(addon.L["Right click"] .. " "  .. addon.L["Icon Right click"]:SetColorAddonBlue());
end

local function OnRightClick()
    addon.Options:Open();
end

addon.Icon = addon.Util.Icon:New(addon.Metadata, SetTooltipContent, nil, OnRightClick);
local icon = addon.Icon;

KrowiMFE_OnAddonCompartmentEnter = function(...) icon:OnAddonCompartmentEnter(...); end
KrowiMFE_OnAddonCompartmentLeave = function(...) icon:OnAddonCompartmentLeave(...); end
KrowiMFE_OnAddonCompartmentClick = function(...) icon:OnAddonCompartmentClick(...); end
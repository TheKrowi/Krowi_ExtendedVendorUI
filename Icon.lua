local _, addon = ...;
local icon = addon.Icon;

function icon.SetMoreTooltipContent(tooltip)
    tooltip:AddLine(addon.L["Right click"] .. " "  .. addon.L["Icon Right click"]:SetColorAddonBlue());
end

function icon.OnRightClick()
    addon.Options:Open();
end
-- [[ Namespaces ]] --
local addonName, addon = ...;

-- Using LibDBIcon instead of creating the icon from scratch is the automatic integration with other addons that also use LibDataBroker
addon.Icon = LibStub("LibDBIcon-1.0"); -- Global icon object
local icon = addon.Icon; -- Local icon object

local function CreateIcon()
    icon.MerchantFrameExtendedLDB = LibStub("LibDataBroker-1.1"):NewDataObject("Krowi_MerchantFrameExtendedLDB", {
        type = "launcher",
        label = addon.MetaData.Title,
        icon = "Interface/PaperDollInfoFrame/UI-GearManager-ItemIntoBag",
        OnClick = function(self, button)
            if button == "LeftButton" then
                -- addon.Gui.ToggleAchievementFrame(addonName, addon.L["Expansions"]);
            elseif button == "RightButton" then
                addon.Options.Open();
            end
        end,
        OnTooltipShow = function(tt)
            tt:ClearLines();
            tt:AddDoubleLine(addon.MetaData.Title, addon.MetaData.BuildVersion);
            -- tt:AddLine(" "); -- Empty line
		    GameTooltip_AddBlankLineToTooltip(tt);
            -- tt:AddLine(addon.L["Left click"] .. " " .. addon.L["Icon Right click"]:SetColorAddonBlue());
            tt:AddLine(addon.L["Right click"] .. " "  .. addon.L["Icon Right click"]:SetColorAddonBlue());
        end,
    });
end

-- Load the icon
function icon.Load()
    CreateIcon();

    local db = addon.Options.db;
    db.Minimap.hide = not db.ShowMinimapIcon;
    icon:Register("Krowi_MerchantFrameExtendedLDB", icon.MerchantFrameExtendedLDB, db.Minimap);
end
local _, addon = ...;
addon.Gui.FilterButton = {};
local filterButton = addon.Gui.FilterButton;

local function CreateModern()
    local button = CreateFrame("DropdownButton", "KrowiEVU_FilterButton", MerchantFrame, "KrowiEVU_FilterButton_Template");
    button:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -9, -32);
    MerchantFrame.FilterButton = button;
    return button;
end

local function CreateClassic()
    local button = CreateFrame("DropDownToggleButton", "KrowiEVU_FilterButton", MerchantFrame, "KrowiEVU_FilterButton_Template");
    button:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -10, -31);
    MerchantFrame.FilterButton = button;
    return button;
end

function filterButton:Load()
	if addon.Util.IsMainline then
        CreateModern();
    else
        CreateClassic()
    end
	addon.Gui.FilterButton = nil;
end
-- [[ Namespaces ]] --
local _, addon = ...;
local merchantItemsContainer = addon.Gui.MerchantItemsContainer;

KrowiEVU_OptionsButtonMixin = {};

local menuBuilder;

local function UpdateView()
	merchantItemsContainer:LoadMaxNumItemSlots();
	MerchantFrame_Update();
end

function KrowiEVU_OptionsButtonMixin:OnLoad()
	local lib = LibStub("Krowi_MenuBuilder-1.0");

	menuBuilder = lib:New({
		uniqueTag = "KEVU_OPTIONS",
		callbacks = {
			OnRadioSelect = function(filters, keys, value)
				addon.Util.WriteNestedKeys(filters, keys, value);
				UpdateView();
			end,
			OnCheckboxSelect = function(filters, keys)
				addon.Util.WriteNestedKeys(filters, keys, not menuBuilder:KeyIsTrue(filters, keys));
			end,
		}
	});
end

function KrowiEVU_OptionsButtonMixin:ShowHide()
    if addon.Options.db.profile.ShowOptionsButton then
        self:Show();
        return;
    end
    self:Hide();
end

local media = "Interface\\AddOns\\Krowi_MerchantFrameExtended\\Media\\";
local function ReplaceVarsWithMenu(str, vars)
    if not vars then
        vars = type(str) == "table" and str or {str};
        str = vars[1];
    end
    vars["arrow"] = "|T" .. media .. "ui-backarrow:0|t";
    vars["gameMenu"] = addon.L["Game Menu"];
    vars["interface"] = addon.L["Interface"];
    vars["addOns"] = addon.L["AddOns"];
    vars["addonName"] = addon.Metadata.Title;
    return addon.Util.Strings.ReplaceVars(str, vars);
end
string.K_ReplaceVarsWithMenu = ReplaceVarsWithMenu;

local function HideOptionsButtonCallback(self)
	addon.Options.db.profile.ShowOptionsButton = false;
	self:ShowHide();
end

local function CreateMenu(self, menuObj)
	local profile = addon.Options.db.profile;
	
	-- Direction submenu
	local direction = menuBuilder:CreateSubmenuButton(menuObj, addon.L["Direction"]);
	menuBuilder:CreateRadio(direction, addon.L["Rows first"], profile, {"Direction"});
	menuBuilder:CreateRadio(direction, addon.L["Columns first"], profile, {"Direction"});
	menuBuilder:AddChildMenu(menuObj, direction);

	-- Rows submenu
	local rows = menuBuilder:CreateSubmenuButton(menuObj, addon.L["Rows"]);
	for i = 1, 10 do
		menuBuilder:CreateRadio(rows, tostring(i), profile, {"NumRows"}, i);
	end
	menuBuilder:AddChildMenu(menuObj, rows);

	-- Columns submenu
	local columns = menuBuilder:CreateSubmenuButton(menuObj, addon.L["Columns"]);
	for i = 2, 6 do
		menuBuilder:CreateRadio(columns, tostring(i), profile, {"NumColumns"}, i);
	end
	menuBuilder:AddChildMenu(menuObj, columns);

	menuBuilder:CreateDivider(menuObj);

	-- Remember Filter checkbox
	menuBuilder:CreateCheckbox(menuObj, addon.L["RememberFilter"], profile, {"RememberFilter"});

	menuBuilder:CreateDivider(menuObj);

	-- Housing Quantity submenu
	local housingQuantity = menuBuilder:CreateSubmenuButton(menuObj, addon.L["Housing Quantity"]);
	for i = 1, 10 do
		menuBuilder:CreateRadio(housingQuantity, tostring(i), addon.Filters.db.profile, {"HousingQuantity"}, i);
	end
	menuBuilder:AddChildMenu(menuObj, housingQuantity);

	-- Hide button
	if profile.ShowHideOption then
		menuBuilder:CreateDivider(menuObj);
		menuBuilder:CreateButtonAndAdd(menuObj, addon.L["Hide"], function()
			if not StaticPopup_IsCustomGenericConfirmationShown("KrowiEVU_ConfirmHideOptionsButton") then
				StaticPopup_ShowCustomGenericConfirmation(
					{
						text = addon.L["Are you sure you want to hide the options button?"]:K_ReplaceVarsWithMenu{
							general = addon.L["General"],
							options = addon.L["Options"]
						},
						callback = function()
							HideOptionsButtonCallback(self);
						end,
						referenceKey = "KrowiEVU_ConfirmHideOptionsButton"
					}
				);
			end
		end);
	end
end

function KrowiEVU_OptionsButtonMixin:MyOnMouseDown()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	menuBuilder:ShowPopup(function()
		local menuObj = menuBuilder:GetMenu();
		CreateMenu(self, menuObj);
	end);
end
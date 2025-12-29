local _, addon = ...;
addon.Gui.OptionsMenu = {};
local optionsMenu = addon.Gui.OptionsMenu;
local merchantItemsContainer = addon.Gui.MerchantItemsContainer;

local menu = LibStub("Krowi_Menu-1.0");
local menuItem = LibStub("Krowi_MenuItem-1.0");

function optionsMenu:AddRadioButton(parentMenu, _menu, text, options, keys, func)
    _menu:AddFull({
		Text = text,
		Checked = function() -- Same
			return addon.Util.ReadNestedKeys(options, keys) == text; -- e.g.: return filters.SortBy.Criteria == addon.L["Default"]
		end,
		Func = function()
			addon.Util.WriteNestedKeys(options, keys, text); -- e.g.: filters.SortBy.Criteria = text;
			menu:SetSelectedName(text);
			func();
		end,
		NotCheckable = false,
		KeepShownOnClick = true
	});
end

local function UpdateView()
	merchantItemsContainer:LoadMaxNumItemSlots();
	MerchantFrame_Update();
end

function optionsMenu:BuildMenu(parentMenu)
	if parentMenu == nil then
		menu:Clear();
	else
		menu = parentMenu;
	end

	local direction = menuItem:New({Text = addon.L["Direction"]});
	self:AddRadioButton(menu, direction, addon.L["Rows first"], addon.Options.db.profile, {"Direction"}, UpdateView);
	self:AddRadioButton(menu, direction, addon.L["Columns first"], addon.Options.db.profile, {"Direction"}, UpdateView);
	menu:Add(direction);

	local rows = menuItem:New({Text = addon.L["Rows"]});
	for i = 1, 10, 1 do
		self:AddRadioButton(menu, rows, i, addon.Options.db.profile, {"NumRows"}, UpdateView);
	end
	menu:Add(rows);

	local columns = menuItem:New({Text = addon.L["Columns"]});
	for i = 2, 6, 1 do
		self:AddRadioButton(menu, columns, i, addon.Options.db.profile, {"NumColumns"}, UpdateView);
	end
	menu:Add(columns);

	menu:AddSeparator();

    menu:AddFull({
        Text = addon.L["RememberFilter"],
        Checked = function()
            return addon.Options.db.profile.RememberFilter;
        end,
        Func = function()
            addon.Options.db.profile.RememberFilter = not addon.Options.db.profile.RememberFilter;
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU);
        end,
        IsNotRadio = true,
        NotCheckable = false,
        KeepShownOnClick = true
    });

	menu:AddSeparator();

	local housingQuantity = menuItem:New({Text = addon.L["Housing Quantity"]});
	for i = 1, 10, 1 do
		self:AddRadioButton(menu, housingQuantity, i, addon.Filters.db.profile, {"HousingQuantity"}, UpdateView);
	end
	menu:Add(housingQuantity);

	if addon.Options.db.profile.ShowHideOption and addon.Options.db.profile.ShowOptionsButton then
		menu:AddSeparator();
		menu:AddFull({
			Text = addon.L["Hide"],
			Func = function()
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
			end
		});
	end

	return menu;
end
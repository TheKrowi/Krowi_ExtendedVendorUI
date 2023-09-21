local _, addon = ...;

KrowiEVU_FilterButtonMixin = {};

function KrowiEVU_FilterButtonMixin:ShowHide()
    if addon.Options.db.profile.ShowOptionsButton then
        self:Show();
        return;
    end
    self:Hide();
end

function KrowiEVU_FilterButtonMixin:AddLootFilterRadioButton(parentMenu, _menu, text, lootFilter, selectedName, filterName)
    _menu:AddFull({
		Text = text,
		Checked = function()
			return GetMerchantFilter() == lootFilter;
		end,
		Func = function()
			MerchantFrame_SetFilter(nil, lootFilter);
			parentMenu:SetSelectedName(selectedName);
			self:SetText(filterName);
		end,
		NotCheckable = false,
		KeepShownOnClick = true
	});
end

function KrowiEVU_FilterButtonMixin:AddCheckBox(_menu, text, keys)
	local _filters = addon.Filters.db.profile;
    _menu:AddFull({
		Text = text,
		Checked = function() -- Using function here, we force the GUI to get the value again instead of only once (caused visual bugs)
			return addon.Util.ReadNestedKeys(_filters, keys); -- e.g.: return filters.Completion.Completed;
		end,
		Func = function()
			addon.Util.WriteNestedKeys(_filters, keys, not addon.Util.ReadNestedKeys(_filters, keys));
			MerchantFrame_SetFilter(nil, GetMerchantFilter());
		end,
		IsNotRadio = true,
		NotCheckable = false,
		KeepShownOnClick = true,
		IgnoreAsMenuSelection = true
	});
end

local menu = LibStub("Krowi_Menu-1.0");
local menuItem = LibStub("Krowi_MenuItem-1.0");
function KrowiEVU_FilterButtonMixin:BuildMenu()
	-- Reset menu
	menu:Clear();

	local className = UnitClass("player");
	local class = menuItem:New({
		Text = className,
		Checked = function()
			return GetMerchantFilter() >= LE_LOOT_FILTER_CLASS and GetMerchantFilter() <= LE_LOOT_FILTER_SPEC4;
		end,
		Func = function()
			MerchantFrame_SetFilter(nil, LE_LOOT_FILTER_CLASS);
			menu:SetSelectedName(className);
			self:SetText(className);
		end,
		NotCheckable = false,
		KeepShownOnClick = true
	});
	local numSpecs = GetNumSpecializations();
	local sex = UnitSex("player");
	for i = 1, numSpecs do
		local _, name = GetSpecializationInfo(i, nil, nil, nil, sex);
		self:AddLootFilterRadioButton(menu, class, name, LE_LOOT_FILTER_SPEC1 + i - 1, className, name);
	end
	self:AddLootFilterRadioButton(menu, class, ALL_SPECS, LE_LOOT_FILTER_CLASS, ALL_SPECS, className);
	menu:Add(class);

	self:AddLootFilterRadioButton(menu, menu, ITEM_BIND_ON_EQUIP, LE_LOOT_FILTER_BOE, ITEM_BIND_ON_EQUIP, ITEM_BIND_ON_EQUIP);

	self:AddLootFilterRadioButton(menu, menu, ALL, LE_LOOT_FILTER_ALL, ALL, ALL);

	menu:AddSeparator();

	-- self:AddLootFilterRadioButton(menu, menu, addon.L["Pets"], LE_LOOT_FILTER_PETS, addon.L["Pets"], addon.L["Pets"]);
	-- self:AddLootFilterRadioButton(menu, menu, addon.L["Mounts"], LE_LOOT_FILTER_MOUNTS, addon.L["Mounts"], addon.L["Mounts"]);

	self:AddCheckBox(menu, addon.L["Hide owned pets"], {"HideOwnedPets"});
	self:AddCheckBox(menu, addon.L["Hide collected mounts"], {"HideCollectedMounts"});

	return menu;
end

function KrowiEVU_FilterButtonMixin:MyOnMouseDown()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	self:BuildMenu();
    menu:Toggle(self, 96, 15);
end
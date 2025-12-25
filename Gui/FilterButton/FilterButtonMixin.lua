local _, addon = ...;

KrowiEVU_FilterButtonMixin = {};

-- Lookup table for loot filter text labels
local lootFilterTextMap = {};

local function InitializeLootFilterTextMap()
	lootFilterTextMap[LE_LOOT_FILTER_ALL] = ALL;
	lootFilterTextMap[LE_LOOT_FILTER_BOE] = ITEM_BIND_ON_EQUIP;
	lootFilterTextMap[LE_LOOT_FILTER_CLASS] = ALL_SPECS;
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_PETS"]] = addon.L["Pets"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_MOUNTS"]] = addon.L["Mounts"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TOYS"]] = addon.L["Toys"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG"]] = addon.L["Appearances"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG_SETS"]] = addon.L["Appearance Sets"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_ILLUSIONS"]] = addon.L["Illusions"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_RECIPES"]] = addon.L["Recipes"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_HOUSING"]] = addon.L["Housing"];
	lootFilterTextMap[_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_CUSTOM"]] = addon.L["Custom"];
end

local function GetLootFilterText(lootFilter)
	if not next(lootFilterTextMap) then
		InitializeLootFilterTextMap();
	end
	return lootFilterTextMap[lootFilter];
end

function KrowiEVU_FilterButtonMixin:AddTitle(menu, text)
	menu:AddFull({
		Text = text,
		IsTitle = true
	});
end

function KrowiEVU_FilterButtonMixin:AddLootFilterRadioButton(parentMenu, _menu, lootFilter, text)
	text = text or GetLootFilterText(lootFilter);
    _menu:AddFull({
		Text = text,
		Checked = function()
			return GetMerchantFilter() == lootFilter;
		end,
		Func = function()
			MerchantFrame_SetFilter(nil, lootFilter);
			parentMenu:SetSelectedName(text);
			self:SetText(text);
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

function KrowiEVU_FilterButtonMixin:CreateSelectDeselectAll(menu, text, filters, type, value)
    menu:AddFull({
        Text = text,
        Func = function()
			for index, _ in next, addon.Filters[type .. "Types"] do
				addon.Util.WriteNestedKeys(filters, {type, index}, value);
			end
            UIDropDownMenu_RefreshAll(UIDROPDOWNMENU_OPEN_MENU);
			MerchantFrame_SetFilter(nil, GetMerchantFilter());
        end,
        KeepShownOnClick = true
    });
end

local menu = LibStub("Krowi_Menu-1.0");
local menuItem = LibStub("Krowi_MenuItem-1.0");
function KrowiEVU_FilterButtonMixin:BuildMenu()
	-- Reset menu
	menu:Clear();

	self:AddTitle(menu, addon.L["Default filters"]);
	if addon.Util.IsMainline then
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
			self:AddLootFilterRadioButton(menu, class, LE_LOOT_FILTER_SPEC1 + i - 1, name);
		end
		self:AddLootFilterRadioButton(menu, class, LE_LOOT_FILTER_CLASS);
		menu:Add(class);

		self:AddLootFilterRadioButton(menu, menu, LE_LOOT_FILTER_BOE);
	end

	self:AddLootFilterRadioButton(menu, menu, LE_LOOT_FILTER_ALL);

	menu:AddSeparator();

	self:AddTitle(menu, addon.L["Only show"]);
	if addon.Util.IsMainline then
		self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_PETS"]);
	end
	self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_MOUNTS"]);
	self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TOYS"]);
	local appearances = menuItem:New({
		Text = addon.L["Appearances"],
		Checked = function()
			return GetMerchantFilter() == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG"];
		end,
		Func = function()
			MerchantFrame_SetFilter(nil, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG"]);
			menu:SetSelectedName(addon.L["Appearances"]);
			self:SetText(addon.L["Appearances"]);
		end,
		NotCheckable = false,
		KeepShownOnClick = true
	});
	self:AddTitle(appearances, C_Item.GetItemClassInfo(4));
	for index, _ in next, addon.Filters.ArmorTypes do
		self:AddCheckBox(appearances, (C_Item.GetItemSubClassInfo(4, index)), {"OnlyShow", "Armor", index});
	end
	appearances:AddSeparator();
	self:CreateSelectDeselectAll(appearances, addon.L["Select All"], addon.Filters.db.profile.OnlyShow, "Armor", true);
	self:CreateSelectDeselectAll(appearances, addon.L["Deselect All"], addon.Filters.db.profile.OnlyShow, "Armor", false);
	appearances:AddSeparator();
	self:AddTitle(appearances, C_Item.GetItemClassInfo(2));
	for index, _ in next, addon.Filters.WeaponTypes do
		self:AddCheckBox(appearances, (C_Item.GetItemSubClassInfo(2, index)), {"OnlyShow", "Weapon", index});
	end
	appearances:AddSeparator();
	self:CreateSelectDeselectAll(appearances, addon.L["Select All"], addon.Filters.db.profile.OnlyShow, "Weapon", true);
	self:CreateSelectDeselectAll(appearances, addon.L["Deselect All"], addon.Filters.db.profile.OnlyShow, "Weapon", false);
	menu:Add(appearances);
	if addon.Util.IsMainline then
		self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG_SETS"]);
		self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_ILLUSIONS"]);
		self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_RECIPES"]);
		self:AddLootFilterRadioButton(menu, menu, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_HOUSING"]);
	end

	local custom = menuItem:New({
		Text = addon.L["Custom"],
		Checked = function()
			return GetMerchantFilter() == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_CUSTOM"];
		end,
		Func = function()
			MerchantFrame_SetFilter(nil, _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_CUSTOM"]);
			menu:SetSelectedName(addon.L["Custom"]);
			self:SetText(addon.L["Custom"]);
		end,
		NotCheckable = false,
		KeepShownOnClick = true
	});
	if addon.Util.IsMainline then
		self:AddCheckBox(custom, addon.L["Pets"], {"Custom", "Pets"});
	end
	self:AddCheckBox(custom, addon.L["Mounts"], {"Custom", "Mounts"});
	self:AddCheckBox(custom, addon.L["Toys"], {"Custom", "Toys"});
	appearances = menuItem:New({
		Text = addon.L["Appearances"],
		Checked = function() -- Using function here, we force the GUI to get the value again instead of only once (caused visual bugs)
			return addon.Filters.db.profile.Custom.Transmog;
		end,
		Func = function()
			addon.Filters.db.profile.Custom.Transmog = not addon.Filters.db.profile.Custom.Transmog;
			MerchantFrame_SetFilter(nil, GetMerchantFilter());
		end,
		IsNotRadio = true,
		NotCheckable = false,
		KeepShownOnClick = true
	});
	self:AddTitle(appearances, C_Item.GetItemClassInfo(4));
	for index, _ in next, addon.Filters.ArmorTypes do
		self:AddCheckBox(appearances, (C_Item.GetItemSubClassInfo(4, index)), {"Custom", "Armor", index});
	end
	appearances:AddSeparator();
	self:CreateSelectDeselectAll(appearances, addon.L["Select All"], addon.Filters.db.profile.Custom, "Armor", true);
	self:CreateSelectDeselectAll(appearances, addon.L["Deselect All"], addon.Filters.db.profile.Custom, "Armor", false);
	appearances:AddSeparator();
	self:AddTitle(appearances, C_Item.GetItemClassInfo(2));
	for index, _ in next, addon.Filters.WeaponTypes do
		self:AddCheckBox(appearances, (C_Item.GetItemSubClassInfo(2, index)), {"Custom", "Weapon", index});
	end
	appearances:AddSeparator();
	self:CreateSelectDeselectAll(appearances, addon.L["Select All"], addon.Filters.db.profile.Custom, "Weapon", true);
	self:CreateSelectDeselectAll(appearances, addon.L["Deselect All"], addon.Filters.db.profile.Custom, "Weapon", false);
	custom:Add(appearances);
	if addon.Util.IsMainline then
		self:AddCheckBox(custom, addon.L["Appearance Sets"], {"Custom", "TransmogSets"});
		self:AddCheckBox(custom, addon.L["Illusions"], {"Custom", "Illusions"});
		self:AddCheckBox(custom, addon.L["Recipes"], {"Custom", "Recipes"});
		self:AddCheckBox(custom, addon.L["Housing"], {"Custom", "Housing"});
	end
	self:AddCheckBox(custom, addon.L["Other"], {"Custom", "Other"});
	menu:Add(custom);

	menu:AddSeparator();

	self:AddTitle(menu, addon.L["Hide collected"]);
	if addon.Util.IsMainline then
		self:AddCheckBox(menu, addon.L["Pets"], {"HideCollected", "Pets"});
	end
	self:AddCheckBox(menu, addon.L["Mounts"], {"HideCollected", "Mounts"});
	self:AddCheckBox(menu, addon.L["Toys"], {"HideCollected", "Toys"});
	self:AddCheckBox(menu, addon.L["Appearances"], {"HideCollected", "Transmog"});
	if addon.Util.IsMainline then
		self:AddCheckBox(menu, addon.L["Appearance Sets"], {"HideCollected", "TransmogSets"});
		self:AddCheckBox(menu, addon.L["Illusions"], {"HideCollected", "Illusions"});
		self:AddCheckBox(menu, addon.L["Recipes"], {"HideCollected", "Recipes"});
		self:AddCheckBox(menu, addon.L["Housing"], {"HideCollected", "Housing"});
	end

	return menu;
end

function KrowiEVU_FilterButtonMixin:MyOnMouseDown()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	self:BuildMenu();
    menu:Toggle(self, 96, 15);
end

hooksecurefunc("MerchantFrame_SetFilter", function(self, filter)
	if not filter then
		return;
	end
	KrowiEVU_Filters = KrowiEVU_Filters or {};
	KrowiEVU_Filters.LastFilter = filter;
end);

hooksecurefunc("ResetSetMerchantFilter", function(self)
	if addon.Options.db.profile.RememberFilter and KrowiEVU_Filters.LastFilter then
		MerchantFrame_SetFilter(nil, KrowiEVU_Filters.LastFilter);
	end
	KrowiEVU_FilterButton:SetText(GetLootFilterText(GetMerchantFilter()));
end);
-- [[ Namespaces ]] --
local _, addon = ...;
local merchantItemsContainer = addon.Gui.MerchantItemsContainer;

KrowiMFE_OptionsButtonMixin = {};

function KrowiMFE_OptionsButtonMixin:AddRadioButton(parentMenu, _menu, text, options, keys, func)
    _menu:AddFull({  Text = text,
                    Checked = function() -- Same
                        return addon.Util.ReadNestedKeys(options, keys) == text; -- e.g.: return filters.SortBy.Criteria == addon.L["Default"]
                    end,
                    Func = function()
                        addon.Util.WriteNestedKeys(options, keys, text); -- e.g.: filters.SortBy.Criteria = text;
                        parentMenu:SetSelectedName(text);
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

local menu = LibStub("Krowi_Menu-1.0");
local menuItem = LibStub("Krowi_MenuItem-1.0");
function KrowiMFE_OptionsButtonMixin:MyOnMouseDown()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);

    -- Reset menu
	menu:Clear();

	local direction = menuItem:New({Text = addon.L["Direction"]});
	self:AddRadioButton(menu, direction, addon.L["Rows first"], addon.Options.db, {"Direction"}, UpdateView);
	self:AddRadioButton(menu, direction, addon.L["Columns first"], addon.Options.db, {"Direction"}, UpdateView);
	menu:Add(direction);

	local rows = menuItem:New({Text = addon.L["Rows"]});
	for i = 1, 10, 1 do
		self:AddRadioButton(menu, rows, i, addon.Options.db, {"NumRows"}, UpdateView);
	end
	menu:Add(rows);

	local columns = menuItem:New({Text = addon.L["Columns"]});
	for i = 2, 6, 1 do
		self:AddRadioButton(menu, columns, i, addon.Options.db, {"NumColumns"}, UpdateView);
	end
	menu:Add(columns);

	menu:Toggle(self, 96, 15);
end
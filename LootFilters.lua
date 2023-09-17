local _, addon = ...;

LE_LOOT_FILTER_NEW_RANGE = 100
LE_LOOT_FILTER_PETS = 101;
LE_LOOT_FILTER_MOUNTS = 102;

addon.LootFilters = {};
local lootFilters = addon.LootFilters;

function lootFilters:Validate(lootFilter, itemId)
	if lootFilter == LE_LOOT_FILTER_PETS then
		return self.Pets(itemId);
    elseif lootFilter == LE_LOOT_FILTER_MOUNTS then
        return self.Mounts(itemId);
	end
end

function lootFilters.Pets(itemId)
	local classId, subclassId = select(12, GetItemInfo(itemId));
	return classId == Enum.ItemClass.Miscellaneous and subclassId == Enum.ItemMiscellaneousSubclass.CompanionPet;
end

function lootFilters.Mounts(itemId)
	local classId, subclassId = select(12, GetItemInfo(itemId));
	return classId == Enum.ItemClass.Miscellaneous and subclassId == Enum.ItemMiscellaneousSubclass.Mount;
end
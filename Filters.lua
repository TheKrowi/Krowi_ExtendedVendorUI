local _, addon = ...;
addon.Filters = {};
local filters = addon.Filters;

LE_LOOT_FILTER_NEW_RANGE = 100
LE_LOOT_FILTER_PETS = 101;
LE_LOOT_FILTER_MOUNTS = 102;

local defaults = {
	profile = {
		HideOwnedPets = false,
		HideCollectedMounts = false
	}
};

function filters:RefreshFilters()
    -- for t, _ in next, addon.Tabs do
    --     addon.Tabs[t].Filters = self.db.profile.Tabs[t];
    -- end
end

function filters:Load()
	self.db = LibStub("AceDB-3.0"):New("KrowiEVU_Filters", defaults, true);
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshFilters");
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshFilters");
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshFilters");
end

function filters:Validate(lootFilter, itemId)
	if self.Pets(itemId) and addon.Filters.db.profile.HideOwnedPets then
		return (C_PetJournal.GetNumCollectedInfo((select(13, C_PetJournal.GetPetInfoByItemID(itemId))))) == 0;
	end

	if self.Mounts(itemId) and addon.Filters.db.profile.HideCollectedMounts then
		return not (select(11, C_MountJournal.GetMountInfoByID(C_MountJournal.GetMountFromItem(itemId))));
	end

	return true;
	-- if lootFilter == LE_LOOT_FILTER_PETS then
	-- 	return self.Pets(itemId);
    -- elseif lootFilter == LE_LOOT_FILTER_MOUNTS then
    --     return self.Mounts(itemId);
	-- end
end

function filters.Pets(itemId)
	local classId, subclassId = select(12, GetItemInfo(itemId));
	return classId == Enum.ItemClass.Miscellaneous and subclassId == Enum.ItemMiscellaneousSubclass.CompanionPet;
end

function filters.Mounts(itemId)
	local classId, subclassId = select(12, GetItemInfo(itemId));
	return classId == Enum.ItemClass.Miscellaneous and subclassId == Enum.ItemMiscellaneousSubclass.Mount;
end
local _, addon = ...;
addon.Filters = {};
local filters = addon.Filters;

_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_NEW_RANGE"] = 100;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_PETS"] = 101;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_MOUNTS"] = 102;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TOYS"] = 103;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG"] = 104;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_RECIPES"] = 105;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_CUSTOM"] = 200;
_G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_SEARCH"] = 201;

filters.ArmorTypes = {
	[0] = "Generic",
	[1] = "Cloth",
	[2] = "Leather",
	[3] = "Mail",
	[4] = "Plate",
	[5] = "Cosmetic",
	[6] = "Shield",
};

filters.WeaponTypes = {
	[0] = "OneHAxe",
	[1] = "TwoHAxe",
	[2] = "Bow",
	[3] = "Gun",
	[4] = "OneHMace",
	[5] = "TwoHMace",
	[6] = "Polearm",
	[7] = "OneHSword",
	[8] = "TwoHSword",
	[9] = "Warglaives",
	[10] = "Staff",
	[11] = "Bearclaw",
	[12] = "Catclaw",
	[13] = "Fist",
	[14] = "Generic",
	[15] = "Dagger",
	[16] = "Thrown",
	[18] = "Crossbow",
	[19] = "Wand",
	[20] = "Fishingpole",
};

local defaults = {
	profile = {
		HideCollected = {
			Pets = false,
			Mounts = false,
			Toys = false,
			Transmog = false,
			Recipes = false
		},
		Custom = {
			Pets = true,
			Mounts = true,
			Toys = true,
			Transmog = true,
			Recipes = true,
			Other = true,
			Armor = { --[[ Automatically generated ]] },
			Weapon = { --[[ Automatically generated ]] }
		},
		OnlyShow = {
			Armor = { --[[ Automatically generated ]] },
			Weapon = { --[[ Automatically generated ]] }
		}
	}
};

for index, _ in next, filters.ArmorTypes do
	defaults.profile.Custom.Armor[index] = true;
	defaults.profile.OnlyShow.Armor[index] = true;
end
for index, _ in next, filters.WeaponTypes do
	defaults.profile.Custom.Weapon[index] = true;
	defaults.profile.OnlyShow.Weapon[index] = true;
end

if not addon.Util.IsMainline then
	local merchantFilter = LE_LOOT_FILTER_ALL;
	function GetMerchantFilter()
		return merchantFilter;
	end

	function SetMerchantFilter(newMerchantFilter)
		merchantFilter = newMerchantFilter;
	end
end

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
	if lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_PETS"] then
		return self:ValidatePetsOnly(itemId);
    elseif lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_MOUNTS"] then
		return self:ValidateMountsOnly(itemId);
    elseif lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TOYS"] then
		return self:ValidateToysOnly(itemId);
    elseif lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_TRANSMOG"] then
		return self:ValidateTransmogOnly(itemId);
    elseif lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_RECIPES"] then
		return self:ValidateRecipesOnly(itemId);
    elseif lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_CUSTOM"] then
		return self:ValidateCustom(itemId);
    elseif lootFilter == _G[addon.Metadata.Prefix .. "_LE_LOOT_FILTER_SEARCH"] then
		return self:ValidateSearch(itemId);
	else
		if self.IsPet(itemId) and addon.Filters.db.profile.HideCollected.Pets then
			return not self.IsPetCollected(itemId);
		end

		if self.IsMount(itemId) and addon.Filters.db.profile.HideCollected.Mounts then
			return not self.IsMountCollected(itemId);
		end

		if self.IsToy(itemId) and addon.Filters.db.profile.HideCollected.Toys then
			return not self.IsToyCollected(itemId);
		end

		if self.IsTransmog(itemId) and addon.Filters.db.profile.HideCollected.Transmog then
			return not self.IsTransmogCollected(itemId);
		end

		if self.IsRecipe(itemId) and addon.Filters.db.profile.HideCollected.Recipes then
			return not self.IsRecipeCollected(itemId);
		end
	end

	return true;
end

do -- Pets
	function filters:ValidatePetsOnly(itemId)
		if not self.IsPet(itemId) then
			return false;
		end
		if addon.Filters.db.profile.HideCollected.Pets then
			return not self.IsPetCollected(itemId);
		end
		return true;
	end

	function filters.IsPet(itemId)
		local classId, subclassId = select(6, C_Item.GetItemInfoInstant(itemId));
		if classId ~= Enum.ItemClass.Miscellaneous or subclassId ~= Enum.ItemMiscellaneousSubclass.CompanionPet then
			return false;
		end

		local name = C_PetJournal.GetPetInfoByItemID(itemId);
		return name ~= nil;
	end

	function filters.IsPetCollected(itemId)
		return (C_PetJournal.GetNumCollectedInfo((select(13, C_PetJournal.GetPetInfoByItemID(itemId))))) ~= 0;
	end
end

do -- Mounts
	function filters:ValidateMountsOnly(itemId)
		if not self.IsMount(itemId) then
			return false;
		end
		if addon.Filters.db.profile.HideCollected.Mounts then
			return not self.IsMountCollected(itemId);
		end
		return true;
	end

	function filters.IsMount(itemId)
		if itemId == 37011 then -- Magic Broom is classified as a mount but can't be learned
			return false;
		end
		local classId, subclassId = select(6, C_Item.GetItemInfoInstant(itemId));
		return classId == Enum.ItemClass.Miscellaneous and subclassId == Enum.ItemMiscellaneousSubclass.Mount;
	end

	function filters.IsMountCollected(itemId)
		local mountId = C_MountJournal.GetMountFromItem(itemId);
		if mountId then
			return (select(11, C_MountJournal.GetMountInfoByID(mountId)));
		end
	end
end

do -- Toys
	function filters:ValidateToysOnly(itemId)
		if not self.IsToy(itemId) then
			return false;
		end
		if addon.Filters.db.profile.HideCollected.Toys then
			return not self.IsToyCollected(itemId);
		end
		return true;
	end

	function filters.IsToy(itemId)
		itemId = C_ToyBox.GetToyInfo(itemId);
		return itemId ~= nil;
	end

	function filters.IsToyCollected(itemId)
		return PlayerHasToy(itemId);
	end
end

do -- Transmog
	function filters:ValidateTransmogOnly(itemId)
		if not self.IsTransmog(itemId) then
			return false;
		end
		if addon.Filters.db.profile.HideCollected.Transmog and self.IsTransmogCollected(itemId) then
			return false;
		end
		local _, _, _, itemEquipLoc, _, classId, subClassId = C_Item.GetItemInfoInstant(itemId);
		if classId == Enum.ItemClass.Armor and addon.Filters.db.profile.OnlyShow.Armor[subClassId] ~= nil then
			return addon.Filters.db.profile.OnlyShow.Armor[subClassId];
		elseif classId == Enum.ItemClass.Weapon and addon.Filters.db.profile.OnlyShow.Weapon[subClassId] ~= nil then
			return addon.Filters.db.profile.OnlyShow.Weapon[subClassId];
		end
		return true;
	end

	function filters.IsTransmog(itemId)
		itemId = C_TransmogCollection.GetItemInfo(itemId);
		return itemId ~= nil;
	end

	function filters.IsTransmogCollected(itemId)
		return C_TransmogCollection.PlayerHasTransmog(itemId);
	end
end

do -- Recipes
	function filters:ValidateRecipesOnly(itemId)
		if not self.IsRecipe(itemId) then
			return false;
		end
		if addon.Filters.db.profile.HideCollected.Recipes then
			return not self.IsRecipeCollected(itemId);
		end
		return true;
	end

	function filters.IsRecipe(itemId)
		local classId = select(6, C_Item.GetItemInfoInstant(itemId));
		return classId == Enum.ItemClass.Recipe;
	end

	function filters.IsRecipeCollected(itemId)
		local tooltipInfo = C_TooltipInfo.GetItemByID(itemId);
		for _, line in next, tooltipInfo.lines do
			if line.type == Enum.TooltipDataLineType.RestrictedSpellKnown then
				return true;
			end
		end
		return false;
	end
end

do -- Custom
	function filters:ValidateCustom(itemId)
		if self.IsPet(itemId) then
			if addon.Filters.db.profile.Custom.Pets then
				if addon.Filters.db.profile.HideCollected.Pets then
					return not self.IsPetCollected(itemId);
				end
				return true;
			end
			return false;
		end

		if self.IsMount(itemId) then
			if addon.Filters.db.profile.Custom.Mounts then
				if addon.Filters.db.profile.HideCollected.Mounts then
					return not self.IsMountCollected(itemId);
				end
				return true;
			end
			return false;
		end

		if self.IsToy(itemId) then
			if addon.Filters.db.profile.Custom.Toys then
				if addon.Filters.db.profile.HideCollected.Toys then
					return not self.IsToyCollected(itemId);
				end
				return true;
			end
			return false;
		end

		if self.IsTransmog(itemId) then
			if addon.Filters.db.profile.Custom.Transmog then
				if addon.Filters.db.profile.HideCollected.Transmog and self.IsTransmogCollected(itemId) then
					return false;
				end
				local _, _, _, itemEquipLoc, _, classId, subClassId = C_Item.GetItemInfoInstant(itemId);
				if classId == Enum.ItemClass.Armor and addon.Filters.db.profile.Custom.Armor[subClassId] ~= nil then
					return addon.Filters.db.profile.Custom.Armor[subClassId];
				elseif classId == Enum.ItemClass.Weapon and addon.Filters.db.profile.Custom.Weapon[subClassId] ~= nil then
					return addon.Filters.db.profile.Custom.Weapon[subClassId];
				end
				return true;
			end
			return false;
		end

		if self.IsRecipe(itemId) then
			if addon.Filters.db.profile.Custom.Recipes then
				if addon.Filters.db.profile.HideCollected.Recipes then
					return not self.IsRecipeCollected(itemId);
				end
				return true;
			end
			return false;
		end

		return addon.Filters.db.profile.Custom.Other;
	end
end

do -- Search
	function filters:ValidateSearch(itemId)
		local name = C_Item.GetItemInfo(itemId);
		if name and strfind(name:lower(), KrowiEVU_SearchBox:GetText():lower(), 1, true) then
			return true;
		end
		return false;
	end
end
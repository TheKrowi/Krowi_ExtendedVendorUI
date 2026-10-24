local _, addon = ...
if addon.NotLoaded then return end
addon.Filters = {}
local filters = addon.Filters

_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_NEW_RANGE'] = 100
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_PETS'] = 101
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_MOUNTS'] = 102
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TOYS'] = 103
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG'] = 104
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_RECIPES'] = 105
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG_SETS'] = 106
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_ILLUSIONS'] = 107
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_HOUSING'] = 108
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_CUSTOM'] = 200
_G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] = 201

filters.ArmorTypes = {
	[0] = 'Generic',
	[1] = 'Cloth',
	[2] = 'Leather',
	[3] = 'Mail',
	[4] = 'Plate',
	[5] = 'Cosmetic',
	[6] = 'Shield',
}

filters.WeaponTypes = {
	[0] = 'OneHAxe',
	[1] = 'TwoHAxe',
	[2] = 'Bow',
	[3] = 'Gun',
	[4] = 'OneHMace',
	[5] = 'TwoHMace',
	[6] = 'Polearm',
	[7] = 'OneHSword',
	[8] = 'TwoHSword',
	[9] = addon.Util.IsMainline and 'Warglaives' or nil,
	[10] = 'Staff',
	[11] = 'Bearclaw',
	[12] = 'Catclaw',
	[13] = 'Fist',
	[14] = 'Generic',
	[15] = 'Dagger',
	[16] = 'Thrown',
	[18] = 'Crossbow',
	[19] = 'Wand',
	[20] = 'Fishingpole',
}

-- Create sorted index arrays for consistent ordering in UI
filters.ArmorIndices = {}
for index in next, filters.ArmorTypes do
	table.insert(filters.ArmorIndices, index)
end
table.sort(filters.ArmorIndices)

filters.WeaponIndices = {}
for index in next, filters.WeaponTypes do
	table.insert(filters.WeaponIndices, index)
end
table.sort(filters.WeaponIndices)

local defaults = {
	profile = {
		HideCollected = {
			Pets = false,
			Mounts = false,
			Toys = false,
			Transmog = false,
			TransmogSets = false,
			Illusions = false,
			Recipes = false,
			RecipesOtherCharacters = false,
			Housing = false,
		},
		Custom = {
			Pets = true,
			Mounts = true,
			Toys = true,
			Transmog = true,
			TransmogSets = true,
			Illusions = true,
			Recipes = true,
			Housing = true,
			Other = true,
			Armor = { --[[ Automatically generated ]] },
			Weapon = { --[[ Automatically generated ]] },
		},
		OnlyShow = {
			Armor = { --[[ Automatically generated ]] },
			Weapon = { --[[ Automatically generated ]] },
		},
		HousingQuantity = 1,
		Gear = { -- Weapons and armor, under every filter
			UsableOnly = false,
			HideSubOptimalArmor = false,
			MinQuality = 0, -- An Enum.ItemQuality value; 0 is off
		},
	}
}

for index, _ in next, filters.ArmorTypes do
	defaults.profile.Custom.Armor[index] = true
	defaults.profile.OnlyShow.Armor[index] = true
end
for index, _ in next, filters.WeaponTypes do
	defaults.profile.Custom.Weapon[index] = true
	defaults.profile.OnlyShow.Weapon[index] = true
end

-- [[ Active filter ]] --
-- The addon keeps the active filter itself. On Retail the server filter is set to the same value as well, so the server returns the same list as before.
local currentFilter
local listeners = {}

local function NotifyListeners(filter)
	for _, listener in next, listeners do
		listener(filter)
	end
end

function filters:GetFilter()
	if currentFilter then
		return currentFilter
	end
	if addon.Util.IsModern then
		return GetMerchantFilter()
	end
	return LE_LOOT_FILTER_ALL
end

function filters:SetFilter(filter)
	currentFilter = filter
	if addon.Util.IsModern then
		SetMerchantFilter(filter)
	end
	if filter then
		KrowiEVU_Filters = KrowiEVU_Filters or {}
		KrowiEVU_Filters.LastFilter = filter
	end
	NotifyListeners(filter)
end

-- Takes over the filter Blizzard's ResetSetMerchantFilter just set on Retail, without remembering it or telling the listeners, as before
function filters:SyncFilter()
	currentFilter = addon.Util.IsModern and GetMerchantFilter() or LE_LOOT_FILTER_ALL
end

function filters:RegisterListener(listener)
	tinsert(listeners, listener)
end

-- The vendor's real indices that pass the active filter and the gear options
function filters:BuildList(list)
	wipe(list)
	local lootFilter = self:GetFilter()
	self:PrepareGear()
	for i = 1, GetMerchantNumItems() do
		local itemId = GetMerchantItemID(i)
		if itemId == nil or (self:Validate(lootFilter, itemId) and self:ValidateGear(i, itemId)) then
			tinsert(list, i)
		end
		if itemId then
			self.RecordRecipe(itemId)
		end
	end
	return list
end

-- [[ Gear ]] --
-- The armor proficiency spells, best first, with the armor subclass each allows (Cloth 1, Leather 2, Mail 3, Plate 4)
local ARMOR_PROFICIENCIES = {
	{ Spell = 750, SubClass = 4 }, -- Plate Mail
	{ Spell = 8737, SubClass = 3 }, -- Mail
	{ Spell = 9077, SubClass = 2 }, -- Leather
}

local bestArmorSubClass
-- Once per list: the best armor the character can wear, or nil for cloth only, when the sub-optimal check has nothing to hide
function filters:PrepareGear()
	bestArmorSubClass = nil
	if not self.db.profile.Gear.HideSubOptimalArmor then
		return
	end
	for _, proficiency in ipairs(ARMOR_PROFICIENCIES) do
		if C_SpellBook.IsSpellKnown(proficiency.Spell) then
			bestArmorSubClass = proficiency.SubClass
			return
		end
	end
end

function filters:GetBestArmorSubClass()
	return bestArmorSubClass
end

-- Weapons and armor only; an item whose data is not loaded yet stays in the list
function filters:ValidateGear(index, itemId)
	local gear = self.db.profile.Gear
	if not (gear.UsableOnly or gear.HideSubOptimalArmor or gear.MinQuality > 0) then
		return true
	end
	local _, _, _, equipLoc, _, classId, subClassId = C_Item.GetItemInfoInstant(itemId)
	if classId ~= Enum.ItemClass.Armor and classId ~= Enum.ItemClass.Weapon then
		return true
	end
	if gear.UsableOnly then
		local info = addon.Gui.MerchantItemSlot.GetItemInfo(index)
		if info and info.name and not info.isUsable then
			return false
		end
	end
	-- Cloth, leather and mail worn on the body; a cloak is cloth for everyone
	if bestArmorSubClass and classId == Enum.ItemClass.Armor and subClassId >= 1 and subClassId < bestArmorSubClass and equipLoc ~= 'INVTYPE_CLOAK' then
		return false
	end
	if gear.MinQuality > 0 then
		local quality = C_Item.GetItemQualityByID(itemId)
		if quality and quality < gear.MinQuality then
			return false
		end
	end
	return true
end

function filters:RefreshFilters()
    -- for t, _ in next, addon.Tabs do
    --     addon.Tabs[t].Filters = self.db.profile.Tabs[t]
    -- end
end

function filters:Load()
	self.db = LibStub('AceDB-3.0'):New('KrowiEVU_Filters', defaults, true)
    self.db.RegisterCallback(self, 'OnProfileChanged', 'RefreshFilters')
    self.db.RegisterCallback(self, 'OnProfileCopied', 'RefreshFilters')
    self.db.RegisterCallback(self, 'OnProfileReset', 'RefreshFilters')
end

function filters:Validate(lootFilter, itemId)
	if lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_PETS'] then
		return self:ValidatePetsOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_MOUNTS'] then
		return self:ValidateMountsOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TOYS'] then
		return self:ValidateToysOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG'] then
		return self:ValidateTransmogOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_TRANSMOG_SETS'] then
		return self:ValidateTransmogSetOnly(itemId)
	elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_ILLUSIONS'] then
		return self:ValidateIllusionOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_RECIPES'] then
		return self:ValidateRecipesOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_HOUSING'] then
		return self:ValidateHousingOnly(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_CUSTOM'] then
		return self:ValidateCustom(itemId)
    elseif lootFilter == _G[addon.Metadata.Prefix .. '_LE_LOOT_FILTER_SEARCH'] then
		return self:ValidateSearch(itemId)
	else
		if self.IsPet(itemId) and addon.Filters.db.profile.HideCollected.Pets then
			return not self.IsPetCollected(itemId)
		end

		if self.IsMount(itemId) and addon.Filters.db.profile.HideCollected.Mounts then
			return not self.IsMountCollected(itemId)
		end

		if self.IsToy(itemId) and addon.Filters.db.profile.HideCollected.Toys then
			return not self.IsToyCollected(itemId)
		end

		if self.IsTransmog(itemId) and addon.Filters.db.profile.HideCollected.Transmog then
			return not self.IsTransmogCollected(itemId)
		end

		if self.IsTransmogSet(itemId) and addon.Filters.db.profile.HideCollected.TransmogSets then
			return not self.IsTransmogSetCollected(itemId)
		end

		if self.IsIllusion(itemId) and addon.Filters.db.profile.HideCollected.Illusions then
			return not self.IsIllusionCollected(itemId)
		end

		if self.IsRecipe(itemId) and self.IsRecipeHidden(itemId) then
			return false
		end

		if self.IsHousing(itemId) and addon.Filters.db.profile.HideCollected.Housing then
			return not self.IsHousingCollected(itemId)
		end
	end

	return true
end

if addon.Util.IsModern then -- Pets
	function filters:ValidatePetsOnly(itemId)
		if not self.IsPet(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.Pets then
			return not self.IsPetCollected(itemId)
		end
		return true
	end

	function filters.IsPet(itemId)
		if itemId == 22200 or itemId == 22235 then -- Silver Shafted Arrow and Truesilver Shafted Arrow is classified as a pet but works differntly by adding a pet to another player, not yourself
			return false
		end
		local classId, subclassId = select(6, C_Item.GetItemInfoInstant(itemId))
		if classId ~= Enum.ItemClass.Miscellaneous or subclassId ~= Enum.ItemMiscellaneousSubclass.CompanionPet then
			return false
		end

		local name = C_PetJournal.GetPetInfoByItemID(itemId)
		return name ~= nil
	end

	function filters.IsPetCollected(itemId)
		return (C_PetJournal.GetNumCollectedInfo((select(13, C_PetJournal.GetPetInfoByItemID(itemId))))) ~= 0
	end
else
	function filters.IsPet(itemId)
		return false
	end

	function filters.IsPetCollected(itemId)
		return false
	end
end

do -- Mounts
	function filters:ValidateMountsOnly(itemId)
		if not self.IsMount(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.Mounts then
			return not self.IsMountCollected(itemId)
		end
		return true
	end

	function filters.IsMount(itemId)
		if itemId == 37011 then -- Magic Broom is classified as a mount but can't be learned
			return false
		end
		local classId, subclassId = select(6, C_Item.GetItemInfoInstant(itemId))
		return classId == Enum.ItemClass.Miscellaneous and subclassId == Enum.ItemMiscellaneousSubclass.Mount
	end

	function filters.IsMountCollected(itemId)
		local mountId = C_MountJournal.GetMountFromItem(itemId)
		if mountId then
			return (select(11, C_MountJournal.GetMountInfoByID(mountId)))
		end
	end
end

do -- Toys
	function filters:ValidateToysOnly(itemId)
		if not self.IsToy(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.Toys then
			return not self.IsToyCollected(itemId)
		end
		return true
	end

	function filters.IsToy(itemId)
		itemId = C_ToyBox.GetToyInfo(itemId)
		return itemId ~= nil
	end

	function filters.IsToyCollected(itemId)
		return PlayerHasToy(itemId)
	end
end

do -- Transmog
	function filters:ValidateTransmogOnly(itemId)
		if not self.IsTransmog(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.Transmog and self.IsTransmogCollected(itemId) then
			return false
		end
		local classId, subClassId = select(6, C_Item.GetItemInfoInstant(itemId))
		if classId == Enum.ItemClass.Armor and addon.Filters.db.profile.OnlyShow.Armor[subClassId] ~= nil then
			return addon.Filters.db.profile.OnlyShow.Armor[subClassId]
		elseif classId == Enum.ItemClass.Weapon and addon.Filters.db.profile.OnlyShow.Weapon[subClassId] ~= nil then
			return addon.Filters.db.profile.OnlyShow.Weapon[subClassId]
		end
		return true
	end

	function filters.IsTransmog(itemId)
		itemId = C_TransmogCollection.GetItemInfo(itemId)
		return itemId ~= nil
	end

	function filters.IsTransmogCollected(itemId)
		return C_TransmogCollection.PlayerHasTransmog(itemId)
	end
end

if addon.Util.IsModern then -- Transmog Set
	function filters:ValidateTransmogSetOnly(itemId)
		if not self.IsTransmogSet(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.TransmogSets then
			return not self.IsTransmogSetCollected(itemId)
		end
		return true
	end

	function filters.IsTransmogSet(itemId)
		local setId = C_Item.GetItemLearnTransmogSet(itemId)
		return setId ~= nil
	end

	function filters.IsTransmogSetCollected(itemId)
		local setId = C_Item.GetItemLearnTransmogSet(itemId)
		local setItems = C_Transmog.GetAllSetAppearancesByID(setId)
		if not setItems then
			return false
		end
		for _, setItem in next, setItems do
			if not filters.IsTransmogCollected(setItem.itemID) then
				return false
			end
		end
		return true
	end
else
	function filters.IsTransmogSet(itemId)
		return false
	end

	function filters.IsTransmogSetCollected(itemId)
		return false
	end
end

if addon.Util.IsModern then -- Illusion
	function filters:ValidateIllusionOnly(itemId)
		if not self.IsIllusion(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.Illusions then
			return not self.IsIllusionCollected(itemId)
		end
		return true
	end

	function filters.IsIllusion(itemId)
		local classId, subclassId = select(6, C_Item.GetItemInfoInstant(itemId))
		return classId == Enum.ItemClass.Consumable and subclassId == Enum.ItemConsumableSubclass.Other
	end

	function filters.IsIllusionCollected(itemId)
		local tooltipInfo = C_TooltipInfo.GetItemByID(itemId)
		for _, line in next, tooltipInfo.lines do
			if line.type == Enum.TooltipDataLineType.RestrictedSpellKnown then
				return true
			end
		end
		return false
	end
else
	function filters.IsIllusion(itemId)
		return false
	end

	function filters.IsIllusionCollected(itemId)
		return false
	end
end

if addon.Util.IsModern then -- Recipes
	function filters:ValidateRecipesOnly(itemId)
		if not self.IsRecipe(itemId) then
			return false
		end
		return not self.IsRecipeHidden(itemId)
	end

	function filters.IsRecipe(itemId)
		local classId, subclassId = select(6, C_Item.GetItemInfoInstant(itemId))
		if classId == Enum.ItemClass.Recipe then
			return true
		end
		if classId == Enum.ItemClass.Consumable and subclassId ~= Enum.ItemConsumableSubclass.Other then
			local tooltipInfo = C_TooltipInfo.GetItemByID(itemId)
			if tooltipInfo then
				for _, line in next, tooltipInfo.lines do
					if line.type == Enum.TooltipDataLineType.ItemSpellTriggerLearn then
						return true
					end
				end
			end
		end
		return false
	end

	-- Account wide, per character: the recipe items a vendor showed it that it knows, for Hide collected, Recipes my other
	-- characters know
	local characterKey
	local function GetKnownRecipes()
		characterKey = characterKey or (UnitName('player') .. '-' .. GetRealmName())
		addon.Filters.db.global.KnownRecipes = addon.Filters.db.global.KnownRecipes or {}
		return addon.Filters.db.global.KnownRecipes, characterKey
	end

	local function Record(itemId, known)
		if not C_Item.IsItemDataCachedByID(itemId) then
			return -- The tooltip may not be complete yet, and would clear a recipe this character knows
		end
		local knownRecipes, character = GetKnownRecipes()
		knownRecipes[character] = knownRecipes[character] or {}
		knownRecipes[character][itemId] = known or nil -- A dropped profession clears on the next visit
	end

	-- Also returns whether the tooltip could be read at all
	function filters.IsRecipeCollected(itemId)
		local tooltipInfo = C_TooltipInfo.GetItemByID(itemId)
		if not tooltipInfo then
			return false, false
		end
		for _, line in next, tooltipInfo.lines do
			if issecretvalue and issecretvalue(line.leftText) then
				return false, false -- Tooltip text is secret under some restrictions (12.x)
			end
			if line.leftText == ITEM_SPELL_KNOWN then
                return true, true
            end
		end
		return false, true
	end

	function filters.IsRecipeKnownByOtherCharacter(itemId)
		local knownRecipes, character = GetKnownRecipes()
		for name, recipes in next, knownRecipes do
			if name ~= character and recipes[itemId] then
				return true
			end
		end
		return false
	end

	-- Hide collected, Recipes (this character) and Recipes my other characters know
	function filters.IsRecipeHidden(itemId)
		local hideCollected = addon.Filters.db.profile.HideCollected
		return (hideCollected.Recipes and filters.IsRecipeCollected(itemId))
			or (hideCollected.RecipesOtherCharacters and filters.IsRecipeKnownByOtherCharacter(itemId)) or false
	end

	-- Every recipe item a vendor shows is recorded once a visit, whatever the Hide collected options. Cleared when the window
	-- closes: Blizzard can draw a vendor before its MERCHANT_SHOW.
	local recorded = {}
	local recordFrame = CreateFrame('Frame')
	recordFrame:RegisterEvent('MERCHANT_CLOSED')
	recordFrame:SetScript('OnEvent', function()
		wipe(recorded)
	end)

	function filters.RecordRecipe(itemId)
		if recorded[itemId] or not C_Item.IsItemDataCachedByID(itemId) then
			return
		end
		recorded[itemId] = true
		if filters.IsRecipe(itemId) then
			local known, readable = filters.IsRecipeCollected(itemId)
			if readable then
				Record(itemId, known)
			end
		end
	end
else
	function filters.IsRecipe(itemId)
		return false
	end

	function filters.IsRecipeCollected(itemId)
		return false
	end

	function filters.IsRecipeHidden(itemId)
		return false
	end

	function filters.RecordRecipe(itemId)
	end
end

if addon.Util.IsMainline then -- Housing
	function filters:ValidateHousingOnly(itemId)
		if not self.IsHousing(itemId) then
			return false
		end
		if addon.Filters.db.profile.HideCollected.Housing then
			return not self.IsHousingCollected(itemId)
		end
		return true
	end

	function filters.IsHousing(itemId)
		local classId = select(6, C_Item.GetItemInfoInstant(itemId))
		return classId == Enum.ItemClass.Housing
	end

	-- Owned anywhere: in storage, placed in a house or plot, or granted and not yet placed (live HousingCatalogUIDocumentation.lua:555-557)
	function filters.IsHousingCollected(itemId)
		local entryInfo = C_HousingCatalog.GetCatalogEntryInfoByItem(itemId)
		if entryInfo then
			local owned = (entryInfo.totalNumStored or 0) + (entryInfo.totalNumPlaced or 0) + (entryInfo.remainingRedeemable or 0)
			return owned >= addon.Filters.db.profile.HousingQuantity
		end
		return false
	end
else
	function filters.IsHousing(itemId)
		return false
	end

	function filters.IsHousingCollected(itemId)
		return false
	end
end

do -- Custom
	function filters:ValidateCustom(itemId)
		if self.IsPet(itemId) then
			if addon.Filters.db.profile.Custom.Pets then
				if addon.Filters.db.profile.HideCollected.Pets then
					return not self.IsPetCollected(itemId)
				end
				return true
			end
			return false
		end

		if self.IsMount(itemId) then
			if addon.Filters.db.profile.Custom.Mounts then
				if addon.Filters.db.profile.HideCollected.Mounts then
					return not self.IsMountCollected(itemId)
				end
				return true
			end
			return false
		end

		if self.IsToy(itemId) then
			if addon.Filters.db.profile.Custom.Toys then
				if addon.Filters.db.profile.HideCollected.Toys then
					return not self.IsToyCollected(itemId)
				end
				return true
			end
			return false
		end

		if self.IsTransmog(itemId) then
			if addon.Filters.db.profile.Custom.Transmog then
				if addon.Filters.db.profile.HideCollected.Transmog and self.IsTransmogCollected(itemId) then
					return false
				end
				local _, _, _, itemEquipLoc, _, classId, subClassId = C_Item.GetItemInfoInstant(itemId)
				if classId == Enum.ItemClass.Armor and addon.Filters.db.profile.Custom.Armor[subClassId] ~= nil then
					return addon.Filters.db.profile.Custom.Armor[subClassId]
				elseif classId == Enum.ItemClass.Weapon and addon.Filters.db.profile.Custom.Weapon[subClassId] ~= nil then
					return addon.Filters.db.profile.Custom.Weapon[subClassId]
				end
				return true
			end
			return false
		end

		if self.IsTransmogSet(itemId) then
			if addon.Filters.db.profile.Custom.TransmogSets then
				if addon.Filters.db.profile.HideCollected.TransmogSets then
					return not self.IsTransmogSetCollected(itemId)
				end
				return true
			end
			return false
		end

		if self.IsIllusion(itemId) then
			if addon.Filters.db.profile.Custom.Illusions then
				if addon.Filters.db.profile.HideCollected.Illusions then
					return not self.IsIllusionCollected(itemId)
				end
				return true
			end
			return false
		end

		if self.IsRecipe(itemId) then
			if addon.Filters.db.profile.Custom.Recipes then
				return not self.IsRecipeHidden(itemId)
			end
			return false
		end

		if self.IsHousing(itemId) then
			if addon.Filters.db.profile.Custom.Housing then
				if addon.Filters.db.profile.HideCollected.Housing then
					return not self.IsHousingCollected(itemId)
				end
				return true
			end
			return false
		end

		return addon.Filters.db.profile.Custom.Other
	end
end

do -- Search
	function filters:ValidateSearch(itemId)
		local name = C_Item.GetItemInfo(itemId)
		if name and strfind(name:lower(), KrowiEVU_SearchBox:GetText():lower(), 1, true) then
			return true
		end
		return false
	end
end
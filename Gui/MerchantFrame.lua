-- [[ Namespaces ]] --
local _, addon = ...;
local merchantItemsContainer = addon.Gui.MerchantItemsContainer;
local originalWidth, originalHeight = MerchantFrame:GetSize();

do -- [[ Set some permanent MerchantFrame changes ]]
	MerchantFrameBottomLeftBorder:SetSize(256, 61);
	MerchantFrameBottomLeftBorder:SetTexture("Interface/MerchantFrame/Merchant");
	MerchantFrameBottomLeftBorder:SetTexCoord(0.001953125, 0.5, 0.00390625, 0.2421875);
	MerchantFrameBottomLeftBorder:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 1, 26);

	local bottomExtensionRightBorder = MerchantFrame:CreateTexture("KrowiEVU_BottomExtensionRightBorder");
	bottomExtensionRightBorder:SetSize(78, 61);
	bottomExtensionRightBorder:SetTexture("Interface/MerchantFrame/Merchant");
	bottomExtensionRightBorder:SetTexCoord(0.5, 0.650390625, 0.00390625, 0.2421875);
	bottomExtensionRightBorder:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -1, 26);

	local bottomExtensionLeftBorder = MerchantFrame:CreateTexture("KrowiEVU_BottomExtensionLeftBorder");
	bottomExtensionLeftBorder:SetSize(78, 61);
	bottomExtensionLeftBorder:SetTexture("Interface/MerchantFrame/Merchant");
	bottomExtensionLeftBorder:SetTexCoord(0.240234375, 0.390625, 0.00390625, 0.2421875);
	bottomExtensionLeftBorder:SetPoint("TOPLEFT", MerchantFrameBottomLeftBorder, "TOPRIGHT", 0, 0);

	local bottomExtensionMidBorder = MerchantFrame:CreateTexture("KrowiEVU_BottomExtensionMidBorder");
	bottomExtensionMidBorder:SetTexture("Interface/MerchantFrame/Merchant");
	bottomExtensionMidBorder:SetTexCoord(0.01953125, 0.373046875, 0.00390625, 0.2421875);
	bottomExtensionMidBorder:SetPoint("TOPLEFT", bottomExtensionLeftBorder, "TOPRIGHT", 0, 0);
	bottomExtensionMidBorder:SetPoint("BOTTOMRIGHT", bottomExtensionRightBorder, "BOTTOMLEFT", 0, 0);

	MerchantPrevPageButton:SetPoint("BOTTOMLEFT", MerchantFrameBottomLeftBorder, "TOPLEFT", 8, -5);
	MerchantNextPageButton:SetPoint("BOTTOMRIGHT", KrowiEVU_BottomExtensionRightBorder, "TOPRIGHT", -7, -5);

	MerchantFrame.FilterDropdown:Hide();
	-- MerchantFrameLootFilter:SetPoint("TOPRIGHT", MerchantFrame, -150, -28);

	MerchantMoneyInset:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -169, 27);
	-- <Anchor point="BOTTOMRIGHT" relativePoint="BOTTOMRIGHT" x="-5" y="4"/>
	-- MerchantExtraCurrencyInset:SetPoint("TOPRIGHT", MerchantFrame, "BOTTOMLEFT", 169, 27);
	MerchantExtraCurrencyInset:ClearAllPoints();
	MerchantExtraCurrencyInset:SetPoint("BOTTOMRIGHT", -167, 4);
	MerchantExtraCurrencyInset:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMRIGHT", -332, 27);
	MerchantExtraCurrencyBg:ClearAllPoints();
	MerchantExtraCurrencyBg:SetPoint("TOPRIGHT", MerchantExtraCurrencyInset, -3, -2);
	MerchantExtraCurrencyBg:SetPoint("BOTTOMLEFT", MerchantExtraCurrencyInset, 3, 2);
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	local numExtraColumns = addon.Options.db.profile.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns;
	local numExtraRows = addon.Options.db.profile.NumRows - merchantItemsContainer.DefaultMerchantInfoNumRows;
	local itemWidth = merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth;
	local itemHeight = merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight;
	local width = originalWidth + numExtraColumns * itemWidth;
	local height = originalHeight + numExtraRows * itemHeight;
	if not MerchantPageText:IsShown() then
		height = height - 36;
	end
	MerchantFrame:SetSize(width, height);
	if numExtraColumns > 0 then
		KrowiEVU_BottomExtensionLeftBorder:Show();
		KrowiEVU_BottomExtensionMidBorder:Show();
		-- Re-arange Filter Button and Search Box if extra columns are shown
		KrowiEVU_FilterButton:ClearAllPoints();
		KrowiEVU_FilterButton:SetPoint("TOPRIGHT", -10, -31);
		KrowiEVU_SearchBox:ClearAllPoints();
		KrowiEVU_SearchBox:SetPoint("RIGHT", KrowiEVU_FilterButton, "LEFT", -10, 0);
	else
		KrowiEVU_BottomExtensionLeftBorder:Hide();
		KrowiEVU_BottomExtensionMidBorder:Hide();
		-- Re-arange Filter Button and Search Box if no extra columns are shown
		KrowiEVU_FilterButton:ClearAllPoints();
		KrowiEVU_FilterButton:SetPoint("TOPRIGHT", -10, -21);
		KrowiEVU_SearchBox:ClearAllPoints();
		KrowiEVU_SearchBox:SetPoint("TOPRIGHT", KrowiEVU_FilterButton, "BOTTOMRIGHT", 0, 2);
	end
	KrowiEVU_BottomExtensionRightBorder:Show();
end);

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	MerchantFrame:SetSize(originalWidth, originalHeight);
	KrowiEVU_BottomExtensionLeftBorder:Hide();
	KrowiEVU_BottomExtensionMidBorder:Hide();
	KrowiEVU_BottomExtensionRightBorder:Hide();
end);

hooksecurefunc("MerchantFrame_UpdateRepairButtons", function()
	if not CanMerchantRepair() then
		MerchantSellAllJunkButton:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMLEFT", 162, 33);
	end
end);

addon.CachedItemIndices = {};

local function GetCachedIndex(index)
	return addon.CachedItemIndices[index] or 0;
end

hooksecurefunc("MerchantFrame_UpdateAltCurrency", function(index, indexOnPage, canAfford)
	local itemCount = GetMerchantItemCostInfo(index);
	if itemCount <= 0 then
		return;
	end

	local frameName = "MerchantItem" .. indexOnPage .. "AltCurrencyFrame";
	local usedCurrencies = 0;
	for i = 1, MAX_ITEM_COST do
		local itemTexture = GetMerchantItemCostItem(index, i);
		if itemTexture then
			usedCurrencies = usedCurrencies + 1;
			local button = _G[frameName.."Item"..usedCurrencies];
			button.index = GetCachedIndex(index);
		end
	end
end);

local origGetMerchantItemInfo = GetMerchantItemInfo;
GetMerchantItemInfo = function(index)
	return origGetMerchantItemInfo(GetCachedIndex(index));
end

local origCanAffordMerchantItem = CanAffordMerchantItem;
CanAffordMerchantItem = function(index)
	return origCanAffordMerchantItem(GetCachedIndex(index));
end

local origGetMerchantItemLink = GetMerchantItemLink;
GetMerchantItemLink = function(index)
	return origGetMerchantItemLink(GetCachedIndex(index));
end

local origGetMerchantItemID = GetMerchantItemID;
GetMerchantItemID = function(index)
	return origGetMerchantItemID(GetCachedIndex(index));
end

local origGetMerchantItemCostInfo = GetMerchantItemCostInfo;
GetMerchantItemCostInfo = function(index)
	return origGetMerchantItemCostInfo(GetCachedIndex(index));
end

local origGetMerchantItemCostItem = GetMerchantItemCostItem;
GetMerchantItemCostItem = function(index, itemIndex)
	return origGetMerchantItemCostItem(GetCachedIndex(index), itemIndex);
end

local origGetMerchantNumItems = GetMerchantNumItems;
GetMerchantNumItems = function()
	wipe(addon.CachedItemIndices);

	local lootFilter = GetMerchantFilter();
	local numMerchantItems = origGetMerchantNumItems();
	for i = 1, numMerchantItems, 1 do
		local itemId = origGetMerchantItemID(i);
		if itemId == nil or addon.Filters:Validate(lootFilter, itemId) then
			tinsert(addon.CachedItemIndices, i);
		end
	end
	return #addon.CachedItemIndices;
end

local origBuyMerchantItem = BuyMerchantItem;
BuyMerchantItem = function(index, quantity)
	origBuyMerchantItem(GetCachedIndex(index), quantity);
end

local origPickupMerchantItem = PickupMerchantItem;
PickupMerchantItem = function(index)
	if index == 0 then
		origPickupMerchantItem(0);
		return;
	end
	origPickupMerchantItem(GetCachedIndex(index));
end

local origGetMerchantItemMaxStack = GetMerchantItemMaxStack;
GetMerchantItemMaxStack = function(index)
	return origGetMerchantItemMaxStack(GetCachedIndex(index));
end

local origMerchantFrame_GetProductInfo = MerchantFrame_GetProductInfo;
function MerchantFrame_GetProductInfo(itemButton)
	local productInfo, specs = origMerchantFrame_GetProductInfo(itemButton);
	productInfo.index = addon.CachedItemIndices[itemButton:GetID()];
	return productInfo, specs;
end

StaticPopupDialogs["CONFIRM_PURCHASE_TOKEN_ITEM"].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count);
end

StaticPopupDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count);
end

StaticPopupDialogs["CONFIRM_PURCHASE_ITEM_DELAYED"].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count);
end

StaticPopupDialogs["CONFIRM_HIGH_COST_ITEM"].OnAccept = function()
	BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count);
end

-- 11.0.5 API changes
local origC_MerchantFrame_GetItemInfo = C_MerchantFrame.GetItemInfo;
C_MerchantFrame.GetItemInfo = function(index)
	return origC_MerchantFrame_GetItemInfo(GetCachedIndex(index));
end
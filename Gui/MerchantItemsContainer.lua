-- [[ Namespaces ]] --
local _, addon = ...;
addon.Gui.MerchantItemsContainer = {};
local merchantItemsContainer = addon.Gui.MerchantItemsContainer;

merchantItemsContainer.FirstOffsetX = 11;
merchantItemsContainer.FirstOffsetY = -69;
merchantItemsContainer.OffsetX = 12;
merchantItemsContainer.OffsetMerchantInfoY = 8;
merchantItemsContainer.OffsetBuybackInfoY = 15;
merchantItemsContainer.DefaultMerchantInfoNumRows = 5;
merchantItemsContainer.DefaultMerchantInfoNumColumns = 2;
merchantItemsContainer.DefaultBuybackInfoNumRows = 6;
merchantItemsContainer.DefaultBuybackInfoNumColumns = 2;
merchantItemsContainer.ItemWidth, merchantItemsContainer.ItemHeight = MerchantItem1:GetSize();

-- Choosing to overwrite this function as not to mess with the GameTooltip's SetMerchantItem
local function ItemSlotOnEnter(frame)
	GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
	if MerchantFrame.selectedTab == 1 then
		GameTooltip:SetMerchantItem(addon.CachedItemIndices[frame:GetID()]);
		GameTooltip_ShowCompareItem(GameTooltip);
		MerchantFrame.itemHover = frame:GetID();
	else
		GameTooltip:SetBuybackItem(frame:GetID());
		if IsModifiedClick("DRESSUP") and frame.hasItem then
			ShowInspectCursor();
		else
			ShowBuybackSellCursor(frame:GetID());
		end
	end
end

local function SetOnEnter(frame)
    frame:SetScript("OnEnter", ItemSlotOnEnter);
    frame.UpdateTooltip = ItemSlotOnEnter;
end

local shoppinglist = {};

local function SetOnClick(frame)
    frame:HookScript("OnClick", function(self, button)
        if not IsModifiedClick("ALT") then
            return;
        end

        for i = 1, MAX_ITEM_COST do
            local itemTexture, itemValue, itemLink = GetMerchantItemCostItem(self:GetID(), i);
            if itemTexture then
                print(itemTexture, itemValue, itemLink)
                shoppinglist[tostring(itemLink)] = shoppinglist[tostring(itemLink)] and shoppinglist[tostring(itemLink)] + itemValue or itemValue;
            end
        end

        print("Shoppinglist content:")
        for key, value in pairs(shoppinglist) do
            print(key, value);
        end
    end);
end

local infoNumRows, infoNumColumns = 0, 0;
local itemSlotTable = {};
for i = 1, 12, 1 do
    SetOnEnter(_G["MerchantItem" .. i].ItemButton);
    SetOnClick(_G["MerchantItem" .. i].ItemButton);
	tinsert(itemSlotTable, _G["MerchantItem" .. i]);
end

function merchantItemsContainer:HideAll()
    for _, itemSlot in next, itemSlotTable do
		itemSlot:Hide();
	end
end

local function GetItemSlot(index)
	if itemSlotTable[index] then
		return itemSlotTable[index];
	end
	local frame = CreateFrame("Frame", "MerchantItem" .. index, MerchantFrame, "MerchantItemTemplate");
    SetOnEnter(frame.ItemButton);
    SetOnClick(frame.ItemButton);
	itemSlotTable[index] = frame;
	return frame;
end

function merchantItemsContainer:LoadMaxNumItemSlots()
    local maxNumRows = math.max(addon.Options.db.profile.NumRows, self.DefaultBuybackInfoNumRows);
    local maxNumColumns = math.max(addon.Options.db.profile.NumColumns, self.DefaultBuybackInfoNumColumns);
    local maxNumItems = maxNumRows * maxNumColumns;
    if #itemSlotTable < maxNumItems then
        for i = 1, maxNumItems, 1 do
            local itemSlot = GetItemSlot(i);
            itemSlot:Hide();
        end
    end
    MERCHANT_ITEMS_PER_PAGE = addon.Options.db.profile.NumRows * addon.Options.db.profile.NumColumns;
end

function merchantItemsContainer:PrepareMerchantInfo()
    infoNumRows, infoNumColumns = addon.Options.db.profile.NumRows, addon.Options.db.profile.NumColumns;
end

function merchantItemsContainer:PrepareBuybackInfo()
    infoNumRows, infoNumColumns = self.DefaultBuybackInfoNumRows, self.DefaultBuybackInfoNumColumns;
end

function merchantItemsContainer:PrepareInfo()
    if MerchantFrame.selectedTab == 1 then
		self:PrepareMerchantInfo();
	else
		self:PrepareBuybackInfo();
	end
end

hooksecurefunc("MerchantFrame_UpdateFilterString", function()
	merchantItemsContainer:PrepareInfo();
end);

function merchantItemsContainer:DrawItemSlot(index, row, column, offsetX, offsetY)
    local itemSlot = GetItemSlot(index);
    local calculatedOffsetX = self.FirstOffsetX + (column - 1) * (offsetX + self.ItemWidth);
    local calculatedOffsetY = self.FirstOffsetY - (row - 1) * (offsetY + self.ItemHeight);
    itemSlot:ClearAllPoints();
    itemSlot:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", calculatedOffsetX, calculatedOffsetY);
    itemSlot:Show();
end

function merchantItemsContainer:DrawItemSlots(numRows, numColumns, offsetX, offsetY)
    if addon.Options.db.profile.Direction == addon.L["Columns first"] then
        for row = 1, numRows, 1 do
            for column = 1, numColumns, 1 do
                local index = (column - 1) * numRows + row;
                self:DrawItemSlot(index, row, column, offsetX, offsetY);
            end
        end
    else
        for column = 1, numColumns, 1 do
            for row = 1, numRows, 1 do
                local index = (row - 1) * numColumns + column;
                self:DrawItemSlot(index, row, column, offsetX, offsetY);
            end
        end
    end
end

function merchantItemsContainer:HideRemainingItemSlots(startIndex)
    local numItemSlots = #itemSlotTable;
    for i = startIndex, numItemSlots, 1 do
        itemSlotTable[i]:Hide();
    end
end

function merchantItemsContainer:DrawMerchantBuyBackItem(show)
    if show then
        MerchantBuyBackItem:ClearAllPoints();
        MerchantBuyBackItem:SetPoint("BOTTOMLEFT", MerchantFrameBottomLeftBorder, "BOTTOMLEFT", 205, 7);
	    MerchantBuyBackItem:Show();
    else
        MerchantBuyBackItem:Hide();
    end
end

function merchantItemsContainer:DrawForMerchantInfo()
	self:DrawItemSlots(infoNumRows, infoNumColumns, self.OffsetX, self.OffsetMerchantInfoY);
    self:HideRemainingItemSlots(infoNumRows * infoNumColumns + 1);
	self:DrawMerchantBuyBackItem(true);
end
hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
    merchantItemsContainer:DrawForMerchantInfo();
end);

function merchantItemsContainer:DrawForBuybackInfo()
	self:DrawItemSlots(infoNumRows, infoNumColumns, self.OffsetX, self.OffsetBuybackInfoY);
    self:HideRemainingItemSlots(infoNumRows * infoNumColumns + 1);
	self:DrawMerchantBuyBackItem(false);
end
hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
    merchantItemsContainer:DrawForBuybackInfo();
end);
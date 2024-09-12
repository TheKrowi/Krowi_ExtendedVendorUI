local _, addon = ...;
local plugins = addon.Plugins;
plugins.BuyEmAll = {};
local buyEmAll = plugins.BuyEmAll;

local MerchantItemsContainer = addon.Gui.MerchantItemsContainer;
tinsert(plugins.Plugins, buyEmAll);

local function MoveFrameToBuyEmAllFrame(frame)
  frame:SetParent(BuyEmAllFrame);
  local point, _, relativePoint, offsetX, offsetY = frame:GetPoint();
  frame:SetPoint(point, BuyEmAllFrame, relativePoint, offsetX, offsetY);
end

local function ModifyBuyEmAllFrame()
  BuyEmAllFrameBottomLeftBorder:SetSize(256, 61);
	BuyEmAllFrameBottomLeftBorder:SetTexture("Interface/MerchantFrame/Merchant");
	BuyEmAllFrameBottomLeftBorder:SetTexCoord(0.001953125, 0.5, 0.00390625, 0.2421875);
	BuyEmAllFrameBottomLeftBorder:SetPoint("BOTTOMLEFT", BuyEmAllFrame, "BOTTOMLEFT", 1, 26);

	local bottomExtensionRightBorder = BuyEmAllFrame:CreateTexture("KrowiEVU_BuyEmAll_BottomExtensionRightBorder");
	bottomExtensionRightBorder:SetSize(78, 61);
	bottomExtensionRightBorder:SetTexture("Interface/MerchantFrame/Merchant");
	bottomExtensionRightBorder:SetTexCoord(0.5, 0.650390625, 0.00390625, 0.2421875);
	bottomExtensionRightBorder:SetPoint("BOTTOMRIGHT", BuyEmAllFrame, "BOTTOMRIGHT", -1, 26);

	local bottomExtensionLeftBorder = BuyEmAllFrame:CreateTexture("KrowiEVU_BuyEmAll_BottomExtensionLeftBorder");
	bottomExtensionLeftBorder:SetSize(78, 61);
	bottomExtensionLeftBorder:SetTexture("Interface/MerchantFrame/Merchant");
	bottomExtensionLeftBorder:SetTexCoord(0.240234375, 0.390625, 0.00390625, 0.2421875);
	bottomExtensionLeftBorder:SetPoint("TOPLEFT", BuyEmAllFrameBottomLeftBorder, "TOPRIGHT", 0, 0);

	local bottomExtensionMidBorder = BuyEmAllFrame:CreateTexture("KrowiEVU_BuyEmAll_BottomExtensionMidBorder");
	bottomExtensionMidBorder:SetTexture("Interface/MerchantFrame/Merchant");
	bottomExtensionMidBorder:SetTexCoord(0.01953125, 0.373046875, 0.00390625, 0.2421875);
	bottomExtensionMidBorder:SetPoint("TOPLEFT", bottomExtensionLeftBorder, "TOPRIGHT", 0, 0);
	bottomExtensionMidBorder:SetPoint("BOTTOMRIGHT", bottomExtensionRightBorder, "BOTTOMLEFT", 0, 0);

	BuyEmAllPrevPageButton:SetPoint("BOTTOMLEFT", BuyEmAllFrameBottomLeftBorder, "TOPLEFT", 8, -5);
	BuyEmAllNextPageButton:SetPoint("BOTTOMRIGHT", KrowiEVU_BuyEmAll_BottomExtensionRightBorder, "TOPRIGHT", -7, -5);

  BuyEmAllFrame.FilterDropdown:Hide();

	BuyEmAllMoneyInset:SetPoint("TOPLEFT", BuyEmAllFrame, "BOTTOMRIGHT", -169, 27);
	BuyEmAllExtraCurrencyInset:ClearAllPoints();
	BuyEmAllExtraCurrencyInset:SetPoint("BOTTOMRIGHT", -167, 4);
	BuyEmAllExtraCurrencyInset:SetPoint("TOPLEFT", BuyEmAllFrame, "BOTTOMRIGHT", -332, 27);
	BuyEmAllExtraCurrencyBg:ClearAllPoints();
	BuyEmAllExtraCurrencyBg:SetPoint("TOPRIGHT", BuyEmAllExtraCurrencyInset, -3, -2);
	BuyEmAllExtraCurrencyBg:SetPoint("BOTTOMLEFT", BuyEmAllExtraCurrencyInset, 3, 2);
end

local itemSlotTable = {};

local function GetItemSlot(index)
  if itemSlotTable[index] then
    return itemSlotTable[index];
  end
  local frame = CreateFrame("Frame", "BuyEmAllItem" .. index, BuyEmAllFrame, "MerchantItemTemplate");
  MerchantItemsContainer:SetOnEnter(frame.ItemButton);
  itemSlotTable[index] = frame;
  return frame;
end

function buyEmAll.AfterLoad()
  for i = 1, 12, 1 do
    MerchantItemsContainer:SetOnEnter(_G["BuyEmAllItem" .. i].ItemButton);
    tinsert(itemSlotTable, _G["BuyEmAllItem" .. i]);
  end

  ModifyBuyEmAllFrame();
  MoveFrameToBuyEmAllFrame(KrowiEVU_OptionsButton);
  MoveFrameToBuyEmAllFrame(KrowiEVU_FilterButton);
  MoveFrameToBuyEmAllFrame(KrowiEVU_SearchBox);

  hooksecurefunc('BuyEmAllFrame_UpdateMerchantInfo', function()
    BuyEmAllFrame:SetSize(MerchantFrame:GetSize())
    if(KrowiEVU_BottomExtensionLeftBorder:IsShown()) then
      KrowiEVU_BuyEmAll_BottomExtensionLeftBorder:Show()
    else
      KrowiEVU_BuyEmAll_BottomExtensionLeftBorder:Hide()
    end

    if(KrowiEVU_BottomExtensionMidBorder:IsShown()) then
      KrowiEVU_BuyEmAll_BottomExtensionMidBorder:Show()
    else
      KrowiEVU_BuyEmAll_BottomExtensionMidBorder:Hide()
    end

    KrowiEVU_BuyEmAll_BottomExtensionRightBorder:Show();
  end)

  hooksecurefunc('BuyEmAllFrame_UpdateBuybackInfo', function()
    BuyEmAllFrame:SetSize(MerchantFrame:GetSize())
    KrowiEVU_BuyEmAll_BottomExtensionLeftBorder:Hide();
    KrowiEVU_BuyEmAll_BottomExtensionMidBorder:Hide();
    KrowiEVU_BuyEmAll_BottomExtensionRightBorder:Hide();
  end)

  hooksecurefunc("BuyEmAllFrame_UpdateRepairButtons", function()
    if not CanMerchantRepair() then
      local point, _, relativePoint, offsetX, offsetY = MerchantSellAllJunkButton:GetPoint();
      BuyEmAllSellAllJunkButton:SetPoint(point, BuyEmAllFrame, relativePoint, offsetX, offsetY);
    end
  end);

  hooksecurefunc("BuyEmAllFrame_UpdateMerchantInfo", function()
    MerchantItemsContainer:DrawForMerchantInfo();
  end);

  hooksecurefunc(MerchantItemsContainer, 'GetItemSlot', function(_, index)
    GetItemSlot(index);
  end)

  hooksecurefunc(MerchantItemsContainer, 'DrawMerchantBuyBackItem', function(_, show)
    if show then
      local point, _, relativePoint, offsetX, offsetY = MerchantBuyBackItem:GetPoint();
      BuyEmAllBuyBackItem:ClearAllPoints();
      BuyEmAllBuyBackItem:SetPoint(point, BuyEmAllFrameBottomLeftBorder, relativePoint, offsetX, offsetY);
      BuyEmAllBuyBackItem:Show();
    else
      BuyEmAllBuyBackItem:Hide();
    end
  end)

  hooksecurefunc(MerchantItemsContainer, 'DrawItemSlots', function()
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
      local itemSlot = GetItemSlot(i);
      local originalItemSlot = MerchantItemsContainer:GetItemSlot(i);
      local point, relativeTo, relativePoint, offsetX, offsetY = originalItemSlot:GetPoint();

      print(itemSlot:GetName(), itemSlot:GetPoint())
      print(originalItemSlot:GetName(), originalItemSlot:GetPoint())
      print(point, relativePoint, offsetX, offsetY);

      itemSlot:ClearAllPoints();
      itemSlot:SetPoint(point, BuyEmAllFrame, relativePoint, offsetX, offsetY);
      itemSlot:Show();
    end
  end)

  hooksecurefunc(MerchantItemsContainer, 'HideRemainingItemSlots', function(_, startIndex)
    local numItemSlots = #itemSlotTable;
    for i = startIndex, numItemSlots, 1 do
        itemSlotTable[i]:Hide();
    end
  end)

  hooksecurefunc(BuyEmAllFrame.FilterDropdown, "Update", function()
    MerchantItemsContainer:PrepareInfo();
  end);
end

function buyEmAll.OnAddonLoaded() 
  local addonEnabled, addonLoaded = C_AddOns.IsAddOnLoaded('BuyEmAll');
  if(not addonEnabled) then return end
  if(not addonLoaded) then
    local loadFrame = CreateFrame('Frame');
    loadFrame:RegisterEvent('ADDON_LOADED');
    function loadFrame:OnEvent(_, addonName)
      if(addonName == 'BuyEmAll') then buyEmAll.AfterLoad() end
    end
    loadFrame:SetScript('OnEvent', loadFrame.OnEvent);
  else
    buyEmAll.AfterLoad();
  end
end
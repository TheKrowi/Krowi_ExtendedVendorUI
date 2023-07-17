-- [[ Namespaces ]] --
local _, addon = ...;
addon.GUI.MerchantFrame = {};
local merchantFrame = addon.GUI.MerchantFrame;
local merchantItemsContainer = addon.GUI.MerchantItemsContainer;

local originalWidth, originalHeight = MerchantFrame:GetSize();

do -- [[ Set some permanent MerchantFrame changes ]]
	-- MerchantFrameBottomRightBorder:SetTexCoord(91 / 256, (91 + 76) / 256, 0, 0.4765625);

	local bottomExtensionRightBorder = MerchantFrame:CreateTexture("KrowiMFE_BottomExtensionRightBorder");
	bottomExtensionRightBorder:SetSize(76, 61);
	bottomExtensionRightBorder:SetTexture("Interface/MerchantFrame/UI-Merchant-BottomBorder");
	bottomExtensionRightBorder:SetTexCoord(0, 0.296875, 0.4765625, 0.953125);
	bottomExtensionRightBorder:SetPoint("BOTTOMRIGHT", MerchantFrameInset, "BOTTOMRIGHT", 3, 0);

	local bottomExtensionLeftBorder = MerchantFrame:CreateTexture("KrowiMFE_BottomExtensionLeftBorder");
	bottomExtensionLeftBorder:SetSize(89, 61);
	bottomExtensionLeftBorder:SetTexture("Interface/MerchantFrame/UI-Merchant-BottomBorder");
	bottomExtensionLeftBorder:SetTexCoord((91 + 76) / 256, 1, 0, 0.4765625);
	bottomExtensionLeftBorder:SetPoint("TOPLEFT", MerchantFrameBottomLeftBorder, "TOPRIGHT", 0, 0);

	local bottomExtensionMidBorder = MerchantFrame:CreateTexture("KrowiMFE_BottomExtensionMidBorder");
	bottomExtensionMidBorder:SetTexture("Interface/MerchantFrame/UI-Merchant-BottomBorder");
	bottomExtensionMidBorder:SetTexCoord(8 / 256, (8 + 151) / 256, 0, 0.4765625);
	bottomExtensionMidBorder:SetPoint("TOPLEFT", bottomExtensionLeftBorder, "TOPRIGHT", 0, 0);
	bottomExtensionMidBorder:SetPoint("BOTTOMRIGHT", bottomExtensionRightBorder, "BOTTOMLEFT", 0, 0);

	MerchantPrevPageButton:SetPoint("BOTTOMLEFT", MerchantFrameBottomLeftBorder, "TOPLEFT", 8, -5);
	MerchantNextPageButton:SetPoint("BOTTOMRIGHT", KrowiMFE_BottomExtensionRightBorder, "TOPRIGHT", -7, -5);
end

function merchantFrame:Load()
	merchantItemsContainer:LoadMaxNumItemSlots();
end

hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
	-- KrowiV_EmbeddedJunkListFrame:Hide();
	-- KrowiV_EmbeddedIgnoreListFrame:Hide();
	local numColumns = addon.Options.db.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns;
	local numRows = addon.Options.db.NumRows - merchantItemsContainer.DefaultMerchantInfoNumRows;
	local itemWidth = merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth;
	local itemHeight = merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight;

	local width = originalWidth + numColumns * itemWidth;
	local height = originalHeight + numRows * itemHeight;
	if not MerchantPageText:IsShown() then
		height = height - 36;
	end
	MerchantFrame:SetSize(width, height);
	KrowiMFE_BottomExtensionRightBorder:Show();
	if numColumns > 0 then
		KrowiMFE_BottomExtensionLeftBorder:Show();
		KrowiMFE_BottomExtensionMidBorder:Show();
	else
		MerchantFrameBottomLeftBorder:Hide();
		KrowiMFE_BottomExtensionLeftBorder:Hide();
		KrowiMFE_BottomExtensionMidBorder:Hide();
	end
	UndoFrame:Show();
end);

hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
	-- KrowiV_EmbeddedJunkListFrame:Hide();
	-- KrowiV_EmbeddedIgnoreListFrame:Hide();
	MerchantFrame:SetSize(originalWidth, originalHeight);
	KrowiMFE_BottomExtensionRightBorder:Hide();
	KrowiMFE_BottomExtensionLeftBorder:Hide();
	KrowiMFE_BottomExtensionMidBorder:Hide();
end);

-- Hook onto MerchantFrame_UpdateFilterString so we're ready for MerchantFrame_UpdateMerchantInfo and/or MerchantFrame_UpdateBuybackInfo
hooksecurefunc("MerchantFrame_UpdateFilterString", function()
	if MerchantFrame.selectedTab == 1 then
		merchantItemsContainer:PrepareMerchantInfo();
	else
		merchantItemsContainer:PrepareBuybackInfo();
	end
end);

hooksecurefunc(MerchantFrame, "Show", function(self)
	SetMerchantFilter(LE_LOOT_FILTER_ALL);

	-- KrowiV_AutoSellListFrame:ShowWithMerchantFrame();
end);

function KrowiV_ShowIgnoreList_OnLoad(self)
	self:SetText(addon.L["Ignore List"]);
	PanelTemplates_SetNumTabs(MerchantFrame, MerchantFrame.numTabs + 1);
end

function KrowiV_ShowJunkList_OnLoad(self)
	self:SetText(addon.L["Junk List"]);
	PanelTemplates_SetNumTabs(MerchantFrame, MerchantFrame.numTabs + 1);
end

function MerchantFrame_Update()
	if MerchantFrame.lastTab ~= MerchantFrame.selectedTab then
		MerchantFrame_CloseStackSplitFrame();
		MerchantFrame.lastTab = MerchantFrame.selectedTab;
	end
	MerchantFrame_UpdateFilterString()
	if MerchantFrame.selectedTab == 1 then
		MerchantFrame_UpdateMerchantInfo();
	-- elseif MerchantFrame.selectedTab == 3 then
	-- 	merchantFrame.UpdateIgnoreInfo();
	-- elseif MerchantFrame.selectedTab == 4 then
	-- 	merchantFrame.UpdateJunkInfo();
	else
		MerchantFrame_UpdateBuybackInfo();
	end
end

-- function merchantFrame.UpdateIgnoreInfo()
-- 	merchantItemsContainer:HideAll();
-- 	-- MerchantFrameBottomRightBorder:Hide();
-- 	KrowiMFE_BottomExtensionRightBorder:Hide();
-- 	KrowiMFE_BottomExtensionLeftBorder:Hide();
-- 	KrowiMFE_BottomExtensionMidBorder:Hide();
-- 	MerchantRepairAllButton:Hide();
-- 	MerchantRepairItemButton:Hide();
-- 	MerchantBuyBackItem:Hide();
-- 	MerchantPrevPageButton:Hide();
-- 	MerchantNextPageButton:Hide();
-- 	MerchantFrameBottomLeftBorder:Hide();
-- 	-- MerchantFrameBottomRightBorder:Hide();
-- 	-- MerchantRepairText:Hide();
-- 	UndoFrame:Hide();
-- 	MerchantPageText:Hide();
-- 	MerchantGuildBankRepairButton:Hide();
-- 	MerchantFrame:SetWidth(610);
-- 	KrowiV_EmbeddedJunkListFrame:Hide();
-- 	KrowiV_EmbeddedIgnoreListFrame:ShowWithMerchantFrame();
-- end

-- function merchantFrame.UpdateJunkInfo()
-- 	merchantItemsContainer:HideAll();
-- 	-- MerchantFrameBottomRightBorder:Hide();
-- 	KrowiMFE_BottomExtensionRightBorder:Hide();
-- 	KrowiMFE_BottomExtensionLeftBorder:Hide();
-- 	KrowiMFE_BottomExtensionMidBorder:Hide();
-- 	MerchantRepairAllButton:Hide();
-- 	MerchantRepairItemButton:Hide();
-- 	MerchantBuyBackItem:Hide();
-- 	MerchantPrevPageButton:Hide();
-- 	MerchantNextPageButton:Hide();
-- 	MerchantFrameBottomLeftBorder:Hide();
-- 	-- MerchantFrameBottomRightBorder:Hide();
-- 	-- MerchantRepairText:Hide();
-- 	UndoFrame:Hide();
-- 	MerchantPageText:Hide();
-- 	MerchantGuildBankRepairButton:Hide();
-- 	MerchantFrame:SetWidth(610);
-- 	KrowiV_EmbeddedIgnoreListFrame:Hide();
-- 	KrowiV_EmbeddedJunkListFrame:ShowWithMerchantFrame(true);
-- end
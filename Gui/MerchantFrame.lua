local _, addon = ...
if addon.NotLoaded then return end
local merchantItemsContainer = addon.Gui.MerchantItemsContainer
local originalWidth, originalHeight = MerchantFrame:GetSize()
originalHeight = originalHeight + 12
originalWidth = originalWidth + 12

addon.Gui.MerchantFrame = {}
local merchantFrame = addon.Gui.MerchantFrame

do
	MerchantMoneyInset:ClearAllPoints()
	MerchantMoneyInset:SetPoint('BOTTOMRIGHT', MerchantFrame, -6, 8)
	MerchantMoneyInset:SetPoint('LEFT', MerchantFrame, 4, 0)
	MerchantMoneyInset:SetHeight(22)

	local buttonsInset = CreateFrame('Frame', 'KrowiEVU_MerchantButtonsInset', MerchantFrame, 'InsetFrameTemplate')
	buttonsInset:SetPoint('BOTTOMLEFT', MerchantMoneyInset, 'TOPLEFT', 0, 4)
	buttonsInset:SetSize(185, 52)
	local buybackInset = CreateFrame('Frame', 'KrowiEVU_MerchantBuybackInset', MerchantFrame, 'InsetFrameTemplate')
	buybackInset:SetPoint('TOPLEFT', buttonsInset, 'TOPRIGHT', 4, 0)
	buybackInset:SetPoint('BOTTOMLEFT', buttonsInset, 'BOTTOMRIGHT', 4, 0)
	buybackInset:SetWidth(149)
	local emptyInset = CreateFrame('Frame', 'KrowiEVU_MerchantEmptyInset', MerchantFrame, 'InsetFrameTemplate')
	emptyInset:SetPoint('TOPLEFT', buybackInset, 'TOPRIGHT', 4, 0)
	emptyInset:SetPoint('BOTTOMLEFT', buybackInset, 'BOTTOMRIGHT', 4, 0)
	emptyInset:SetPoint('RIGHT', MerchantMoneyInset)

	local function UpdateRepairButtons()
		MerchantRepairItemButton:ClearAllPoints()
		MerchantRepairItemButton:SetPoint('RIGHT', MerchantRepairAllButton, 'LEFT', -8, 0)
		MerchantRepairAllButton:ClearAllPoints()
		MerchantRepairAllButton:SetPoint('LEFT', buttonsInset, 52, -1) -- Start with this to not trigger Default Blizzard errors
		MerchantGuildBankRepairButton:ClearAllPoints()
		MerchantGuildBankRepairButton:SetPoint('LEFT', MerchantRepairAllButton, 'RIGHT', 8, 0)
		if addon.Util.IsModern then
			MerchantSellAllJunkButton:ClearAllPoints()
			MerchantSellAllJunkButton:SetPoint('LEFT', MerchantGuildBankRepairButton, 'RIGHT', 8, 0)
		else
			MerchantRepairText:Hide()
		end
	end
	merchantFrame.UpdateRepairButtons = UpdateRepairButtons -- Makes placing them correctly possible via plugins like ElvUI
	hooksecurefunc('MerchantFrame_UpdateRepairButtons', UpdateRepairButtons)

	MerchantFrameInset:ClearPoint('BOTTOMRIGHT')
	MerchantFrameInset:SetPoint('RIGHT', MerchantFrame, 'RIGHT', -6, 0)
	MerchantFrameInset:SetPoint('BOTTOM', buttonsInset, 'TOP', 0, 4)

	KrowiEVU_MerchantPrevPageButton:ClearAllPoints()
	KrowiEVU_MerchantPrevPageButton:SetPoint('BOTTOMLEFT', MerchantFrameInset, 5, 2)
	KrowiEVU_MerchantNextPageButton:ClearAllPoints()
	KrowiEVU_MerchantNextPageButton:SetPoint('BOTTOMRIGHT', MerchantFrameInset, -3, 2)
	KrowiEVU_MerchantPageText:SetPoint('CENTER', MerchantFrameInset)
	KrowiEVU_MerchantPageText:SetPoint('BOTTOM', buttonsInset, 'TOP', 0, 17)

	BuybackBG:SetPoint('TOPLEFT', MerchantFrameInset)
	BuybackBG:SetPoint('BOTTOMRIGHT', MerchantFrameInset)

	if not addon.Util.IsModern then
		MerchantFrameBtnCornerLeft:Hide()
		MerchantFrameBtnCornerRight:Hide()

		MerchantBuyBackItemNameFrame:SetWidth(112)
		MerchantBuyBackItemNameFrame:SetPoint('LEFT', MerchantBuyBackItemSlotTexture, 'RIGHT', -9, -11)
	end
end

function merchantFrame.SetMerchantFrameSize()
	if MerchantFrame.selectedTab == 1 then
		local numExtraColumns = addon.Options.db.profile.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns
		local numExtraRows = addon.Options.db.profile.NumRows - merchantItemsContainer.DefaultMerchantInfoNumRows
		local itemWidth = merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth
		local itemHeight = merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight
		local width = originalWidth + numExtraColumns * itemWidth
		local height = originalHeight + numExtraRows * itemHeight + MerchantMoneyInset:GetHeight() - 23
		if not addon.Gui.Paging:IsShown() then
			height = height - 36
		end
		MerchantFrame:SetSize(width, height)
	elseif MerchantFrame.selectedTab == 2 then
		MerchantFrame:SetSize(originalWidth, originalHeight)
	end
end

function merchantFrame.UpdateMerchantInfoLayout()
	merchantFrame.SetMerchantFrameSize()
	if addon.Util.IsModern then
		MerchantFrame.FilterDropdown:Hide()
	end
	KrowiEVU_FilterButton:Show()
	KrowiEVU_SearchBox:Show()
	KrowiEVU_OptionsButton:ShowHide()
	local numExtraColumns = addon.Options.db.profile.NumColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns
	if numExtraColumns > 0 then
		addon.Gui.OptionsButton:ResetPointOffset()
		addon.Gui.SearchBox:ResetPointOffset()
		KrowiEVU_SearchBox:SetWidth(144)
		KrowiEVU_MerchantEmptyInset:Show()
	else
		addon.Gui.OptionsButton:SetPointOffset(-7)
		addon.Gui.SearchBox:SetPointOffset(-2)
		KrowiEVU_SearchBox:SetWidth(90)
		KrowiEVU_MerchantEmptyInset:Hide()
	end
	MerchantFrameInset:SetPoint('BOTTOM', KrowiEVU_MerchantButtonsInset, 'TOP', 0, 4)
	KrowiEVU_MerchantButtonsInset:Show()
	KrowiEVU_MerchantBuybackInset:Show()
	if not addon.Util.IsModern then
		MerchantFrameBottomRightBorder:Hide()
	end
	if MerchantToken4 then
		MerchantToken4:ClearAllPoints()
		MerchantToken4:SetPoint('BOTTOMRIGHT', -185, 8)
	end
	MerchantFrameBottomLeftBorder:Hide()
end
hooksecurefunc('MerchantFrame_UpdateMerchantInfo', merchantFrame.UpdateMerchantInfoLayout)

hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function()
	merchantFrame.SetMerchantFrameSize()
	if addon.Util.IsModern then
		MerchantFrame.FilterDropdown:Hide()
	end
	KrowiEVU_OptionsButton:Hide()
	KrowiEVU_SearchBox:Hide()
	KrowiEVU_FilterButton:Hide()
	MerchantFrameInset:SetPoint('BOTTOM', MerchantMoneyInset, 'TOP', 0, 3)
	KrowiEVU_MerchantButtonsInset:Hide()
	KrowiEVU_MerchantBuybackInset:Hide()
	KrowiEVU_MerchantEmptyInset:Hide()
end)
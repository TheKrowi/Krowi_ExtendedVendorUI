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

	-- With nothing to repair Blizzard disables both repair-all buttons, and they say nothing: a disabled button runs no OnEnter,
	-- and theirs only fill the tooltip when there is a cost (live MerchantFrame.xml:240-252 and 338-371, TBC 215-222). So they
	-- run their mouse scripts while disabled too, and then say what they do (#32). Blizzard's OnLeave hides the tooltip again.
	local function AddDisabledTooltip(button, title)
		button:SetMotionScriptsWhileDisabled(true)
		button:HookScript('OnEnter', function(self)
			if self:IsEnabled() then
				return
			end
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
			GameTooltip:SetText(title)
			GameTooltip:AddLine(addon.L['Nothing to repair'], 1, 1, 1)
			GameTooltip:Show()
		end)
	end
	AddDisabledTooltip(MerchantRepairAllButton, REPAIR_ALL_ITEMS)
	AddDisabledTooltip(MerchantGuildBankRepairButton, addon.L['Repair all items with guild money'])

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

-- One column and one row of the merchant tab's grid, in the window's size
function merchantFrame.GetGridStep()
	return merchantItemsContainer.OffsetX + merchantItemsContainer.ItemWidth, merchantItemsContainer.OffsetMerchantInfoY + merchantItemsContainer.ItemHeight
end

-- The merchant tab's window size for a grid; withPaging false for the 36 px less while the page controls are hidden
function merchantFrame.GetMerchantInfoSize(numColumns, numRows, withPaging)
	local columnWidth, rowHeight = merchantFrame.GetGridStep()
	local width = originalWidth + (numColumns - merchantItemsContainer.DefaultMerchantInfoNumColumns) * columnWidth
	local height = originalHeight + (numRows - merchantItemsContainer.DefaultMerchantInfoNumRows) * rowHeight + MerchantMoneyInset:GetHeight() - 23
	if not withPaging then
		height = height - 36
	end
	return width, height
end

function merchantFrame.SetMerchantFrameSize()
	if MerchantFrame.selectedTab == 1 then
		local profile = addon.Options.db.profile
		MerchantFrame:SetSize(merchantFrame.GetMerchantInfoSize(profile.NumColumns, profile.NumRows, addon.Gui.Paging:IsShown()))
	elseif MerchantFrame.selectedTab == 2 then
		MerchantFrame:SetSize(originalWidth, originalHeight)
	end
end

-- [[ Grid size by dragging ]] --
-- The resize grip (#139, Gui/ResizeGrip.lua) and /kevutest size the grid here: the gear menu's limits (rows 1-99, columns
-- 2-99, OptionsButtonMixin.lua:153-156, 186) and no larger than fits between the window's top-left and the screen's
-- bottom-right, unless the grid already is (then it may only shrink). The window is anchored by its top-left, by the panel
-- manager and by a moved spot, so that corner stays put.
local MIN_ROWS, MIN_COLUMNS, MAX_GRID = 1, 2, 99
function merchantFrame.GetMaxGrid()
	local profile = addon.Options.db.profile
	local left, top = MerchantFrame:GetLeft(), MerchantFrame:GetTop()
	if not left or not top then
		return math.max(profile.NumColumns, MIN_COLUMNS), math.max(profile.NumRows, MIN_ROWS)
	end
	local ratio = UIParent:GetEffectiveScale() / MerchantFrame:GetEffectiveScale()
	local columnWidth, rowHeight = merchantFrame.GetGridStep()
	local baseWidth, baseHeight = merchantFrame.GetMerchantInfoSize(MIN_COLUMNS, MIN_ROWS, true)
	local maxColumns = MIN_COLUMNS + math.floor((UIParent:GetRight() * ratio - left - baseWidth) / columnWidth)
	local maxRows = MIN_ROWS + math.floor((top - baseHeight) / rowHeight)
	maxColumns = math.min(MAX_GRID, math.max(maxColumns, profile.NumColumns, MIN_COLUMNS))
	maxRows = math.min(MAX_GRID, math.max(maxRows, profile.NumRows, MIN_ROWS))
	return maxColumns, maxRows
end

function merchantFrame.ClampGrid(numColumns, numRows)
	local maxColumns, maxRows = merchantFrame.GetMaxGrid()
	return math.max(MIN_COLUMNS, math.min(numColumns, maxColumns)), math.max(MIN_ROWS, math.min(numRows, maxRows))
end

-- Writes the gear menu's Rows and Columns and redraws as the gear menu does; true when the grid changed
function merchantFrame.ResizeTo(numColumns, numRows)
	numColumns, numRows = merchantFrame.ClampGrid(numColumns, numRows)
	local profile = addon.Options.db.profile
	if profile.NumColumns == numColumns and profile.NumRows == numRows then
		return false
	end
	profile.NumColumns, profile.NumRows = numColumns, numRows
	addon.Gui.OptionsButton.UpdateView()
	return true
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
	KrowiEVU_MerchantResizeGrip:Show()
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
	KrowiEVU_MerchantResizeGrip:Hide() -- The Buyback tab keeps Blizzard's size
end)
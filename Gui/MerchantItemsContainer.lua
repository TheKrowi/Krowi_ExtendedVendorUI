-- [[ Namespaces ]] --
local _, addon = ...
addon.Gui.MerchantItemsContainer = {}
local merchantItemsContainer = addon.Gui.MerchantItemsContainer
local merchantItemSlot = addon.Gui.MerchantItemSlot
local paging = addon.Gui.Paging

merchantItemsContainer.FirstOffsetX = 11
merchantItemsContainer.FirstOffsetY = -69
merchantItemsContainer.OffsetX = 12
merchantItemsContainer.OffsetMerchantInfoY = 8
merchantItemsContainer.OffsetBuybackInfoY = 15
merchantItemsContainer.DefaultMerchantInfoNumRows = 5
merchantItemsContainer.DefaultMerchantInfoNumColumns = 2
merchantItemsContainer.DefaultBuybackInfoNumRows = 6
merchantItemsContainer.DefaultBuybackInfoNumColumns = 2
merchantItemsContainer.ItemWidth, merchantItemsContainer.ItemHeight = MerchantItem1:GetSize()

-- The merchant tab shows the addon's own item slots, KrowiEVU_MerchantItem<N>, with the vendor's real indices that pass the filter.
-- Blizzard's MerchantItem1-10 keep being filled by Blizzard's own code and are hidden there; the buyback tab uses Blizzard's MerchantItem1-12.
local indices = {}
local itemSlots = {}
local isOwnItemButton = {}

-- [[ Item slots ]] --
-- Blizzard's MerchantItemTemplate OnClick (live MerchantFrame.xml:43-49), with Bulk Purchase taking the modified clicks when it is on
local function ItemButton_OnClick(self, button)
    if IsModifiedClick() then
        if addon.Options.db and addon.Options.db.profile.BulkPurchase.Enabled then
            KrowiEVU_BulkPurchaseMixin:OnModifiedClick(self, button)
        else
            MerchantItemButton_OnModifiedClick(self, button)
        end
    else
        MerchantItemButton_OnClick(self, button)
    end
end

local function GetItemSlot(index)
    if itemSlots[index] then
        return itemSlots[index]
    end
    local itemSlot = CreateFrame('Frame', 'KrowiEVU_MerchantItem' .. index, MerchantFrame, 'MerchantItemTemplate')
    itemSlot:Hide()
    itemSlot.ItemButton:SetScript('OnClick', ItemButton_OnClick)
    isOwnItemButton[itemSlot.ItemButton] = true
    itemSlots[index] = itemSlot
    KrowiEVU.PluginsApi:CallPlugins('OnItemSlotCreated', itemSlot)
    return itemSlot
end

local function GetBlizzardItemSlot(index)
    return _G['MerchantItem' .. index]
end

function merchantItemsContainer:LoadMaxNumItemSlots()
    local maxNumItems = addon.Options.db.profile.NumRows * addon.Options.db.profile.NumColumns
    for i = 1, maxNumItems, 1 do
        GetItemSlot(i)
    end
end

function merchantItemsContainer:GetIndices()
    return indices
end

local function HideItemSlots()
    for _, itemSlot in next, itemSlots do
        itemSlot:Hide()
    end
end

function merchantItemsContainer:HideAll()
    HideItemSlots()
    paging:Hide()
    for i = 1, BUYBACK_ITEMS_PER_PAGE, 1 do
        GetBlizzardItemSlot(i):Hide()
    end
end

-- [[ Placement ]] --
local function PlaceItemSlot(itemSlot, row, column, offsetX, offsetY)
    local calculatedOffsetX = merchantItemsContainer.FirstOffsetX + (column - 1) * (offsetX + merchantItemsContainer.ItemWidth)
    local calculatedOffsetY = merchantItemsContainer.FirstOffsetY - (row - 1) * (offsetY + merchantItemsContainer.ItemHeight)
    itemSlot:ClearAllPoints()
    itemSlot:SetPoint('TOPLEFT', MerchantFrame, 'TOPLEFT', calculatedOffsetX, calculatedOffsetY)
end

local function PlaceItemSlots(getItemSlot, numRows, numColumns, offsetX, offsetY, show)
    if addon.Options.db.profile.Direction == 'Columns' then
        for row = 1, numRows, 1 do
            for column = 1, numColumns, 1 do
                local itemSlot = getItemSlot((column - 1) * numRows + row)
                PlaceItemSlot(itemSlot, row, column, offsetX, offsetY)
                if show then
                    itemSlot:Show()
                end
            end
        end
    else
        for column = 1, numColumns, 1 do
            for row = 1, numRows, 1 do
                local itemSlot = getItemSlot((row - 1) * numColumns + column)
                PlaceItemSlot(itemSlot, row, column, offsetX, offsetY)
                if show then
                    itemSlot:Show()
                end
            end
        end
    end
end

function merchantItemsContainer:DrawMerchantBuyBackItem(show)
    if show then
        MerchantBuyBackItem:ClearAllPoints()
        MerchantBuyBackItem:SetPoint('LEFT', KrowiEVU_MerchantBuybackInset, 7, 0)
        MerchantBuyBackItem:Show()
    else
        MerchantBuyBackItem:Hide()
    end
end

-- [[ Merchant tab ]] --
local function GetStackSplitOwner()
    if StackSplitFrame and StackSplitFrame:IsShown() and isOwnItemButton[StackSplitFrame.owner] then
        return StackSplitFrame.owner
    end
end

local function CloseStackSplit()
    if not GetStackSplitOwner() then
        return
    end
    if StackSplitCancelButton_OnClick then
        StackSplitCancelButton_OnClick()
    elseif StackSplitFrameCancel_Click then
        StackSplitFrameCancel_Click()
    else
        StackSplitFrame:Hide()
    end
end

local firstDrawDone
local function DrawPage()
    if not firstDrawDone then
        firstDrawDone = true
        KrowiEVU.PluginsApi:CallPlugins('OnFirstDraw')
    end
    -- A split window stays only while its slot keeps its item: page changes, the page clamp and a filter change all move items
    local splitOwner = GetStackSplitOwner()
    local splitIndex = splitOwner and splitOwner:GetID()

    local numRows, numColumns = addon.Options.db.profile.NumRows, addon.Options.db.profile.NumColumns
    local itemsPerPage = numRows * numColumns
    local numPages = math.max(1, math.ceil(#indices / itemsPerPage))
    if paging:GetPage() > numPages then -- The list got shorter or the pages larger
        paging:SetPage(numPages)
    end
    PlaceItemSlots(GetItemSlot, numRows, numColumns, merchantItemsContainer.OffsetX, merchantItemsContainer.OffsetMerchantInfoY, true)
    for i = itemsPerPage + 1, #itemSlots, 1 do
        itemSlots[i]:Hide()
    end

    local firstIndex = (paging:GetPage() - 1) * itemsPerPage
    for i = 1, itemsPerPage, 1 do
        local itemSlot = itemSlots[i]
        local index = indices[firstIndex + i]
        merchantItemSlot.Draw(itemSlot, index)
        KrowiEVU.PluginsApi:CallPlugins('OnItemSlotUpdated', itemSlot, index)
    end
    if splitOwner and splitOwner:GetID() ~= splitIndex then
        CloseStackSplit()
    end

    paging:Update(#indices, itemsPerPage)
    KrowiEVU.PluginsApi:CallPlugins('OnItemSlotsUpdated')
end

local updatePending
function merchantItemsContainer:Update()
    updatePending = nil
    if MerchantFrame.selectedTab ~= 1 then
        return
    end
    addon.Filters:BuildList(indices)
    DrawPage()
    addon.Gui.MerchantFrame.SetMerchantFrameSize()
    addon.Gui.TokenBanner:RequestUpdate()
end

-- Updates on the next frame, once for any number of requests (item data arriving), and not at all when an update runs first
function merchantItemsContainer:RequestUpdate()
    if updatePending then
        return
    end
    updatePending = true
    C_Timer.After(0, function()
        if not updatePending then
            return
        end
        updatePending = nil -- Before the update, so a request made during it gets its own
        if MerchantFrame:IsShown() then
            merchantItemsContainer:Update()
        end
    end)
end

-- For changes made outside a Blizzard refresh, like the options button
function merchantItemsContainer:Refresh()
    if not MerchantFrame:IsShown() or MerchantFrame.selectedTab ~= 1 then
        return
    end
    self:Update()
    addon.Gui.MerchantFrame.UpdateMerchantInfoLayout()
end

local function HideBlizzardMerchantInfo()
    for i = 1, MERCHANT_ITEMS_PER_PAGE, 1 do
        local itemSlot = GetBlizzardItemSlot(i)
        if itemSlot then
            itemSlot:Hide()
        end
    end
    MerchantPrevPageButton:Hide()
    MerchantNextPageButton:Hide()
    MerchantPageText:Hide()
end

hooksecurefunc('MerchantFrame_UpdateMerchantInfo', function()
    if MerchantFrame.selectedTab ~= 1 then -- Krowi_Vendorer calls this on its own tabs
        return
    end
    HideBlizzardMerchantInfo()
    merchantItemsContainer:Update()
    merchantItemsContainer:DrawMerchantBuyBackItem(true)
end)

-- [[ Buyback tab ]] --
-- Only sets the anchors, so it can run again after another addon moved Blizzard's slots
function merchantItemsContainer:PlaceBuybackItemSlots(show)
    PlaceItemSlots(GetBlizzardItemSlot, self.DefaultBuybackInfoNumRows, self.DefaultBuybackInfoNumColumns, self.OffsetX, self.OffsetBuybackInfoY, show)
end

hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function()
    HideItemSlots()
    paging:Hide()
    merchantItemsContainer:PlaceBuybackItemSlots(true)
    merchantItemsContainer:DrawMerchantBuyBackItem(false)
end)

-- [[ Page, filter and item data changes ]] --
paging.OnPageChanged = function()
    DrawPage()
end

-- At once, so a filter set while the window opens (Classic's RememberFilter in an OnShow hook) shows in its first frame
addon.Filters:RegisterListener(function()
    paging:SetPage(1)
    if MerchantFrame:IsShown() then
        merchantItemsContainer:Update()
    end
end)

merchantItemSlot.OnItemInfoReceived = function()
    merchantItemsContainer:RequestUpdate()
end

MerchantFrame:HookScript('OnHide', function()
    paging:SetPage(1)
end)

local eventFrame = CreateFrame('Frame')
eventFrame:RegisterEvent('MERCHANT_SHOW')
eventFrame:RegisterEvent('MERCHANT_CLOSED')
eventFrame:SetScript('OnEvent', function(_, event)
    if event == 'MERCHANT_SHOW' then
        -- Closing the window already went back to page 1 (OnHide above); this is for switching vendors with it open, where
        -- Blizzard's refresh for the new vendor may already have drawn the old page
        if paging:GetPage() ~= 1 then
            paging:SetPage(1)
            if MerchantFrame:IsShown() then
                merchantItemsContainer:Update()
            end
        end
    else
        merchantItemSlot.StopQualityUpdates()
    end
end)
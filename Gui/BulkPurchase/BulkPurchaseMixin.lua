-- [[ Namespaces ]] --
local _, addon = ...

KrowiEVU_BulkPurchaseMixin = {}
local mixin = KrowiEVU_BulkPurchaseMixin

local ContainerGetNumFreeSlots = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
local ContainerGetNumSlots     = C_Container and C_Container.GetContainerNumSlots     or GetContainerNumSlots
local ContainerGetItemInfo     = C_Container and C_Container.GetContainerItemInfo     or GetContainerItemInfo
local GetItemFamily_  = C_Item and C_Item.GetItemFamily  or GetItemFamily
local GetItemCount_   = C_Item and C_Item.GetItemCount   or GetItemCount

local function GetMerchantItemInfoNormalized(index)
    if addon.Util.IsMainline then
        local info = C_MerchantFrame.GetItemInfo(index)
        if not info then return nil end
        return info
    else
        local name, texture, price, stackCount, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(index)
        if not name then return nil end
        return {
            name             = name,
            price            = price,
            stackCount       = stackCount,
            numAvailable     = numAvailable,
            hasExtendedCost  = extendedCost,
        }
    end
end

StaticPopupDialogs['KEVU_BULK_CONFIRM'] = {
    preferredIndex = 3,
    text           = '%d × %s — are you sure?',
    button1        = YES,
    button2        = NO,
    OnAccept       = function(dialog)
        local d = dialog.data
        mixin:DoPurchase(d.amount, d.itemIndex, d.itemLink, d.stack)
    end,
    timeout        = 0,
    hideOnEscape   = true,
}

local tooltipLines = {
    stack = {
        labelKey = 'Stack purchase',
        field    = 'stackClick',
        {labelKey = 'Stack size',     field = 'stack'},
        {labelKey = 'Partial stack',  field = 'partialFit'},
    },
    max = {
        labelKey = 'Maximum purchase',
        field    = 'max',
        {labelKey = 'You can afford', field = 'afford'},
        {labelKey = 'You can fit',    field = 'fit'},
        {
            labelKey = 'Vendor has',
            field    = 'available',
            Hide     = function() return (mixin.available or 0) <= 1 end,
        },
    },
}

local function HasBagEquippedInSlot(slotID)
    local inventorySlotId = GetInventorySlotInfo('Bag' .. (slotID - 1) .. 'Slot')
    return GetInventoryItemID('player', inventorySlotId) ~= nil
end

function mixin:GetFreeBagSpace(itemID)
    local canFit   = 0
    local itemType = GetItemFamily_(itemID) or 0
    local stackSize = GetMerchantItemMaxStack(self.itemIndex) or 1

    local maxBag = addon.Util.IsMainline and 5 or 4
    for bag = 0, maxBag do
        local freeSpace, bagType = ContainerGetNumFreeSlots(bag)
        if freeSpace and bagType then
            if bagType == 0
            or (HasBagEquippedInSlot(bag)
                and (bagType == itemType or (itemType ~= 0 and bit.band(itemType, bagType) == bagType)))
            then
                canFit = canFit + (freeSpace * stackSize)

                local totalSlots = ContainerGetNumSlots(bag)
                for slot = 1, totalSlots do
                    if addon.Util.IsMainline then
                        local itemInfo = ContainerGetItemInfo(bag, slot)
                        if itemInfo and itemInfo.itemID == itemID then
                            canFit = canFit + (stackSize - (itemInfo.stackCount or 0))
                        end
                    else
                        local _, count, _, _, _, _, _, _, _, slotItemID = ContainerGetItemInfo(bag, slot)
                        if slotItemID == itemID then
                            canFit = canFit + (stackSize - (count or 0))
                        end
                    end
                end
            end
        end
    end
    return canFit, stackSize
end

local function IsItemUnique(itemID)
    if not addon.Util.IsMainline then return false end
    if not C_TooltipInfo then return false end
    local tooltipData = C_TooltipInfo.GetItemByID(itemID)
    if not tooltipData then return false end
    local uniqueString = ITEM_UNIQUE or 'Unique'
    for _, line in ipairs(tooltipData.lines) do
        if line.leftText == uniqueString then
            return true
        end
    end
    return false
end

function mixin:Show(clickedButton)
    self.typing = false
    KrowiEVU_BulkLeftButton:Disable()
    KrowiEVU_BulkRightButton:Enable()
    KrowiEVU_BulkStackButton:Enable()
    if self.max < (self.stackClick or 1) then
        KrowiEVU_BulkStackButton:Disable()
    end
    KrowiEVU_BulkStackButton:SetText(addon.L['Stack'])
    KrowiEVU_BulkMaxButton:SetText(addon.L['Max'])
    KrowiEVU_BulkBuyButton:SetText(addon.L['Buy'])

    KrowiEVU_BulkPurchaseFrame:ClearAllPoints()
    KrowiEVU_BulkPurchaseFrame:SetPoint('BOTTOMLEFT', clickedButton, 'TOPLEFT', 0, 0)
    KrowiEVU_BulkPurchaseFrame:Show()
    self:UpdateDisplay()
end

function mixin:OnModifiedClick(frame, button)
    if not (MerchantFrame.selectedTab == 1 and IsShiftKeyDown() and not IsControlKeyDown() and not ChatFrame1EditBox:HasFocus()) then
        MerchantItemButton_OnModifiedClick(frame, button)
        return
    end

    self.itemIndex = frame:GetID()
    local info = GetMerchantItemInfoNormalized(self.itemIndex)
    if not info then return end

    self.itemName       = info.name
    self.price          = info.price
    self.preset         = info.stackCount
    self.available      = info.numAvailable
    self.altCurrencyMode = false

    self.itemLink = GetMerchantItemLink(self.itemIndex)

    if self.itemLink == nil then
        BuyMerchantItem(self.itemIndex, self.preset)
        return
    end

    if addon.Util.IsMainline and strmatch(self.itemLink, 'currency') and (not self.price or self.price <= 0) then
        local currInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(self.itemLink)
        if currInfo then
            local totalMax = currInfo.maxQuantity
            self.fit   = totalMax <= 0 and 10000000 or totalMax
            self.stack = self.preset
            self:AltCurrencyHandling(self.itemIndex, frame)
            return
        end
    end

    if strmatch(self.itemLink, 'item') then
        self.itemID = tonumber(strmatch(self.itemLink, 'item:(%d+):'))
        local bagMax, stack = self:GetFreeBagSpace(self.itemID)
        self.stack      = stack
        self.fit        = bagMax
        self.partialFit = bagMax % stack
    elseif addon.Util.IsMainline and strmatch(self.itemLink, 'currency') then
        self.stack = self.preset
        local currInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(self.itemLink)
        if currInfo then
            local totalMax = currInfo.maxQuantity
            self.fit = totalMax == 0 and 10000000 or (totalMax - currInfo.quantity)
        else
            self.fit = 10000000
        end
        self.partialFit = 0
    end

    if not addon.Util.IsClassicEra and info.hasExtendedCost and (not self.price or self.price <= 0) then
        self:AltCurrencyHandling(self.itemIndex, frame)
        return
    end

    KrowiEVU_BulkCurrency1:SetTexture('Interface\\MONEYFRAME\\UI-GoldIcon')
    KrowiEVU_BulkCurrency2:SetTexture('Interface\\MONEYFRAME\\UI-SilverIcon')
    KrowiEVU_BulkCurrency3:SetTexture('Interface\\MONEYFRAME\\UI-CopperIcon')

    if self.itemID and IsItemUnique(self.itemID) then
        self.afford = 1
    elseif not self.price or self.price <= 0 then
        self.afford = self.fit
    else
        self.afford = floor(GetMoney() / ceil(self.price / self.preset))
    end

    self.max = min(self.fit, self.afford)
    if self.available > -1 then
        self.max = min(self.max, self.available)
    end

    if self.max <= 0 then return end
    if self.max == 1 then
        MerchantItemButton_OnClick(frame, 'LeftButton')
        return
    end

    self.defaultStack = self.preset
    self.split = 1
    self:SetStackClick()
    self:Show(frame)
end

function mixin:AltCurrencyHandling(itemIndex, frame)
    self.altCurrencyMode = true
    self.numAltCurrency  = GetMerchantItemCostInfo(itemIndex)
    self.altCurrTex      = {}
    self.altCurrPrice    = {}
    self.altCurrAfford   = {}

    if self.numAltCurrency <= 0 then
        self.afford = self.fit
    else
        for i = 1, self.numAltCurrency do
            local tex, price, link = GetMerchantItemCostItem(itemIndex, i)
            self.altCurrTex[i]   = tex
            self.altCurrPrice[i] = price

            if link and strmatch(link, 'currency') and addon.Util.IsMainline then
                local currInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(link)
                self.altCurrAfford[i] = currInfo
                    and floor(currInfo.quantity / price) * self.preset
                    or  0
            elseif link and strmatch(link, 'item') then
                local id = tonumber(strmatch(link, 'item:(%d+):'))
                self.altCurrAfford[i] = floor(GetItemCount_(id, true) / price) * self.preset
            else
                self.altCurrAfford[i] = 0
            end
        end
        self.afford = self.altCurrAfford[1] or 0
        if self.numAltCurrency > 1 then
            for i = 2, self.numAltCurrency do
                self.afford = min(self.afford, self.altCurrAfford[i] or 999999)
            end
        end
    end

    if self.itemID and IsItemUnique(self.itemID) then
        self.afford = 1
    end

    self.max = min(self.fit, self.afford)
    if self.available > -1 then
        self.max = min(self.max, self.available * self.preset)
    end

    if self.max <= 0 then return end
    if self.max == 1 then
        MerchantItemButton_OnClick(frame, 'LeftButton')
        return
    end

    self.defaultStack = self.preset
    self.split        = self.defaultStack
    self.partialFit   = self.fit % self.stack
    self:SetStackClick()
    self:Show(frame)
end

local function RunPurchaseLoop(itemIndex, numLoops, loopAmt, leftover)
    if numLoops > 0 then
        BuyMerchantItem(itemIndex, loopAmt)
        numLoops = numLoops - 1
        C_Timer.After(0.5, function() RunPurchaseLoop(itemIndex, numLoops, loopAmt, leftover) end)
    elseif leftover > 0 then
        BuyMerchantItem(itemIndex, leftover)
    end
end

function mixin:DoPurchase(amount, itemIndex, itemLink, stack)
    itemIndex = itemIndex or self.itemIndex
    itemLink  = itemLink  or self.itemLink
    stack     = stack     or self.stack
    KrowiEVU_BulkPurchaseFrame:Hide()

    if itemLink and strmatch(itemLink, 'currency') then
        BuyMerchantItem(itemIndex, amount)
        return
    end

    if amount <= stack then
        BuyMerchantItem(itemIndex, amount)
        return
    end

    local numLoops  = floor(amount / stack)
    local leftover  = amount % stack
    RunPurchaseLoop(itemIndex, numLoops, stack, leftover)
end

function mixin:VerifyPurchase(amount)
    amount = amount or self.split
    if self.altCurrencyMode then
        amount = self:AltCurrRounding(amount)
    end
    if amount <= 0 then return end

    if amount > self.stack and amount > self.defaultStack
    and addon.Options.db.profile.BulkPurchase.ShowConfirm then
        local dialog = StaticPopup_Show('KEVU_BULK_CONFIRM', amount, self.itemName)
        if dialog then
            dialog.data = {
                amount    = amount,
                itemIndex = self.itemIndex,
                itemLink  = self.itemLink,
                stack     = self.stack,
            }
        end
    else
        self:DoPurchase(amount)
    end
end

function mixin:AltCurrRounding(purchase)
    local hasSingleCost = false
    for i = 1, (self.numAltCurrency or 0) do
        if self.altCurrPrice[i] == 1 then hasSingleCost = true end
    end
    if hasSingleCost and purchase % self.preset ~= 0 then
        purchase = purchase + (self.preset - (purchase % self.preset))
    end
    return purchase
end

function mixin:UpdateDisplay()
    KrowiEVU_BulkLeftButton:Enable()
    KrowiEVU_BulkRightButton:Enable()
    KrowiEVU_BulkMaxButton:Enable()

    if self.split >= self.max then
        KrowiEVU_BulkRightButton:Disable()
        KrowiEVU_BulkMaxButton:Disable()
    end
    if not self.altCurrencyMode and self.split <= 1 then
        KrowiEVU_BulkLeftButton:Disable()
    elseif self.altCurrencyMode and self.split <= self.preset then
        KrowiEVU_BulkLeftButton:Disable()
    end

    self:SetStackClick()
    KrowiEVU_BulkStackButton:Enable()
    if self.max < (self.stackClick or 1) then
        KrowiEVU_BulkStackButton:Disable()
    end

    if not self.altCurrencyMode then
        local cost   = ceil(self.split * (self.price / self.defaultStack))
        local gold   = floor(cost / 10000)
        local silver = floor((cost / 100) % 100)
        local copper = floor(cost % 100)
        KrowiEVU_BulkCurrencyAmt1:SetText(gold)
        KrowiEVU_BulkCurrencyAmt2:SetText(silver)
        KrowiEVU_BulkCurrencyAmt3:SetText(copper)
    else
        local amount = self:AltCurrRounding(self.split)
        local numPurchases = amount / self.preset

        KrowiEVU_BulkCurrencyAmt1:SetText(numPurchases * (self.altCurrPrice[1] or 0))
        KrowiEVU_BulkCurrency1:SetTexture(self.altCurrTex[1])

        if self.altCurrPrice[2] then
            KrowiEVU_BulkCurrencyAmt2:SetText(numPurchases * self.altCurrPrice[2])
            KrowiEVU_BulkCurrency2:SetTexture(self.altCurrTex[2])
        else
            KrowiEVU_BulkCurrencyAmt2:SetText('')
            KrowiEVU_BulkCurrency2:SetTexture(nil)
        end

        if self.altCurrPrice[3] then
            KrowiEVU_BulkCurrencyAmt3:SetText(numPurchases * self.altCurrPrice[3])
            KrowiEVU_BulkCurrency3:SetTexture(self.altCurrTex[3])
        else
            KrowiEVU_BulkCurrencyAmt3:SetText('')
            KrowiEVU_BulkCurrency3:SetTexture(nil)
        end
    end

    KrowiEVU_BulkAmountText:SetText(self.split)
end

function mixin:SetStackClick()
    local increase = ((self.partialFit == 0 and self.stack or self.partialFit) - (self.split % self.stack))
    self.stackClick = self.split + (increase == 0 and self.stack or increase)
end

function mixin:DeStackClick()
    local cur = tonumber(KrowiEVU_BulkAmountText:GetText()) or self.split
    if cur <= self.stack then
        self.split = self.altCurrencyMode and self.preset or 1
    else
        self.split = cur - self.stack
    end
    self:UpdateDisplay()
end

function mixin:Buy_Click()
    local amount = tonumber(KrowiEVU_BulkAmountText:GetText()) or self.split
    self:VerifyPurchase(amount)
end

function mixin:Cancel_Click()
    KrowiEVU_BulkPurchaseFrame:Hide()
end

function mixin:Stack_Click(frame, button)
    if button == 'LeftButton' then
        self.split = min(self.stackClick, self.max)
        self:UpdateDisplay()
        if frame:IsEnabled() then self:OnEnter(frame) else GameTooltip:Hide() end
    elseif button == 'RightButton' then
        self:DeStackClick()
        if frame:IsEnabled() then self:OnEnter(frame) else GameTooltip:Hide() end
    end
end

function mixin:Max_Click()
    self.split = self.max
    self:UpdateDisplay()
end

function mixin:Left_Click()
    if self.altCurrencyMode then
        self.split = self.split - self.preset
    else
        self.split = self.split - 1
    end
    self:UpdateDisplay()
end

function mixin:Right_Click()
    if self.altCurrencyMode then
        self.split = self.split + self.preset
    else
        self.split = self.split + 1
    end
    self:UpdateDisplay()
end

function mixin:OnChar(text)
    if text < '0' or text > '9' then return end
    if not self.typing then
        self.typing = true
        self.split  = 0
    end
    local input = (self.split * 10) + tonumber(text)
    if input == 0 then return end
    if input <= self.max then
        self.split = input
    else
        self.split = self.max
    end
    self:UpdateDisplay()
end

function mixin:OnKeyDown(key)
    if key == 'BACKSPACE' or key == 'DELETE' then
        if not self.typing or self.split <= 1 then return end
        self.split = floor(self.split / 10)
        if self.split <= 1 then
            self.split  = 1
            self.typing = false
        end
        self:UpdateDisplay()
    elseif key == 'ENTER' then
        self:VerifyPurchase()
    elseif key == 'ESCAPE' then
        KrowiEVU_BulkPurchaseFrame:Hide()
    elseif key == 'LEFT' or key == 'DOWN' then
        self:Left_Click()
    elseif key == 'RIGHT' or key == 'UP' then
        self:Right_Click()
    elseif key == 'PRINTSCREEN' then
        Screenshot()
    end
end

function mixin:OnEnter(frame)
    local isMax   = (frame == KrowiEVU_BulkMaxButton)
    local lines   = isMax and tooltipLines.max or tooltipLines.stack
    lines.amount  = self[lines.field]
    for _, line in ipairs(lines) do
        line.amount = self[line.field]
    end
    self:CreateTooltip(frame, lines)
end

function mixin:CreateTooltip(frame, lines)
    GameTooltip:SetOwner(frame, 'ANCHOR_BOTTOMRIGHT')
    GameTooltip:SetText(addon.L[lines.labelKey] .. '|cFFFFFFFF - |r' .. GREEN_FONT_COLOR_CODE .. (lines.amount or 0) .. '|r')
    for _, line in ipairs(lines) do
        if not (line.Hide and line.Hide()) then
            local color = (line.amount == lines.amount) and GREEN_FONT_COLOR or HIGHLIGHT_FONT_COLOR
            GameTooltip:AddDoubleLine(addon.L[line.labelKey], line.amount or 0, 1, 1, 1, color.r, color.g, color.b)
        end
    end
    GameTooltip:Show()
end

function mixin:OnLeave()
    GameTooltip:Hide()
end

function mixin:OnHide()
    KrowiEVU_BulkCurrency1:SetTexture(nil)
    KrowiEVU_BulkCurrency2:SetTexture(nil)
    KrowiEVU_BulkCurrency3:SetTexture(nil)
    KrowiEVU_BulkCurrencyAmt1:SetText('')
    KrowiEVU_BulkCurrencyAmt2:SetText('')
    KrowiEVU_BulkCurrencyAmt3:SetText('')
    StaticPopup_Hide('KEVU_BULK_CONFIRM')
end
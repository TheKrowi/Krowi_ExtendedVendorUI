local _, addon = ...
if addon.NotLoaded then return end
addon.Gui.MerchantItemSlot = {}
local merchantItemSlot = addon.Gui.MerchantItemSlot

-- Draws one of the addon's item slots the way Blizzard's MerchantFrame_UpdateMerchantInfo draws MerchantItemN,
-- with the vendor's real index. Keep it in step with Blizzard's per-item code after each patch:
-- Mainline: live Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua:275-403
-- Classic: classic Blizzard_UIPanels_Game/TBC/MerchantFrame.lua:196-321 (Mists, Anniversary; Era's Vanilla copy differs only in the heirloom check)

local MAX_MONEY_DISPLAY_WIDTH = 120 -- A local in Blizzard's MerchantFrame.lua

-- [[ Item info ]] --
if addon.Util.IsMainline then
    function merchantItemSlot.GetItemInfo(index)
        return C_MerchantFrame.GetItemInfo(index)
    end
else
    -- Classic has no C_MerchantFrame.GetItemInfo: the same table, from GetMerchantItemInfo
    function merchantItemSlot.GetItemInfo(index)
        local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost, currencyID, spellID = GetMerchantItemInfo(index)
        return {
            name = name,
            texture = texture,
            price = price,
            stackCount = stackCount,
            numAvailable = numAvailable,
            isPurchasable = isPurchasable,
            isUsable = isUsable,
            hasExtendedCost = extendedCost,
            currencyID = currencyID,
            spellID = spellID,
            isQuestStartItem = false -- This info isn't available in the old API
        }
    end
end

-- [[ Alternate currency ]] --
-- Copy of MerchantFrame_UpdateAltCurrency (live MerchantFrame.lua:470-504, the same on Classic), which only finds MerchantItemN
local function UpdateAltCurrency(slot, index, canAfford)
    local itemCount = GetMerchantItemCostInfo(index)
    local frameName = slot:GetName() .. 'AltCurrencyFrame'
    local usedCurrencies = 0
    local width = 0

    if itemCount > 0 then
        for i = 1, MAX_ITEM_COST do
            local itemTexture, itemValue, itemLink = GetMerchantItemCostItem(index, i)
            if itemTexture then
                usedCurrencies = usedCurrencies + 1
                local button = _G[frameName .. 'Item' .. usedCurrencies]
                button.index = index
                button.item = i
                button.itemLink = itemLink
                AltCurrencyFrame_Update(frameName .. 'Item' .. usedCurrencies, itemTexture, itemValue, canAfford)
                width = width + button:GetWidth()
                if usedCurrencies > 1 then
                    width = width + 4 -- Button spacing
                end
                button:Show()
            end
        end
        for i = usedCurrencies + 1, MAX_ITEM_COST do
            _G[frameName .. 'Item' .. i]:Hide()
        end
    else
        for i = 1, MAX_ITEM_COST do
            _G[frameName .. 'Item' .. i]:Hide()
        end
    end
    return width
end

-- [[ Quality ]] --
local qualityEventFrame = CreateFrame('Frame')
qualityEventFrame:SetScript('OnEvent', function(self)
    self:UnregisterEvent('GET_ITEM_INFO_RECEIVED') -- Registered again by the next draw if an item is still missing
    if merchantItemSlot.OnItemInfoReceived then
        merchantItemSlot.OnItemInfoReceived()
    end
end)

local UpdateQuality
if addon.Util.IsMainline then
    -- Mirrors MerchantFrameItem_UpdateQuality (live MerchantFrame.lua:212-228), which registers its event on MerchantFrame
    function UpdateQuality(slot, link, isBound)
        local quality = link and select(3, C_Item.GetItemInfo(link)) or nil
        if quality then
            local colorData = ColorManager.GetColorDataForItemQuality(quality)
            if colorData then
                slot.Name:SetTextColor(colorData.r, colorData.g, colorData.b)
            else
                slot.Name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
            end
        else
            slot.Name:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
            if not qualityEventFrame:IsEventRegistered('GET_ITEM_INFO_RECEIVED') then
                qualityEventFrame:RegisterEvent('GET_ITEM_INFO_RECEIVED')
            end
        end

        local doNotSuppressOverlays = false
        slot.ItemButton:SetItemButtonQuality(quality, link, doNotSuppressOverlays, isBound)
    end
else
    function UpdateQuality()
        -- No quality borders for Classic (classic TBC MerchantFrame.lua:137-148)
    end
end

function merchantItemSlot.StopQualityUpdates()
    qualityEventFrame:UnregisterEvent('GET_ITEM_INFO_RECEIVED')
end

-- [[ Tint ]] --
-- The same on every client
local function Tint(slot, numAvailable, isKnownHeirloom, tintRed)
    local itemButton = slot.ItemButton
    if numAvailable == 0 or isKnownHeirloom then
        -- If not available and not usable
        if tintRed then
            SetItemButtonNameFrameVertexColor(slot, 0.5, 0, 0)
            SetItemButtonSlotVertexColor(slot, 0.5, 0, 0)
            SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0)
            SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0)
        else
            SetItemButtonNameFrameVertexColor(slot, 0.5, 0.5, 0.5)
            SetItemButtonSlotVertexColor(slot, 0.5, 0.5, 0.5)
            SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5)
            SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0.5, 0.5)
        end
    elseif tintRed then
        SetItemButtonNameFrameVertexColor(slot, 1.0, 0, 0)
        SetItemButtonSlotVertexColor(slot, 1.0, 0, 0)
        SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0)
        SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0)
    else
        SetItemButtonNameFrameVertexColor(slot, 0.5, 0.5, 0.5)
        SetItemButtonSlotVertexColor(slot, 1.0, 1.0, 1.0)
        SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
        SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0)
    end
end

-- [[ Empty slot ]] --
-- The same on every client
local function DrawEmpty(slot)
    local slotName = slot:GetName()
    local itemButton = slot.ItemButton
    itemButton.price = nil
    itemButton.hasItem = nil
    itemButton.name = nil
    itemButton:Hide()
    SetItemButtonNameFrameVertexColor(slot, 0.5, 0.5, 0.5)
    SetItemButtonSlotVertexColor(slot, 0.4, 0.4, 0.4)
    _G[slotName .. 'Name']:SetText('')
    _G[slotName .. 'MoneyFrame']:Hide()
    _G[slotName .. 'AltCurrencyFrame']:Hide()
end

-- [[ Mainline ]] --
local function DrawMainline(slot, index)
    local info = index and C_MerchantFrame.GetItemInfo(index)
    if not info then
        DrawEmpty(slot)
        return
    end

    local slotName = slot:GetName()
    local itemButton = slot.ItemButton
    local merchantMoney = _G[slotName .. 'MoneyFrame']
    local merchantAltCurrency = _G[slotName .. 'AltCurrencyFrame']

    if info.currencyID then
        info.name, info.texture, info.numAvailable = CurrencyContainerUtil.GetCurrencyContainerInfo(info.currencyID, info.numAvailable, info.name, info.texture, nil)
    end

    local canAfford = CanAffordMerchantItem(index)
    _G[slotName .. 'Name']:SetText(info.name)
    SetItemButtonCount(itemButton, info.stackCount)
    SetItemButtonStock(itemButton, info.numAvailable)
    SetItemButtonTexture(itemButton, info.texture)

    if info.hasExtendedCost and info.price <= 0 then
        itemButton.price = nil
        itemButton.extendedCost = true
        itemButton.name = info.name
        itemButton.link = GetMerchantItemLink(index)
        itemButton.texture = info.texture
        UpdateAltCurrency(slot, index, canAfford)
        merchantAltCurrency:ClearAllPoints()
        merchantAltCurrency:SetPoint('BOTTOMLEFT', slotName .. 'NameFrame', 'BOTTOMLEFT', 0, 31)
        merchantMoney:Hide()
        merchantAltCurrency:Show()
    elseif info.hasExtendedCost and info.price > 0 then
        itemButton.price = info.price
        itemButton.extendedCost = true
        itemButton.name = info.name
        itemButton.link = GetMerchantItemLink(index)
        itemButton.texture = info.texture
        local altCurrencyWidth = UpdateAltCurrency(slot, index, canAfford)
        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH - altCurrencyWidth)
        MoneyFrame_Update(merchantMoney:GetName(), info.price)
        local color
        if canAfford == false then
            color = 'gray'
        end
        SetMoneyFrameColor(merchantMoney:GetName(), color)
        merchantAltCurrency:ClearAllPoints()
        merchantAltCurrency:SetPoint('LEFT', merchantMoney:GetName(), 'RIGHT', -14, 0)
        merchantAltCurrency:Show()
        merchantMoney:Show()
    else
        itemButton.price = info.price
        itemButton.extendedCost = nil
        itemButton.name = info.name
        itemButton.link = GetMerchantItemLink(index)
        itemButton.texture = info.texture
        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH)
        MoneyFrame_Update(merchantMoney:GetName(), info.price)
        local color
        if canAfford == false then
            color = 'gray'
        end
        SetMoneyFrameColor(merchantMoney:GetName(), color)
        merchantAltCurrency:Hide()
        merchantMoney:Show()
    end

    if info.isQuestStartItem then
        itemButton.IconQuestTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG)
        itemButton.IconQuestTexture:Show()
    else
        itemButton.IconQuestTexture:Hide()
    end

    UpdateQuality(slot, GetMerchantItemLink(index))

    local merchantItemID = GetMerchantItemID(index)
    local isHeirloom = merchantItemID and C_Heirloom.IsItemHeirloom(merchantItemID)
    local isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(merchantItemID)

    itemButton.showNonrefundablePrompt = not C_MerchantFrame.IsMerchantItemRefundable(index)

    itemButton.hasItem = true
    itemButton:SetID(index)
    itemButton:Show()

    local tintRed = not info.isPurchasable or (not info.isUsable and not isHeirloom)

    SetItemButtonDesaturated(itemButton, isKnownHeirloom)
    Tint(slot, info.numAvailable, isKnownHeirloom, tintRed)
end

-- [[ Classic ]] --
-- TBC's guard; Era's Vanilla copy has no heirlooms at all, and the constant may be missing there
local hasHeirlooms = ClassicExpansionAtLeast and LE_EXPANSION_WRATH_OF_THE_LICH_KING and ClassicExpansionAtLeast(LE_EXPANSION_WRATH_OF_THE_LICH_KING)

local function DrawClassic(slot, index)
    if not index then
        DrawEmpty(slot)
        return
    end

    local slotName = slot:GetName()
    local itemButton = slot.ItemButton
    local merchantMoney = _G[slotName .. 'MoneyFrame']
    local merchantAltCurrency = _G[slotName .. 'AltCurrencyFrame']

    local name, texture, price, stackCount, numAvailable, isPurchasable, isUsable, extendedCost, currencyID = GetMerchantItemInfo(index)

    if currencyID then
        name, texture, numAvailable = CurrencyContainerUtil.GetCurrencyContainerInfo(currencyID, numAvailable, name, texture, nil)
    end

    local canAfford = CanAffordMerchantItem(index)
    _G[slotName .. 'Name']:SetText(name)
    SetItemButtonCount(itemButton, stackCount)
    SetItemButtonStock(itemButton, numAvailable)
    SetItemButtonTexture(itemButton, texture)

    if extendedCost and price <= 0 then
        itemButton.price = nil
        itemButton.extendedCost = true
        itemButton.name = name
        itemButton.link = GetMerchantItemLink(index)
        itemButton.texture = texture
        UpdateAltCurrency(slot, index, canAfford)
        merchantAltCurrency:ClearAllPoints()
        merchantAltCurrency:SetPoint('BOTTOMLEFT', slotName .. 'NameFrame', 'BOTTOMLEFT', 2, 31)
        merchantMoney:Hide()
        merchantAltCurrency:Show()
    elseif extendedCost and price > 0 then
        itemButton.price = price
        itemButton.extendedCost = true
        itemButton.name = name
        itemButton.link = GetMerchantItemLink(index)
        itemButton.texture = texture
        local altCurrencyWidth = UpdateAltCurrency(slot, index, canAfford)
        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH - altCurrencyWidth)
        MoneyFrame_Update(merchantMoney:GetName(), price)
        local color
        if canAfford == false then
            color = 'gray'
        end
        SetMoneyFrameColor(merchantMoney:GetName(), color)
        merchantAltCurrency:ClearAllPoints()
        merchantAltCurrency:SetPoint('LEFT', merchantMoney:GetName(), 'RIGHT', -12, 0)
        merchantAltCurrency:Show()
        merchantMoney:Show()
    else
        itemButton.price = price
        itemButton.extendedCost = nil
        itemButton.name = name
        itemButton.link = GetMerchantItemLink(index)
        itemButton.texture = texture
        MoneyFrame_SetMaxDisplayWidth(merchantMoney, MAX_MONEY_DISPLAY_WIDTH)
        MoneyFrame_Update(merchantMoney:GetName(), price)
        local color
        if canAfford == false then
            color = 'gray'
        end
        SetMoneyFrameColor(merchantMoney:GetName(), color)
        merchantAltCurrency:Hide()
        merchantMoney:Show()
    end

    local merchantItemID = GetMerchantItemID(index)

    local isHeirloom, isKnownHeirloom
    if hasHeirlooms then
        isHeirloom = merchantItemID and C_Heirloom.IsItemHeirloom(merchantItemID)
        isKnownHeirloom = isHeirloom and C_Heirloom.PlayerHasHeirloom(merchantItemID)
    else
        isHeirloom = false
        isKnownHeirloom = false
    end

    itemButton.showNonrefundablePrompt = isHeirloom

    itemButton.hasItem = true
    itemButton:SetID(index)
    itemButton:Show()

    local tintRed = not isPurchasable or (not isUsable and not isHeirloom)

    SetItemButtonDesaturated(itemButton, isKnownHeirloom)
    Tint(slot, numAvailable, isKnownHeirloom, tintRed)
end

-- index is the vendor's real index, or nil for an empty slot
merchantItemSlot.Draw = addon.Util.IsMainline and DrawMainline or DrawClassic
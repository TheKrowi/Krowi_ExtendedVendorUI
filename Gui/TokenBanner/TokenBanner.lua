local _, addon = ...
if addon.NotLoaded then return end

addon.Gui.TokenBanner = {}
local tokenBanner = addon.Gui.TokenBanner

local preLoadTokenNum = 5

local tokenPool = {}
local function HideAllTokens()
    for _, token in next, tokenPool do
		token:Hide()
	end
end

local function GetPoolToken(index)
    if tokenPool[index] then
        return tokenPool[index]
    end
    local token = CreateFrame('Button', 'KrowiEVU_TokenBannerToken' .. index, KrowiEVU_TokenBanner, 'KrowiEVU_Token_Template')
    tokenPool[index] = token
    return token
end

local tokenLines
local function DrawTokenQuick(index)
    local token = GetPoolToken(index)
    if index == 1 then
        tokenLines = 1
        token:SetPoint('TOPRIGHT', KrowiEVU_TokenBanner, 'TOPRIGHT', -10, addon.Util.IsModern and -5 or -4)
    else
        token:SetPoint('TOPRIGHT', _G['KrowiEVU_TokenBannerToken' .. (index - 1)], 'TOPLEFT', -10, 0)
    end

    token:Draw()

    return token
end

local function DrawToken(index)
    local token  = DrawTokenQuick(index)

    local left, bannerLeft = token:GetLeft(), KrowiEVU_TokenBanner:GetLeft() -- nil until the frames are laid out
    if left and bannerLeft and left < bannerLeft + 10 then
        local offset = 5 + (token:GetHeight() + 3) * tokenLines
        token:SetPoint('TOPRIGHT', KrowiEVU_TokenBanner, 'TOPRIGHT', -10, addon.Util.IsModern and -offset or -offset + 1)
        tokenLines = tokenLines + 1
    end
end

function tokenBanner:Load()
    local banner = CreateFrame('Frame', 'KrowiEVU_TokenBanner', MerchantMoneyInset, 'KrowiEVU_ThinGoldEdge_Template') -- ThinGoldEdgeTemplate
    banner:SetPoint('TOPLEFT', MerchantMoneyInset, 'TOPLEFT', 3, -2)
    banner:SetPoint('BOTTOMRIGHT', MerchantMoneyInset, 'BOTTOMRIGHT', -3, 2)

    for i = 1, preLoadTokenNum do
        DrawTokenQuick(i)
    end
    HideAllTokens()
end

local function UpdateBannerHeight()
    local height = 5 + (GetPoolToken(1):GetHeight() + 3) * tokenLines + 5
    MerchantMoneyInset:SetHeight(height)
end

local function HideBlizzardTokenFrame()
    -- if MerchantMoneyInset then
    --     MerchantMoneyInset:Hide()
    -- end
    if MerchantExtraCurrencyInset then
        MerchantExtraCurrencyInset:Hide()
    end
    if MerchantMoneyBg then
        MerchantMoneyBg:Hide()
    end
    if MerchantExtraCurrencyBg then
        MerchantExtraCurrencyBg:Hide()
    end
    if MerchantMoneyFrame then
        MerchantMoneyFrame:Hide()
    end
    if MerchantExtraCurrencyBg then
        MerchantExtraCurrencyBg:Hide()
    end
    for i = 1, MAX_MERCHANT_CURRENCIES do
        local token = _G['MerchantToken'..i]
        if token then
            token:Hide()
        end
    end
end

-- One update for any number of requests within the delay. The flag is cleared before the update runs, so an error in it
-- cannot stop the later ones, as Krowi_Util's DelayFunction would: it frees its slot only after the function returns.
local updatePending
function tokenBanner:RequestUpdate()
    if not KrowiEVU_TokenBanner or updatePending then
        return
    end

    updatePending = true
    C_Timer.After(0.25, function()
        updatePending = nil
        if not MerchantFrame:IsShown() then -- Opening the window requests one
            return
        end
        tokenBanner:Update()
        addon.Gui.MerchantFrame.SetMerchantFrameSize()
    end)
end

-- MerchantFrame_UpdateCurrencies is called before MerchantFrame_Update so we need to do the handling here
hooksecurefunc('MerchantFrame_Update', function()
    if not KrowiEVU_TokenBanner then
        return
    end

    HideBlizzardTokenFrame()

    tokenBanner:RequestUpdate()
end)

local function HideRemainingTokens(startIndex)
    local numTokens = #tokenPool
    for i = startIndex, numTokens, 1 do
        tokenPool[i]:Hide()
    end
end

-- Calculate functions
local function CalculateGoldCount(goldCount, itemIndex)
    local info = addon.Gui.MerchantItemSlot.GetItemInfo(itemIndex)
    if not info then
        return goldCount
    end
    if info.price and info.price > 0 and not info.hasExtendedCost then
        goldCount = goldCount + info.price
    end
    return goldCount
end

-- Keyed by the id, so one cost whose links differ (an amount or level in the link) still gets one token
local function CalculateCurrencyCounts(currencyCounts, link, texture, value)
    local key = link:match('currency:%d+')
    if not key then
        return currencyCounts
    end

    if not currencyCounts[key] then
        currencyCounts[key] = {
            link = link,
            texture = texture,
            count = 0
        }
    end
    currencyCounts[key].count = currencyCounts[key].count + value

    return currencyCounts
end

local function CalculateItemCounts(itemCounts, link, texture, value)
    local key = link:match('item:%d+')
    if not key then
        return itemCounts
    end

    if not itemCounts[key] then
        itemCounts[key] = {
            link = link,
            texture = texture,
            count = 0
        }
    end
    itemCounts[key].count = itemCounts[key].count + value

    return itemCounts
end

local function CalculateOtherCounts(currencyCounts, itemCounts, itemIndex)
    local numCosts = GetMerchantItemCostInfo(itemIndex)
    if numCosts and numCosts > 0 then
        for costIndex = 1, numCosts do
            local texture, value, link = GetMerchantItemCostItem(itemIndex, costIndex)
            if texture and value and link then
                currencyCounts = CalculateCurrencyCounts(currencyCounts, link, texture, value)
                itemCounts = CalculateItemCounts(itemCounts, link, texture, value)
            end
        end
    end
    return currencyCounts, itemCounts
end

local function CalculateCounts()
    local currencyCounts, itemCounts, goldCount = {}, {}, 0
    for _, index in ipairs(addon.Gui.MerchantItemsContainer:GetIndices()) do
        goldCount = CalculateGoldCount(goldCount, index)
        currencyCounts, itemCounts = CalculateOtherCounts(currencyCounts, itemCounts, index)
    end
    return goldCount, currencyCounts, itemCounts
end

-- Update / Draw functions
local tokenIndex
local function DrawGoldToken(goldCount)
    if goldCount <= 0 then
        return
    end

    if GetPoolToken(tokenIndex + 1):SetGold(goldCount) then
        tokenIndex = tokenIndex + 1
        DrawToken(tokenIndex)
    end
end

-- The Hide currencies you have none of option
local function IsHiddenCost(token)
    return addon.Options.db.profile.TokenBanner.HideNone and token.HaveAmount == 0
end

-- A cost without data, or hidden, takes no place in the row; HideRemainingTokens hides the pooled token it was given
local function DrawCurrencyToken(texture, value, link)
    local token = GetPoolToken(tokenIndex + 1)
    if token:SetCurrency(texture, value, link) and not IsHiddenCost(token) then
        tokenIndex = tokenIndex + 1
        DrawToken(tokenIndex)
    end
end

local function DrawItemToken(texture, value, link)
    local token = GetPoolToken(tokenIndex + 1)
    if token:SetItem(texture, value, link) and not IsHiddenCost(token) then
        tokenIndex = tokenIndex + 1
        DrawToken(tokenIndex)
    end
end

function tokenBanner:Update()
    local goldCount, currencyCounts, itemCounts = CalculateCounts()

    tokenIndex = 0

    DrawGoldToken(goldCount)

    for _, currency in pairs(currencyCounts) do
        DrawCurrencyToken(currency.texture, currency.count, currency.link)
    end

    for _, item in pairs(itemCounts) do
        DrawItemToken(item.texture, item.count, item.link)
    end

    HideRemainingTokens(tokenIndex + 1)

    UpdateBannerHeight()
end

function tokenBanner:CreateOptionsMenu(menuObj, menuBuilder)
    local profile = addon.Options.db.profile.TokenBanner

    local tokenBannerMenu = menuBuilder:CreateSubmenuButton(menuObj, addon.L['Token Banner'])

    menuBuilder:CreateTitle(tokenBannerMenu, addon.L['Token Format'])
	menuBuilder:CreateRadio(tokenBannerMenu, addon.L['Need'], profile, {'Format'}, 'Need')
	menuBuilder:CreateRadio(tokenBannerMenu, addon.L['Have'], profile, {'Format'}, 'Have')
	menuBuilder:CreateRadio(tokenBannerMenu, addon.L['Both'], profile, {'Format'}, 'Both')

    menuBuilder:CreateDivider(tokenBannerMenu)

	addon.CurrencyLib:CreateMoneyOptionsMenu(tokenBannerMenu, menuBuilder, profile)
    menuBuilder:CreateCheckbox(tokenBannerMenu, addon.L['Gold total'], profile, {'GoldTotal'}) -- Last in Money Options

	menuBuilder:CreateDivider(tokenBannerMenu)

	addon.CurrencyLib:CreateCurrencyOptionsMenu(tokenBannerMenu, menuBuilder, profile)
    menuBuilder:CreateCheckbox(tokenBannerMenu, addon.L['Hide currencies you have none of'], profile, {'HideNone'}) -- Last in Currency Options

    menuBuilder:AddChildMenu(menuObj, tokenBannerMenu)
end
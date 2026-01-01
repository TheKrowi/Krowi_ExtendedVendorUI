local _, addon = ...;

-- if not addon.Util.IsMainline then
--     return;
-- end

addon.Gui.TokenBanner = {};
local tokenBanner = addon.Gui.TokenBanner;

local preLoadTokenNum = 5;

local tokenPool = {}
function HideAllTokens()
    for _, token in next, tokenPool do
		token:Hide();
	end
end

local function GetPoolToken(index)
    if tokenPool[index] then
        return tokenPool[index];
    end
    local token = CreateFrame("Button", "KrowiEVU_TokenBannerToken" .. index, KrowiEVU_TokenBanner, "KrowiEVU_Token_Template");
    tokenPool[index] = token;
    return token
end

local tokenLines
local function DrawToken(index)
    local token = GetPoolToken(index);
    if index == 1 then
        tokenLines = 1
        token:SetPoint("TOPRIGHT", KrowiEVU_TokenBanner, "TOPRIGHT", -10, addon.Util.IsMainline and -5 or -4);
    else
        token:SetPoint("TOPRIGHT", _G["KrowiEVU_TokenBannerToken" .. (index - 1)], "TOPLEFT", -10, 0);
    end

    token:Draw()

    if token:GetLeft() < KrowiEVU_TokenBanner:GetLeft() + 10 then
        local offset = 5 + (token:GetHeight() + 3) * tokenLines
        token:SetPoint("TOPRIGHT", KrowiEVU_TokenBanner, "TOPRIGHT", -10, addon.Util.IsMainline and -offset or -offset + 1);
        tokenLines = tokenLines + 1;
    end
end

function tokenBanner:Load()
    local banner = CreateFrame("Frame", "KrowiEVU_TokenBanner", MerchantMoneyInset, "KrowiEVU_ThinGoldEdge_Template"); -- ThinGoldEdgeTemplate
    banner:SetPoint("TOPLEFT", MerchantMoneyInset, "TOPLEFT", 3, -2);
    banner:SetPoint("BOTTOMRIGHT", MerchantMoneyInset, "BOTTOMRIGHT", -3, 2);

    for i = 1, preLoadTokenNum do
        DrawToken(i);
    end
    HideAllTokens()
end

local function UpdateBannerHeight()
    local height = 5 + (GetPoolToken(1):GetHeight() + 3) * tokenLines + 5
    MerchantMoneyInset:SetHeight(height)
end

local function HideBlizzardTokenFrame()
    -- if MerchantMoneyInset then
    --     MerchantMoneyInset:Hide();
    -- end
    if MerchantExtraCurrencyInset then
        MerchantExtraCurrencyInset:Hide();
    end
    if MerchantMoneyBg then
        MerchantMoneyBg:Hide();
    end
    if MerchantExtraCurrencyBg then
        MerchantExtraCurrencyBg:Hide();
    end
    if MerchantMoneyFrame then
        MerchantMoneyFrame:Hide();
    end
    if MerchantExtraCurrencyBg then
        MerchantExtraCurrencyBg:Hide();
    end
    for i = 1, MAX_MERCHANT_CURRENCIES do
        local token = _G["MerchantToken"..i];
        if token then
            token:Hide();
        end
    end
end

-- MerchantFrame_UpdateCurrencies is called before MerchantFrame_Update so we need to do the handling here
hooksecurefunc("MerchantFrame_Update", function()
    if not KrowiEVU_TokenBanner then
        return;
    end

    HideBlizzardTokenFrame()

    addon.Util.DelayFunction("KrowiEVU_TokenBannerUpdate", 0.5, function()
        tokenBanner:Update()
        addon.Gui.MerchantFrame.SetMerchantFrameSize()
    end);
end);

local function HideRemainingTokens(startIndex)
    local numTokens = #tokenPool;
    for i = startIndex, numTokens, 1 do
        tokenPool[i]:Hide();
    end
end

-- Calculate functions
local function CalculateGoldCount(goldCount, itemIndex)
    local _, _, price, _, _, _, _, extendedCost = GetMerchantItemInfo(itemIndex);
    if price and price > 0 and not extendedCost then
        goldCount = goldCount + price;
    end
    return goldCount
end

local function CalculateCurrencyCounts(currencyCounts, link, texture, value)
    if not link:find("currency:") then
        return currencyCounts
    end

    if not currencyCounts[link] then
        currencyCounts[link] = {
            link = link,
            texture = texture,
            count = 0
        };
    end
    currencyCounts[link].count = currencyCounts[link].count + value;

    return currencyCounts
end

local function CalculateItemCounts(itemCounts, link, texture, value)
    if not link:find("item:") then
        return itemCounts
    end

    if not itemCounts[link] then
        itemCounts[link] = {
            link = link,
            texture = texture,
            count = 0
        };
    end
    itemCounts[link].count = itemCounts[link].count + value;

    return itemCounts
end

local function CalculateOtherCounts(currencyCounts, itemCounts, itemIndex)
    local numCosts = GetMerchantItemCostInfo(itemIndex);
    if numCosts and numCosts > 0 then
        for costIndex = 1, numCosts do
            local texture, value, link = GetMerchantItemCostItem(itemIndex, costIndex);
            if texture and value and link then
                currencyCounts = CalculateCurrencyCounts(currencyCounts, link, texture, value);
                itemCounts = CalculateItemCounts(itemCounts, link, texture, value);
            end
        end
    end
    return currencyCounts, itemCounts
end

local function CalculateCounts()
    local currencyCounts, itemCounts, goldCount = {}, {}, 0;
    for i = 1, #addon.CachedItemIndices do
        goldCount = CalculateGoldCount(goldCount, i);
        currencyCounts, itemCounts = CalculateOtherCounts(currencyCounts, itemCounts, i);
    end
    return goldCount, currencyCounts, itemCounts
end

-- Update / Draw functions
local tokenIndex;
local function DrawGoldToken(goldCount)
    if goldCount <= 0 then
        return
    end

    tokenIndex = tokenIndex + 1;
    local token = GetPoolToken(tokenIndex);
    token:SetGold(goldCount);
    DrawToken(tokenIndex);
end

local function DrawCurrencyToken(texture, value, link)
    tokenIndex = tokenIndex + 1;
    local token = GetPoolToken(tokenIndex);
    token:SetCurrency(texture, value, link);
    DrawToken(tokenIndex);
end

local function DrawItemToken(texture, value, link)
    tokenIndex = tokenIndex + 1;
    local token = GetPoolToken(tokenIndex);
    token:SetItem(texture, value, link);
    DrawToken(tokenIndex);
end

function tokenBanner:Update()
    local goldCount, currencyCounts, itemCounts = CalculateCounts()

    tokenIndex = 0;

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
    local profile = addon.Options.db.profile.TokenBanner;

    local tokenBannerMenu = menuBuilder:CreateSubmenuButton(menuObj, addon.L["Token Banner"]);

	menuBuilder:CreateTitle(tokenBannerMenu, addon.L["Money Options"]);

    local moneyLabel = menuBuilder:CreateSubmenuButton(tokenBannerMenu, addon.L["Money Label"]);
    menuBuilder:CreateRadio(moneyLabel, addon.L["None"], profile, {"MoneyLabel"}, "None");
    menuBuilder:CreateRadio(moneyLabel, addon.L["Text"], profile, {"MoneyLabel"}, "Text");
    menuBuilder:CreateRadio(moneyLabel, addon.L["Icon"], profile, {"MoneyLabel"}, "Icon");
    menuBuilder:AddChildMenu(tokenBannerMenu, moneyLabel);

    local moneyAbbreviate = menuBuilder:CreateSubmenuButton(tokenBannerMenu, addon.L["Money Abbreviate"]);
    menuBuilder:CreateRadio(moneyAbbreviate, addon.L["None"], profile, {"MoneyAbbreviate"}, "None");
    menuBuilder:CreateRadio(moneyAbbreviate, addon.L["1k"], profile, {"MoneyAbbreviate"}, "1k");
    menuBuilder:CreateRadio(moneyAbbreviate, addon.L["1m"], profile, {"MoneyAbbreviate"}, "1m");
    menuBuilder:AddChildMenu(tokenBannerMenu, moneyAbbreviate);

    local thousandsSeparator = menuBuilder:CreateSubmenuButton(tokenBannerMenu, addon.L["Thousands Separator"]);
    menuBuilder:CreateRadio(thousandsSeparator, addon.L["Space"], profile, {"ThousandsSeparator"}, "Space");
    menuBuilder:CreateRadio(thousandsSeparator, addon.L["Period"], profile, {"ThousandsSeparator"}, "Period");
    menuBuilder:CreateRadio(thousandsSeparator, addon.L["Comma"], profile, {"ThousandsSeparator"}, "Comma");
    menuBuilder:AddChildMenu(tokenBannerMenu, thousandsSeparator);

    menuBuilder:CreateCheckbox(tokenBannerMenu, addon.L["Money Gold Only"], profile, {"MoneyGoldOnly"});
    menuBuilder:CreateCheckbox(tokenBannerMenu, addon.L["Money Colored"], profile, {"MoneyColored"});

    menuBuilder:CreateDivider(tokenBannerMenu);
	menuBuilder:CreateTitle(tokenBannerMenu, addon.L["Currency Options"]);

	local currencyAbbreviate = menuBuilder:CreateSubmenuButton(tokenBannerMenu, addon.L["Currency Abbreviate"]);
	menuBuilder:CreateRadio(currencyAbbreviate, addon.L["None"], profile, {"CurrencyAbbreviate"}, "None");
	menuBuilder:CreateRadio(currencyAbbreviate, addon.L["1k"], profile, {"CurrencyAbbreviate"}, "1k");
	menuBuilder:CreateRadio(currencyAbbreviate, addon.L["1m"], profile, {"CurrencyAbbreviate"}, "1m");
	menuBuilder:AddChildMenu(tokenBannerMenu, currencyAbbreviate);

    menuBuilder:AddChildMenu(menuObj, tokenBannerMenu);
end
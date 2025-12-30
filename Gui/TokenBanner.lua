local _, addon = ...;
addon.Gui.TokenBanner = {};
local tokenBanner = addon.Gui.TokenBanner;

local preLoadTokenNum = 5;

local function AppendItemCount(tooltip, itemId)
    if not itemId then
        return;
    end

    local inBag = GetItemCount(itemId);
    local total = GetItemCount(itemId, true, false, true, true);
    local inBank = total - inBag;

    local text = addon.L["Bags:"] .. " " .. inBag;

    if inBank > 0 then
        text = text .. "    " .. addon.L["Bank:"] .. " " .. inBank;
    end

    tooltip:AddLine(text);
    tooltip:Show();
end

-- check this bit of code still
local function SetupTooltip(token)
    token:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        if self.currencyId then
            GameTooltip:SetCurrencyByID(self.currencyId);
        elseif self.itemLink then
            GameTooltip:SetHyperlink(self.itemLink);
            GameTooltip_AddBlankLineToTooltip(GameTooltip);
            local itemId = (select(3, strfind(self.itemLink, "item:(%d+)")));
            AppendItemCount(GameTooltip, tonumber(itemId));
        elseif self.isGold then
            GameTooltip:AddLine("Total Gold Cost");
            GameTooltip:AddLine(" ");
            local gold = math.floor(self.goldAmount / 10000);
            local silver = math.floor((self.goldAmount % 10000) / 100);
            local copper = self.goldAmount % 100;
            if gold > 0 then
                GameTooltip:AddDoubleLine("Gold:", gold .. "|cFFFFD700g|r", 1, 1, 1, 1, 1, 1);
            end
            if silver > 0 then
                GameTooltip:AddDoubleLine("Silver:", silver .. "|cFFC7C7CFs|r", 1, 1, 1, 1, 1, 1);
            end
            if copper > 0 then
                GameTooltip:AddDoubleLine("Copper:", copper .. "|cFFB87333c|r", 1, 1, 1, 1, 1, 1);
            end
        end
        GameTooltip:Show();
    end);

    token:SetScript("OnLeave", function(self)
        GameTooltip:Hide();
    end);
end

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
    local token = CreateFrame("Button", "KrowiEVU_TokenBannerToken" .. index, KrowiEVU_TokenBanner, "BackpackTokenTemplate");
    SetupTooltip(token);
    tokenPool[index] = token;
    return token
end

local function DrawToken(index)
    local button = GetPoolToken(index);
    if index == 1 then
        button:SetPoint("RIGHT", KrowiEVU_TokenBanner, "RIGHT", -10, -2);
    else
        button:SetPoint("RIGHT", _G["KrowiEVU_TokenBannerToken" .. (index - 1)], "LEFT", -4, 0);
    end
    button:Show()
end

function tokenBanner:Load()
    local inset = CreateFrame("Frame", "KrowiEVU_TokenBannerInset", MerchantFrame, "InsetFrameTemplate");
    inset:SetPoint("BOTTOMLEFT", MerchantFrame, "BOTTOMLEFT", 4, 4);
    inset:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -5, 5);
    inset:SetHeight(23);
    inset:SetFrameStrata("HIGH");

    local banner = CreateFrame("Frame", "KrowiEVU_TokenBanner", inset, "ThinGoldEdgeTemplate");
    banner:SetPoint("TOPLEFT", inset, "TOPLEFT", 3, -2);
    banner:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -3, 2);

    for i = 1, preLoadTokenNum do
        DrawToken(i);
    end
    HideAllTokens()
end

-- MerchantFrame_UpdateCurrencies is called before MerchantFrame_Update so we need to do the handling here
hooksecurefunc("MerchantFrame_Update", function()
    addon.Util.DelayFunction("KrowiEVU_TokenBannerUpdate", 0.5, function()
        tokenBanner:Update()
    end);
end);

local function HideBlizzardTokenFrame()
    if MerchantMoneyInset then
        MerchantMoneyInset:Hide();
    end
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

local function HideRemainingTokens(startIndex)
    local numTokens = #tokenPool;
    for i = startIndex, numTokens, 1 do
        tokenPool[i]:Hide();
    end
end

local function CalculateGoldTotal(goldTotal, itemIndex)
    local _, _, price, _, _, _, _, extendedCost = GetMerchantItemInfo(itemIndex);
    if price and price > 0 and not extendedCost then
        goldTotal = goldTotal + price;
    end
    return goldTotal
end

local function CalculateOtherCostTotal(currencyCounts, itemCounts, itemIndex)
    local numCosts = GetMerchantItemCostInfo(itemIndex);
    if numCosts and numCosts > 0 then
        for costIndex = 1, numCosts do
            local texture, value, link, currencyName = GetMerchantItemCostItem(itemIndex, costIndex);
            if texture and value then
                if link then
                    -- It's an item cost - extract name from link
                    local costItemName = link:match("%[(.+)%]") or link;
                    if not itemCounts[costItemName] then
                        itemCounts[costItemName] = {count = 0, link = link, texture = texture};
                    end
                    itemCounts[costItemName].count = itemCounts[costItemName].count + value;
                elseif currencyName and currencyName ~= "" then
                    -- It's a currency cost
                    if not currencyCounts[currencyName] then
                        currencyCounts[currencyName] = {count = 0, texture = texture};
                    end
                    currencyCounts[currencyName].count = currencyCounts[currencyName].count + value;
                end
            end
        end
    end
    return currencyCounts, itemCounts
end

function tokenBanner:Update()
    HideBlizzardTokenFrame()

    local currencyCounts = {};
    local itemCounts = {};
    local goldTotal = 0;
    
    for i = 1, #addon.CachedItemIndices do
        goldTotal = CalculateGoldTotal(goldTotal, i);
        currencyCounts, itemCounts = CalculateOtherCostTotal(currencyCounts, itemCounts, i);
    end
    
    print("Gold Total: "..goldTotal)
    print("Currency Counts:")
    for currencyName, data in pairs(currencyCounts) do
        print(currencyName, data.count)
    end
    print("Item Counts:")
    for itemName, data in pairs(itemCounts) do
        print(itemName, data.count)
    end

    -- Update the currency frame
    if not KrowiEVU_TokenBanner then
        return;
    end
    
    local tokenIndex = 0;
    
    -- Add gold token
    if goldTotal > 0 then
        tokenIndex = tokenIndex + 1;
        local button = GetPoolToken(tokenIndex);
        if button then
            button.Icon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon");
            
            local gold = math.floor(goldTotal / 10000);
            local silver = math.floor((goldTotal % 10000) / 100);
            local copper = goldTotal % 100;
            
            -- Display the most significant value
            if gold > 0 then
                button.Count:SetText(gold);
            elseif silver > 0 then
                button.Count:SetText(silver);
                button.Icon:SetTexture("Interface\\MoneyFrame\\UI-SilverIcon");
            else
                button.Count:SetText(copper);
                button.Icon:SetTexture("Interface\\MoneyFrame\\UI-CopperIcon");
            end
            
            -- Store data for tooltip
            button.isGold = true;
            button.goldAmount = goldTotal;
            button.currencyId = nil;
            button.itemLink = nil;
            
            DrawToken(tokenIndex);
        end
    end
    
    -- Add currency tokens
    for currencyName, data in pairs(currencyCounts) do
        tokenIndex = tokenIndex + 1;
        local button = GetPoolToken(tokenIndex);
        if button then
            button.Icon:SetTexture(data.texture);
            button.Count:SetText(data.count);
            
            -- Store data for tooltip
            button.currencyId = data.currencyId;
            button.isGold = nil;
            button.itemLink = nil;
            
            DrawToken(tokenIndex);
        end
    end
    
    -- Add item tokens
    for itemName, data in pairs(itemCounts) do
        tokenIndex = tokenIndex + 1;
        local button = GetPoolToken(tokenIndex);
        if button then
            button.Icon:SetTexture(data.texture);
            button.Count:SetText(data.count);
            
            -- Store data for tooltip
            button.itemLink = data.link;
            button.isGold = nil;
            button.currencyId = nil;
            
            DrawToken(tokenIndex);
        end
    end

    -- Show/hide frame
    if tokenIndex > 1 then
        KrowiEVU_TokenBanner:Show();
    else
        KrowiEVU_TokenBanner:Hide();
    end

    HideRemainingTokens(tokenIndex + 1)
end
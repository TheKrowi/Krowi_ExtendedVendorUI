local _, addon = ...;

local TEXTURE_SIZE = 14

KrowiEVU_TokenMixin = {};

local function AbbreviateValue(value, abbreviateK, abbreviateM)
	if abbreviateK and value >= 1000 then
		return math.floor(value / 1000), "k";
	elseif abbreviateM and value >= 1000000 then
		return math.floor(value / 1000000), "m";
	end
	return value, "";
end

local function GetSeparators()
	local options = addon.Options.db.profile.TokenBanner;
	if (options.ThousandsSeparator == addon.L["Space"]) then
		return " ", ".";
	elseif (options.ThousandsSeparator == addon.L["Period"]) then
		return ".", ",";
	elseif (options.ThousandsSeparator == addon.L["Comma"]) then
		return ",", ".";
	end
	return "", "";
end

local function BreakMoney(value)
	return math.floor(value / 10000), math.floor((value % 10000) / 100), value % 100;
end

local function NumToString(amount, thousands_separator, decimal_separator)
	if type(amount) ~= "number" then
		return "0";
	end

	if amount > 99999999999999 then
		return tostring(amount);
	end

	local sign, int, frac = tostring(amount):match('([-]?)(%d+)([.]?%d*)');
	int = int:reverse():gsub("(%d%d%d)", "%1|");
	int = int:reverse():gsub("^|", "");
	int = int:gsub("%.", decimal_separator);
	int = int:gsub("|", thousands_separator);

	return sign .. int .. frac;
end

local function FormatMoney(value)
	local options = addon.Options.db.profile.TokenBanner;
	local thousandsSeparator, decimalSeparator = GetSeparators();

	local gold, silver, copper, abbr = BreakMoney(value);

	local moneyAbbreviateK = options.MoneyAbbreviate == addon.L["1k"];
	local moneyAbbreviateM = options.MoneyAbbreviate == addon.L["1m"];
	gold, abbr = AbbreviateValue(gold, moneyAbbreviateK, moneyAbbreviateM);
	gold = NumToString(gold, thousandsSeparator, decimalSeparator);

	local goldLabel, silverLabel, copperLabel = "", "", "";
	if options.MoneyLabel == addon.L["Text"] then
		goldLabel = addon.L["Gold Label"];
		silverLabel = addon.L["Silver Label"];
		copperLabel = addon.L["Copper Label"];
	elseif options.MoneyLabel == addon.L["Icon"] then
		local icon_pre = "|TInterface\\MoneyFrame\\";
		local icon_post = ":" .. TEXTURE_SIZE .. ":" .. TEXTURE_SIZE .. ":2:0|t";
		goldLabel = icon_pre .. "UI-GoldIcon" .. icon_post;
		silverLabel = icon_pre .. "UI-SilverIcon" .. icon_post;
		copperLabel = icon_pre .. "UI-CopperIcon" .. icon_post;
	end

	local colors = options.MoneyColored and {
		coin_gold = "ffd100",
		coin_silver = "e6e6e6",
		coin_copper = "c8602c",
	} or {
        coin_gold = "ffffff",
        coin_silver = "ffffff",
        coin_copper = "ffffff",
    };

	local outstr = "|cff" .. colors.coin_gold .. gold .. abbr .. goldLabel .. "|r";

	if not options.MoneyGoldOnly then
		outstr = outstr .. " " .. "|cff" .. colors.coin_silver .. silver .. silverLabel .. "|r";
		outstr = outstr .. " " .. "|cff" .. colors.coin_copper .. copper .. copperLabel .. "|r";
	end

	return outstr;
end

function KrowiEVU_TokenMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    if self.IsGold then
        GameTooltip:AddLine("Total Gold Cost");
    elseif self.IsCurrency or self.IsItem then
        GameTooltip:SetHyperlink(self.Link);
    end
    GameTooltip_AddBlankLineToTooltip(GameTooltip);
    GameTooltip:AddDoubleLine("Have", self.Have, 1, 1, 1, 1, 1, 1);
    GameTooltip:AddDoubleLine("Need", self.Need, 1, 1, 1, 1, 1, 1);
    GameTooltip:Show();
end

function KrowiEVU_TokenMixin:OnLeave()
    GameTooltip:Hide();
end

-- local function GetMoneySingleValueAndTexture(value)
--     local gold, silver, copper = BreakMoney(value);
--     local texture
--     if gold > 0 then
--         value = gold;
--         texture = "Interface\\MoneyFrame\\UI-GoldIcon";
--     elseif silver > 0 then
--         value = silver;
--         texture = "Interface\\MoneyFrame\\UI-SilverIcon";
--     else
--         value = copper;
--         texture = "Interface\\MoneyFrame\\UI-CopperIcon";
--     end
--     return value, texture;
-- end

function KrowiEVU_TokenMixin:Draw()
    if not self.Need then
        return
    end

    local text = self.Need
    if self.Have then
        text = self.Have .. " / " .. text
    end
    if self.IconTexture then
        text = text .. " |T" .. self.IconTexture .. ":" .. TEXTURE_SIZE .. ":" .. TEXTURE_SIZE .. ":2:0|t";
    end
    self.Text:SetText(text);
    self:SetWidth(self.Text:GetStringWidth());

    self:Show()
end

function KrowiEVU_TokenMixin:SetGold(value)
    self.IsGold = true
    self.IsCurrency = false
    self.IsItem = false

    self.Need, self.IconTexture = FormatMoney(value) -- GetMoneySingleValueAndTexture(value)
    self.Have = FormatMoney(GetMoney()) -- GetMoneySingleValueAndTexture(GetMoney())
end

function KrowiEVU_TokenMixin:SetCurrency(texture, value, link)
    self.IsGold = false
    self.IsCurrency = true
    self.IsItem = false

    self.Need, self.IconTexture = value, texture or "Interface\\Icons\\Inv_Misc_QuestionMark"
    self.Link = link;

    local currencyInfo = C_CurrencyInfo.GetCurrencyInfoFromLink(link);
    if not currencyInfo then
        return
    end

    self.Have = currencyInfo.quantity;
end

function KrowiEVU_TokenMixin:SetItem(texture, value, link)
    self.IsGold = false
    self.IsCurrency = false
    self.IsItem = true

    self.Need, self.IconTexture = value, texture or "Interface\\Icons\\Inv_Misc_QuestionMark"
    self.Link = link;

    local itemId = tonumber(link:match("item:(%d+)"));
    if not itemId then
        return
    end

    self.Have = C_Item.GetItemCount(link, true, false, true, true);
end

function KrowiEVU_TokenMixin:OnShow()
    print("Token shown", self.Have, self.Need);
end
local _, addon = ...

addon.Options.Defaults = {
    profile = {
        ShowMinimapIcon = false,
        NumRows = 5,
        NumColumns = 2,
        Direction = 'Rows',
        Minimap = {
            hide = true -- not ShowMinimapIcon
        },
        ShowOptionsButton = true,
        ShowHideOption = true,
        RememberFilter = false,
        RememberSearch = false,
        RememberSearchBetweenVendors = false,
        BulkPurchase = {
            Enabled = true,
            ShowConfirm = true,
        },
        TokenBanner = {
            MoneyLabel = 'Icon',
            MoneyAbbreviate = 'None',
            ThousandsSeparator = 'Space',
            MoneyGoldOnly = false,
            MoneyColored = true,
	        CurrencyAbbreviate = 'None',
            Format = 'Both',
            GoldTotal = true, -- Off: the gold token shows only the gold the player has
            HideNone = false, -- On: no token for a currency the player has none of (item costs stay)
        }
    }
}
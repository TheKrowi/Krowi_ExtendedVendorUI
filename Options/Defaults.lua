local _, addon = ...;

addon.Options.Defaults = {
    profile = {
        ShowMinimapIcon = false,
        NumRows = 5,
        NumColumns = 2,
        Direction = addon.L["Rows first"],
        Minimap = {
            hide = true -- not ShowMinimapIcon
        },
        ShowOptionsButton = true,
        ShowHideOption = true,
        RememberFilter = false,
        RememberSearch = false,
        RememberSearchBetweenVendors = false,
        TokenBanner = {
            MoneyLabel = addon.L["Icon"],
            MoneyAbbreviate = addon.L["None"],
            ThousandsSeparator = addon.L["Space"],
            MoneyGoldOnly = false,
            MoneyColored = true,
        }
    }
};
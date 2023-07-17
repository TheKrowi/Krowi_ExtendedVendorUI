-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;

options.Defaults = {
    profile = {
        ShowMinimapIcon = false,
        NumRows = 5,
        NumColumns = 2,
        Direction = addon.L["Rows first"],
        Minimap = {
            hide = true -- not ShowMinimapIcon
        },
        AutoJunk = {
            Quality = {
                false, -- Poor
                false, -- Common
                false, -- Uncommon
                true, -- Rare
                true -- Epic
            }
        },
        AutoSell = {
            Quality = {
                false, -- Poor
                false, -- Common
                false, -- Uncommon
                true, -- Rare
                true -- Epic
            },
            ItemLevel = 0,
            Operator = 1,
            PrintChatMessage = true,
            TooltipDetails = 2 -- Basic
        },
        AutoRepair = {
            IsEnabled = true,
            IsGuildEnabled = true,
            PrintChatMessage = true
        },
        Debug = {
            TooltipShowItemInfo = false
        }
    }
};
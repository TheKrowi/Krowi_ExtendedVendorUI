-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.General = {};
local general = options.General;
tinsert(options.OptionsTables, general);

local OrderPP = KrowiMFE_InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = KrowiMFE_InjectOptions.AdjustedWidth;

function general.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.MetaData.Title, options.OptionsTable.args.General);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.MetaData.Title, addon.MetaData.Title, nil);
end

function general.PostLoad()

end

local function MinimapShowMinimapIconSet()
    addon.Options.db.ShowMinimapIcon = not addon.Options.db.ShowMinimapIcon;
    if addon.Options.db.ShowMinimapIcon then
        addon.Icon:Show("Krowi_MerchantFrameExtendedLDB");
    else
        addon.Icon:Hide("Krowi_MerchantFrameExtendedLDB");
    end
end

options.OptionsTable.args["General"] = {
    type = "group", childGroups = "tab",
    name = addon.L["General"],
    args = {
        Info = {
            order = OrderPP(), type = "group",
            name = addon.L["Info"],
            args = {
                General = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["General"],
                    args = {
                        Version = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(), fontSize = "medium",
                            name = (addon.L["Version"] .. ": "):SetColorYellow() .. addon.MetaData.Version,
                        },
                        Build = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(), fontSize = "medium",
                            name = (addon.L["Build"] .. ": "):SetColorYellow() .. addon.MetaData.Build,
                        },
                        Blank1 = {order = OrderPP(), type = "description", width = AdjustedWidth(), name = ""},
                        Author = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(2), fontSize = "medium",
                            name = (addon.L["Author"] .. ": "):SetColorYellow() .. addon.MetaData.Author,
                        },
                        Discord = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["Discord"],
                            desc = addon.L["Discord Desc"]:ReplaceVars(addon.MetaData.DiscordServerName),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.MetaData.DiscordInviteLink); end
                        }
                    }
                },
                Sources = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Sources"],
                    args = {
                        CurseForge = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["CurseForge"],
                            desc = addon.L["CurseForge Desc"]:InjectAddonName_KMFE():ReplaceVars(addon.L["CurseForge"]),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.MetaData.CurseForge); end
                        },
                        Wago = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["Wago"],
                            desc = addon.L["Wago Desc"]:InjectAddonName_KMFE():ReplaceVars(addon.L["Wago"]),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.MetaData.Wago); end
                        },
                        WoWInterface = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["WoWInterface"],
                            desc = addon.L["WoWInterface Desc"]:InjectAddonName_KMFE():ReplaceVars(addon.L["WoWInterface"]),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.MetaData.WoWInterface); end
                        }
                    }
                }
            }
        },
        Icon = {
            order = OrderPP(), type = "group",
            name = addon.L["Icon"],
            args = {
                Minimap = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Minimap"],
                    args = {
                        ShowMinimapIcon = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                            name = addon.L["Show minimap icon"],
                            desc = addon.L["Show minimap icon Desc"]:AddDefaultValueText_KMFE("ShowMinimapIcon"),
                            get = function() return addon.Options.db.ShowMinimapIcon; end,
                            set = MinimapShowMinimapIconSet
                        }
                    }
                }
            }
        },
        Debug = {
            order = OrderPP(), type = "group",
            name = addon.L["Debug"],
            args = {
                Debug = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Debug"],
                    args = {
                        -- Description = {
                        --     order = OrderPP(), type = "description", width = "full", fontSize = "medium",
                        --     name = addon.L["Debug Desc"],
                        -- },
                        -- TooltipShowAutoSellRules = {
                        --     order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                        --     name = addon.L["TooltipShowAutoSellRules"],
                        --     desc = addon.L["TooltipShowAutoSellRules Desc"]:AddDefaultValueText_KMFE("Debug.TooltipShowItemInfo"),
                        --     get = function() return addon.Options.db.Debug.TooltipShowItemInfo; end,
                        --     set = function(_, value) addon.Options.db.Debug.TooltipShowItemInfo = value; end
                        -- },
                        -- Blank1 = {order = OrderPP(), type = "description", width = AdjustedWidth(2), name = ""},
                        -- ScreenshotMode = {
                        --     order = OrderPP(), type = "execute",
                        --     name = addon.L["Screenshot Mode"],
                        --     desc = addon.L["Screenshot Mode Desc"],
                        --     func = HandleScreenshotMode
                        -- },
                        -- AutoSellPrintChatMessage = {
                        --     order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                        --     name = addon.L["AutoSellPrintChatMessage"],
                        --     desc = addon.L["AutoSellPrintChatMessage Desc"]:AddDefaultValueText_KMFE("AutoSell.PrintChatMessage"),
                        --     get = function() return addon.Options.db.AutoSell.PrintChatMessage; end,
                        --     set = function(_, value) addon.Options.db.AutoSell.PrintChatMessage = value; end
                        -- },
                        -- Blank2 = {order = OrderPP(), type = "description", width = AdjustedWidth(), name = ""},
                        -- ExportCriteria = {
                        --     order = OrderPP(), type = "execute",
                        --     name = addon.L["Export Criteria"],
                        --     desc = addon.L["Export Criteria Desc"],
                        --     func = ExportCriteria
                        -- },
                        -- ShowPlaceholdersFilter = {
                        --     order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                        --     name = addon.L["Show placeholders filter"],
                        --     desc = addon.L["Show placeholders filter Desc"]:AddDefaultValueText_KAF("ShowPlaceholdersFilter"),
                        --     get = function() return addon.Options.db.ShowPlaceholdersFilter; end,
                        --     set = function() addon.Options.db.ShowPlaceholdersFilter = not addon.Options.db.ShowPlaceholdersFilter; end
                        -- }
                    }
                }
            }
        }
    }
};
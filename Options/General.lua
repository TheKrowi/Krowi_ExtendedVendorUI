-- [[ Namespaces ]] --
local _, addon = ...;
local options = addon.Options;
options.General = {};
local general = options.General;
tinsert(options.OptionsTables, general);

local OrderPP = addon.InjectOptions.AutoOrderPlusPlus;
local AdjustedWidth = addon.InjectOptions.AdjustedWidth;

function general.RegisterOptionsTable()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addon.Metadata.Title, options.OptionsTable.args.General);
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addon.Metadata.Title, addon.Metadata.Title, nil);
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

local function OptionsButtonShowOptionsButtonSet(_, value)
    addon.Options.db.ShowOptionsButton = value;
    KrowiMFE_OptionsButton:ShowHide();
end

local function OptionsButtonOpenOptionsFunc()
    local menu = KrowiMFE_OptionsButton:BuildMenu();
    menu:Open();
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
                            name = (addon.L["Version"] .. ": "):SetColorYellow() .. addon.Metadata.Version,
                        },
                        Build = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(), fontSize = "medium",
                            name = (addon.L["Build"] .. ": "):SetColorYellow() .. addon.Metadata.Build,
                        },
                        Blank1 = {order = OrderPP(), type = "description", width = AdjustedWidth(), name = ""},
                        Author = {
                            order = OrderPP(), type = "description", width = AdjustedWidth(2), fontSize = "medium",
                            name = (addon.L["Author"] .. ": "):SetColorYellow() .. addon.Metadata.Author,
                        },
                        Discord = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["Discord"],
                            desc = addon.L["Discord Desc"]:K_ReplaceVars(addon.Metadata.DiscordServerName),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.Metadata.DiscordInviteLink); end
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
                            desc = addon.L["CurseForge Desc"]:InjectAddonName_KMFE():K_ReplaceVars(addon.L["CurseForge"]),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.Metadata.CurseForge); end
                        },
                        Wago = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["Wago"],
                            desc = addon.L["Wago Desc"]:InjectAddonName_KMFE():K_ReplaceVars(addon.L["Wago"]),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.Metadata.Wago); end
                        },
                        WoWInterface = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["WoWInterface"],
                            desc = addon.L["WoWInterface Desc"]:InjectAddonName_KMFE():K_ReplaceVars(addon.L["WoWInterface"]),
                            func = function() LibStub("Krowi_PopopDialog-1.0").ShowExternalLink(addon.Metadata.WoWInterface); end
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
        Options = {
            order = OrderPP(), type = "group",
            name = addon.L["Options"],
            args = {
                OptionsButton = {
                    order = OrderPP(), type = "group", inline = true,
                    name = addon.L["Options Button"],
                    args = {
                        ShowOptionsButton = {
                            order = OrderPP(), type = "toggle", width = AdjustedWidth(),
                            name = addon.L["Show options button"],
                            desc = addon.L["Show options button Desc"]:AddDefaultValueText_KMFE("ShowOptionsButton"),
                            get = function() return addon.Options.db.ShowOptionsButton; end,
                            set = OptionsButtonShowOptionsButtonSet
                        },
                        Blank1 = {order = OrderPP(), type = "description", width = AdjustedWidth(), name = ""},
                        OpenOptions = {
                            order = OrderPP(), type = "execute", width = AdjustedWidth(),
                            name = addon.L["Options"],
                            desc = addon.L["Options Desc"],
                            func = OptionsButtonOpenOptionsFunc
                        }
                    }
                },
            }
        }
    }
};
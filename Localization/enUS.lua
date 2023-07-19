-- [[ English texts by Krowi, 2023-07-19 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "enUS", true, true);

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.GlobalStrings.Load(L);

L["Default value"] = "Default value";
L["Checked"] = "Checked";
L["Unchecked"] = "Unchecked";
L["Build"] = "Build";
L["Author"] = "Author";
L["Discord"] = "Discord";
L["Discord Desc"] = "Open a popup dialog with a link to the {serverName} Discord server. Here you can post comments, reports, remarks, ideas or anything else related.";
L["CurseForge"] = "CurseForge";
L["CurseForge Desc"] = "Open a popup dialog with a link to the {addonName} {curseForge} page.";
L["Wago"] = "Wago";
L["Wago Desc"] = "Open a popup dialog with a link to the {addonName} {wago} page.";
L["WoWInterface"] = "WoWInterface";
L["WoWInterface Desc"] = "Open a popup dialog with a link to the {addonName} {woWInterface} page.";
L["Show minimap icon"] = "Show minimap icon";
L["Show minimap icon Desc"] = "Show / hide the minimap icon.";
L["Right click"] = "Right click";
L["Icon Right click"] = "for Options.";
L["Rows first"] = "Rows first";
L["Columns first"] = "Columns first";
L["Rows"] = "Rows";
L["Columns"] = "Columns";
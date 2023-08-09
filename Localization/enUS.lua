-- [[ English texts by Krowi, 2023-07-19 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "enUS", true, true);


local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.GlobalStrings.Load(L);

-- [[ https://legacy.curseforge.com/wow/addons/krowi-merchant-frame-extended/localization ]] --
-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["Are you sure you want to hide the options button?"] = [=[Are you sure you want to hide the options button?
The options button can be shown again via {gameMenu} {arrow} {interface} {arrow} {addOns} {arrow} {addonName} {arrow} {general} {arrow} {options}]=]
L["Author"] = true
L["Build"] = true
L["Checked"] = true
L["Columns"] = true
L["Columns first"] = true
L["CurseForge"] = true
L["CurseForge Desc"] = "Open a popup dialog with a link to the {addonName} {curseForge} page."
L["Default value"] = true
L["Discord"] = true
L["Discord Desc"] = "Open a popup dialog with a link to the {serverName} Discord server. Here you can post comments, reports, remarks, ideas or anything else related."
L["Hide"] = true
L["Icon Right click"] = "for Options."
L["Options button"] = true
L["Options Desc"] = "Open the options that are also available from the options button in the merchant window."
L["Right click"] = true
L["Rows"] = true
L["Rows first"] = true
L["Show minimap icon"] = true
L["Show minimap icon Desc"] = "Show / hide the minimap icon."
L["Show options button"] = true
L["Show options button Desc"] = "Show / hide the options button in the merchant window."
L["Unchecked"] = true
L["Wago"] = true
L["Wago Desc"] = "Open a popup dialog with a link to the {addonName} {wago} page."
L["WoWInterface"] = true
L["WoWInterface Desc"] = "Open a popup dialog with a link to the {addonName} {woWInterface} page."


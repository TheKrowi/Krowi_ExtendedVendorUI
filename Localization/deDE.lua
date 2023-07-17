-- [[ Exported at 2023-05-05 12-08-47 ]] --
-- [[ This code is automatically generated as an export from ]] --
-- [[ an SQLite database and is not meant for manual edit. ]] --

-- [[ German translation by Ta, 2023-04-22 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "deDE");
if not L then return end

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.PluginStrings.deDE.Load(L);
addon.GlobalStrings.Load(L);
addon.Plugins:LoadLocalization(L);



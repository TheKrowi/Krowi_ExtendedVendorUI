-- [[ German translation by Ta, 2023-07-19 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "deDE");
if not L then return end

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.GlobalStrings.Load(L);

-- [[ https://legacy.curseforge.com/wow/addons/krowi-merchant-frame-extended/localization ]] --
-- [[ Everything after this line is automatically generated from CurseForge and is not meant for manual edit - SOURCETOKEN - AUTOGENTOKEN ]] --

L["Author"] = "Autor"
L["Build"] = "Version"
L["Checked"] = "Aktivert"
L["CurseForge"] = true
L["CurseForge Desc"] = "Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {curseForge}."
L["Default value"] = "Vorgabewert (Standard)"
L["Discord"] = true
L["Discord Desc"] = "Öffnet ein Popup-Fenster mit einem Link zum {serverName} Discord-Server. Hier können Sie Kommentare, Berichte, Bemerkungen, Ideen und alles andere posten."
L["Icon Right click"] = "für die Optionen."
L["Right click"] = "Rechts-Klick"
L["Show minimap icon"] = "Zeige Minimap Icon"
L["Show minimap icon Desc"] = "Zeige / Verstecke das Minimap Icon."
L["Unchecked"] = "Nicht aktiviert"
L["Wago"] = true
L["Wago Desc"] = "Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {wago}."
L["WoWInterface"] = true
L["WoWInterface Desc"] = "Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {woWInterface}."


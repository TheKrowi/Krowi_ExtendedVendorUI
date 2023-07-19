-- [[ German translation by Ta, 2023-07-19 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "deDE");
if not L then return end

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.GlobalStrings.Load(L);

L["Default value"] = "Vorgabewert (Standard)";
L["Checked"] = "Aktivert";
L["Unchecked"] = "Nicht aktiviert";
L["Build"] = "Version";
L["Author"] = "Autor";
L["Discord"] = "Discord";
L["Discord Desc"] = "Öffnet ein Popup-Fenster mit einem Link zum {serverName} Discord-Server. Hier können Sie Kommentare, Berichte, Bemerkungen, Ideen und alles andere posten.";
L["CurseForge"] = "CurseForge";
L["CurseForge Desc"] = "Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {curseForge}.";
L["Wago"] = "Wago";
L["Wago Desc"] = "Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {wago}.";
L["WoWInterface"] = "WoWInterface";
L["WoWInterface Desc"] = "Öffnet ein Popup-Fenster mit einem Link zur Seite {addonName} {woWInterface}.";
L["Show minimap icon"] = "Zeige Minimap Icon";
L["Show minimap icon Desc"] = "Zeige / Verstecke das Minimap Icon.";
L["Right click"] = "Rechts-Klick";
L["Icon Right click"] = "für die Optionen.";

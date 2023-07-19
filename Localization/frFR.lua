-- [[ French translation by Astiraïs, 2023-07-19 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "frFR");
if not L then return end

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.GlobalStrings.Load(L);

L["Default value"] = "Valeur par défaut";
L["Checked"] = "Coché";
L["Unchecked"] = "Non coché";
L["Build"] = "Version";
L["Author"] = "Auteur";
L["Discord"] = "Discord";
L["Discord Desc"] = "Ouvre une fenêtre avec un lien vers le serveur Discord {serverName}. Sur ce serveur vous pourrez poster des commentaires, des rapports, des remarques, des idées et toute autre chose.";
L["CurseForge"] = "CurseForge";
L["CurseForge Desc"] = "Ouvre une fenêtre avec un lien vers la page {addonName} {curseForge}.";
L["Wago"] = "Wago";
L["Wago Desc"] = "Ouvre une fenêtre avec un lien vers la page {addonName} {wago}.";
L["WoWInterface"] = "WoWInterface";
L["WoWInterface Desc"] = "Ouvre une fenêtre avec un lien vers la page {addonName} {woWInterface}.";
L["Show minimap icon"] = "Afficher l'icone sur la mini-map";
L["Show minimap icon Desc"] = "Afficher ou masquer l'icône sur la mini-map.";
L["Right click"] = "Clic droit";
L["Icon Right click"] = "pour les options.";

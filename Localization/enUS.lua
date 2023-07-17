-- [[ Exported at 2023-05-05 12-08-47 ]] --
-- [[ This code is automatically generated as an export from ]] --
-- [[ an SQLite database and is not meant for manual edit. ]] --

-- [[ English texts by Krowi, 2023-01-20 ]] --

-- [[ Namespaces ]] --
local addonName, addon = ...;
local L = LibStub(addon.Libs.AceLocale):NewLocale(addonName, "enUS", true, true);

local tab = "|T:1:8|t";
L["TAB"] = tab;

-- Load strings into the localization that are already localized by Blizzard
addon.PluginStrings.enUS.Load(L);
addon.GlobalStrings.Load(L);
addon.Plugins:LoadLocalization(L);


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
L["Auto Sell"] = "Auto Sell";
L["Preset Rules"] = "Preset Rules";
L["Preset Rules Desc"] = "When adding one of the rules below, the rule will be added to the respective rules list.";
L["Account Rules"] = "Account Rules";
L["Character Rules"] = "Character Rules";
L["Add new rule"] = "Add new rule";
L["Add new rule Desc"] = "Add a new rule. These are evaluated as OR. This means that an item will be sold if it applies to at least 1 rule.";
L["Open inventory"] = "Open inventory";
L["Open inventory Desc"] = "Opens your inventory.";
L["Open auto sell list"] = "Open auto sell list";
L["Open auto sell list Desc"] = "Open the auto sell list. Changes made to the rules will be directly visible.";
L["Delete rule"] = "Delete rule";
L["Delete rule Desc"] = "Delete this rule.";
L["Enabled Desc"] = "Enable / disable this rule. Disabled rules are not evaluated.";
L["Invalid Rule"] = "This rule is not valid. Check the errors below.";
L["Item types and sub types"] = "Item types and sub types";
L["No item types"] = "No item types or sub types are defined. This rule will apply to all items.";
L["Item Types are read only"] = "This rule is a preset rule. Item types and sub types are read only. Any changes made to the dropdown lists will be reverted.";
L["Add new item type"] = "Add new item type";
L["Add new item type Desc"] = "Add a new item type with the option to add sub types to this rule. These are evaluated as OR. This means that an item will be sold if it applies to at least 1 item type or sub type.";
L["Conditions"] = "Conditions";
L["No conditions"] = "No conditions are defined. This rule will apply to all items based on the item type and/or sub types (if defined).";
L["Add new condition"] = "Add new condition";
L["Add new condition Desc"] = "Add a new condition to this rule. These are evaluated as AND. This means that an item only will be sold if it applies to all conditions.";
L["Select sub type"] = "Select sub type";
L["Select sub type Desc"] = "When checked, items will be validaded on their type and sub type. This allows for more fine grained control.";
L["Delete type Desc"] = "Delete this type and sub types.";
L["No item type selected"] = "No item type selected. Select an item type or delete it.";
L["At least one item sub type must be selected"] = "At least one item sub type must be selected.";
L["If"] = "If";
L["Delete Condition Desc"] = "Delete this condition and criteria.";
L["Invalid condition"] = "Invalid condition";
L["No criteria type selected"] = "No criteria type selected. Select a criteria or delete it.";
L["No valid criteria type selected"] = "No valid criteria type selected. Select a new one.";
L["No equality operator selected"] = "No equality operator selected. Select one.";
L["No valid equality operator selected"] = "No valid equality operator selected. Select a new one.";
L["No item level value entered"] = "No item level value entered. Enter a number.";
L["ItemLevel is not a valid item level."] = "'{itemLevel}' is not a valid item level.";
L["At least one quality must be selected"] = "At least one quality must be selected.";
L["Auto Repair"] = "Auto Repair";
L["Auto Repair Is Enabled"] = "Repair all items automatically when you visit a vendor that can do it.";
L["Auto Repair Is Guild Enabled"] = "Prefer guild funds to repair, if available.";
L["Auto Repair Print Chat Message"] = "Enable to print auto repair messages in the chat.";
L["Right click"] = "Right click";
L["Icon Right click"] = "for Options.";
L["Rows first"] = "Rows first";
L["Columns first"] = "Columns first";
L["Rows"] = "Rows";
L["Columns"] = "Columns";
L["Ignore List"] = "Ignore List";
L["Auto Sell List"] = "Auto Sell List";
L["Auto Sell List Info"] = "Left-click: sell individual item\nRight-click: ignore item";
L["Sell All Items"] = "Sell All Items";
L["Sell 12 Items"] = "Sell 12 Items";
L["Selling item"] = "[KV] Selling item {item}";
L["x of y items sold"] = "[KV] {x} of {y} items sold";
L["x of y items sold in safe mode"] = "[KV] {x} of {y} items sold in safe mode";
L["Auto Repair No Guild Funds Use Personal"] = "[KV] Not enough guild funds to repair, trying personal funds.";
L["Auto Repair No Personal"] = "[KV] Not enough personal funds to repair.";
L["Auto Repair Repaired"] = "[KV] Repaired {g}g {s}s {c}c.";
L["Junk List"] = "Junk List";
L["Junk"] = "Junk";
L["Artifact Relic"] = "Artifact Relic";
L["Unusable Equipment"] = "Unusable Equipment";


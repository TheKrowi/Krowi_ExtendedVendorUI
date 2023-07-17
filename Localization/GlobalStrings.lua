-- [[ Namespaces ]] --
local _, addon = ...;
addon.GlobalStrings = {};
local globalStrings = addon.GlobalStrings;

function addon.GetInstanceInfoName(journalInstanceId)
    local name = EJ_GetInstanceInfo and (EJ_GetInstanceInfo(journalInstanceId)) or nil;
    if name then
        return name;
    end
    name = addon.L["EJ_GetInstanceInfo" .. journalInstanceId];
    if name then
        return name;
    end
    return journalInstanceId;
end

function addon.GetCategoryInfoTitle(categoryId)
    local title = (GetCategoryInfo(categoryId));
    if title then
        return title;
    end
    title = addon.L["GetCategoryInfo" .. categoryId];
    if title then
        return title;
    end
    return categoryId;
end

function globalStrings.Load(L)
    L["Options"] = GAMEOPTIONS_MENU;
    L["Classic"] = EXPANSION_NAME0;
    L["The Burning Crusade"] = EXPANSION_NAME1;
    L["Wrath of the Lich King"] = EXPANSION_NAME2;
    L["Cataclysm"] = EXPANSION_NAME3;
    L["Mists of Pandaria"] = EXPANSION_NAME4;
    L["Warlords of Draenor"] = EXPANSION_NAME5;
    L["Legion"] = EXPANSION_NAME6;
    L["Battle for Azeroth"] = EXPANSION_NAME7;
    L["Shadowlands"] = EXPANSION_NAME8;
    L["Dragonflight"] = EXPANSION_NAME9;
    L["Item Level"] = STAT_AVERAGE_ITEM_LEVEL;
    L["Soulbound"] = ITEM_SOULBOUND;
    L["Quality"] = QUALITY;
    
    L["Direction"] = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION;
    L["General"] = GENERAL;
    L["Info"] = INFO;
    L["Version"] = GAME_VERSION_LABEL;
    L["Sources"] = SOURCES;
    L["Icon"] = EMBLEM_SYMBOL;
    L["Minimap"] = MINIMAP_LABEL;
    L["Name"] = NAME;
    L["Delete"] = DELETE;
    L["Enabled"] = VIDEO_OPTIONS_ENABLED;
    L["Quality"] = QUALITY;
    L["Quality"] = QUALITY;
    L["Quality"] = QUALITY;
    

    SOURCES = "Sources";
end
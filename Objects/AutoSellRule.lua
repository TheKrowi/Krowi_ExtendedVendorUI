-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.AutoSellRule = {};
local autoSellRule = objects.AutoSellRule;
autoSellRule.TooltipDetails = {};
local tooltipDetails = autoSellRule.TooltipDetails;
local criteriaType = addon.Objects.CriteriaType;

tooltipDetails.List = {
    addon.L["None"],
    addon.L["Basic"],
    addon.L["Rules"],
    addon.L["Detailed"]
};

tooltipDetails.Enum = addon.Util.Enum2{
    "None",
    "Basic",
    "Rules",
    "Detailed"
};

-- We can't work with instances because we need to save the rules to the SavedVariables
-- and don't want to pollute the object with references to functions

do -- [[ Creation and modification ]]
    function autoSellRule.CreateNewRule(rulesTable, guid, name)
        local unique = time() + random(time());
        local newRule = {
            Guid = guid or ("Rule-" .. unique),
            Name = name or ("Rule " .. unique),
        };
        for _, rule in next, rulesTable do -- Prevent identical rules
            if newRule.Guid == rule.Guid then
                return rule, false;
            end
        end
        tinsert(rulesTable, newRule);
        return newRule, true;
    end

    function autoSellRule.MakeQuickItemTypes(rule)
        rule.QuickItemTypes = {};
        for _, _itemType in next, rule.ItemTypes do
            if not _itemType.IsInvalid then
                rule.QuickItemTypes[_itemType.Type] = rule.QuickItemTypes[_itemType.Type] or (_itemType.SubTypes and {} or true);
                if _itemType.SubTypes then
                    for itemSubTypeId, _ in next, _itemType.SubTypes do
                        rule.QuickItemTypes[_itemType.Type][itemSubTypeId] = true;
                    end
                end
            end
        end
    end

    function autoSellRule.SetSubItemType(itemType, index, value)
        itemType.NumSelectedSubTypes = (itemType.NumSelectedSubTypes or 0) + (value and 1 or -1);
        itemType.SubTypes = itemType.SubTypes or {};
        itemType.SubTypes[index] = value;
    end

    function autoSellRule.SetItemType(itemType, value)
        itemType.Type = value;
    end

    function autoSellRule.AddNewItemType(rule, value)
        local unique = time() + random(time());
        local itemType = {
            Guid = "ItemType-" .. unique
        };
        if value then
            autoSellRule.SetItemType(itemType, value);
        end
        rule.ItemTypes = rule.ItemTypes or {};
        tinsert(rule.ItemTypes, itemType);
        return itemType;
    end

    local function ShowAlert(message)
        StaticPopupDialogs["KROWIV_ALERT"] = {
            text = message,
            button1 = OKAY,
            hideOnEscape = true,
            timeout = 0,
            exclusive = true,
            whileDead = true,
        }
        StaticPopup_Show("KROWIV_ALERT")
    end

    function autoSellRule.SetItemLevel(condition, value)
        if strtrim(value) == "" then
            condition.Value = 0;
        elseif tonumber(value) == nil then
            ShowAlert(addon.L["ItemLevel is not a valid item level."]:ReplaceVars(value));
        else
            condition.Value = tonumber(value);
        end
    end

    function autoSellRule.SetQuality(condition, index, value)
        condition.NumSelectedQualities = (condition.NumSelectedQualities or 0) + (value and 1 or -1);
        condition.Qualities = condition.Qualities or {};
        condition.Qualities[index] = value;
    end

    function autoSellRule.SetInventoryType(condition, index, value)
        condition.NumSelectedInventoryTypes = (condition.NumSelectedInventoryTypes or 0) + (value and 1 or -1);
        condition.InventoryTypes = condition.InventoryTypes or {};
        condition.InventoryTypes[index] = value;
    end

    function autoSellRule.SetCriteriaType(condition, value)
        condition.CriteriaType = value;
        if value == criteriaType.Enum.Soulbound or value == criteriaType.Enum.Quality or value == criteriaType.Enum.InventoryType then
            condition.Operator = nil;
            condition.Value = nil;
        end
        if value == criteriaType.Enum.ItemLevel or value == criteriaType.Enum.Soulbound or value == criteriaType.Enum.InventoryType then
            condition.Qualities = nil;
            condition.NumSelectedQualities = nil;
        end
        if value == criteriaType.Enum.ItemLevel or value == criteriaType.Enum.Soulbound or value == criteriaType.Enum.Quality then
            condition.InventoryTypes = nil;
            condition.NumSelectedInventoryTypes = nil;
        end
    end

    function autoSellRule.AddNewCondition(rule, value)
        local unique = time() + random(time());
        local condition = {
            Guid = "Condition-" .. unique,
        };
        if value then
            autoSellRule.SetCriteriaType(condition, value);
        end
        rule.Conditions = rule.Conditions or {};
        tinsert(rule.Conditions, condition);
        return condition;
    end
end

do -- [[ Validation ]]
    local function CheckIfItemTypesAreInvalid(itemTypes)
        if not itemTypes then
            return;
        end
        for _, itemType in next, itemTypes do
            if itemType.IsInvalid then
                return true;
            end
        end
    end

    local function CheckIfConditionsAreInvalid(conditions)
        if not conditions then
            return;
        end
        for _, condition in next, conditions do
            if condition.IsInvalid then
                return true;
            end
        end
    end

    function autoSellRule.CheckIfRuleIsInvalid(rule)
        local isInvalid = CheckIfItemTypesAreInvalid(rule.ItemTypes);
        if not isInvalid then
            isInvalid = CheckIfConditionsAreInvalid(rule.Conditions);
        end
        rule.IsInvalid = isInvalid and true or nil; -- Force to nil if false
    end

    function autoSellRule.CheckIfItemTypeIsInvalid(itemType)
        local isInvalid = not itemType.Type or (itemType.SubTypes and itemType.NumSelectedSubTypes == 0);
        itemType.IsInvalid = isInvalid and true or nil; -- Force to nil if false
    end

    function autoSellRule.CheckIfConditionIsInalid(condition)
        local isValid, description = criteriaType.CheckIfValid(condition);
        condition.IsInvalid = not isValid and true or nil; -- Force to nil if false
        return description;
    end
end
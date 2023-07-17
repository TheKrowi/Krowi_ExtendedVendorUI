-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.ItemType = {};
local itemType = objects.ItemType;

-- itemType.List = tInvert(Enum.ItemClass);
local obsoleteIds = {5, 6, 10, 11, 14};
-- for _, id in next, obsoleteIds do
--     itemType.List[id] = nil;
-- end
-- for id, _ in next, itemType.List do
--     itemType.List[id] = GetItemClassInfo(id);
-- end

-- itemType.WeaponList = tInvert(Enum.ItemWeaponSubclass);
-- for id, _ in next, itemType.WeaponList do
--     itemType.WeaponList[id] = (GetItemSubClassInfo(Enum.ItemClass.Weapon, id));
-- end

function itemType.HasSubTypes(type)

end

function itemType.Load()
    itemType.List = {};
    itemType.SubTypeList = {};
    -- KrowiV_Test = {};
    local type, subType;
    local i = 0;
    repeat
        type = GetItemClassInfo(i);
        if type then
            -- KrowiV_Test[type] = {};
            itemType.List[i] = type;
        end
        local j = 0;
        repeat
            subType = GetItemSubClassInfo(i, j);
            if subType == "" then
                subType = nil;
            end
            if subType then
                -- KrowiV_Test[type].SubTypes = KrowiV_Test[type].SubTypes or {};
                -- KrowiV_Test[type].SubTypes[j] = subType;
                itemType.SubTypeList[i] = itemType.SubTypeList[i] or {};
                itemType.SubTypeList[i][j] = subType;
            end
            j = j + 1;
        until subType == nil or j > 100;
        i = i + 1;
        for _, value in pairs(obsoleteIds) do
            if i == value then
                i = i + 1;
            end
        end
    until type == nil or i > 100;
    -- KrowiV_Test2 = itemType.List;
    -- KrowiV_Test3 = itemType.SubTypeList;
end
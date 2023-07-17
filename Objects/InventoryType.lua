-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.InventoryType = {};
local inventoryType = objects.InventoryType;

inventoryType.List = tInvert(Enum.InventoryType);
-- local obsoleteIds = {5, 6, 10, 11, 13, 14};
-- for _, id in next, obsoleteIds do
--     itemType.List[id] = nil;
-- end
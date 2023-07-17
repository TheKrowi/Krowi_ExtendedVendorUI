-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.ItemQuality = {};
local itemQuality = objects.ItemQuality;

itemQuality.List = tInvert(Enum.ItemQuality);
-- local obsoleteIds = {5, 6, 10, 11, 13, 14};
-- for _, id in next, obsoleteIds do
--     itemType.List[id] = nil;
-- end
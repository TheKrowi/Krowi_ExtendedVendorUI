-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;

objects.InstanceType = addon.Util.Enum2{
    "Dungeon",
    "Raid"
};
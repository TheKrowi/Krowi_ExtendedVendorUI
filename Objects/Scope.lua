-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;

objects.ScopeList = {
    "Account",
    "Character"
};

objects.Scope = addon.Util.Enum2(objects.ScopeList);
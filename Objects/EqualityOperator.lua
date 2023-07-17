-- [[ Namespaces ]] --
local _, addon = ...;
local objects = addon.Objects;
objects.EqualityOperator = {};
local equalityOperator = objects.EqualityOperator;

equalityOperator.List = {
    "<",
    "<=",
    "==",
    ">=",
    ">"
};

equalityOperator.Enum = addon.Util.Enum2{
    "LessThan",
    "LessThanOrEqualTo",
    "EqualTo",
    "GreaterThanOrEqualTo",
    "GreaterThan"
};

equalityOperator.Func = {
    function(a, b) return a < b; end,
    function(a, b) return a <= b; end,
    function(a, b) return a == b; end,
    function(a, b) return a >= b; end,
    function(a, b) return a > b; end,
}
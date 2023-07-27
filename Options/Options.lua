-- [[ Namespaces ]] --
local _, addon = ...;
addon.Options = addon.Util.Options:New("KrowiMFE_Options", addon.Metadata.Title, addon.InjectOptions); -- Will be overwritten in Load (intended)
local options = addon.Options;

string.KMFE_InjectAddonName = function(str)
    return str:K_ReplaceVars{addonName = addon.Metadata.Title};
end

string.KMFE_AddDefaultValueText = function(str, valuePath, values)
    return str:K_AddDefaultValueText(options.Defaults.profile, valuePath, values);
end
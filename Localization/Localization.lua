local addonName, addon = ...
addon.Localization = {}
local localization = addon.Localization

function localization.GetDefaultLocale()
    return LibStub(addon.Libs.AceLocale):NewLocale(addonName, 'enUS', true, true)
end

function localization.GetLocale(locale)
    return LibStub(addon.Libs.AceLocale):NewLocale(addonName, locale)
end
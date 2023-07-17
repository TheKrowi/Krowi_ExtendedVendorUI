-- [[ Namespaces ]] --
local addonName, addon = ...;

-- [[ Version data ]] --
local version = (GetBuildInfo());
local major = string.match(version, "(%d+)%.(%d+)%.(%d+)(%w?)");
addon.IsWrathClassic = major == "3";
addon.IsDragonflightRetail = major == "10";

-- [[ Ace ]] --
addon.L = LibStub(addon.Libs.AceLocale):GetLocale(addonName);

print(addon.MetaData.Title, "loaded");

if MerchantFrame then
    print("already loaded")
end

-- [[ Load addon ]] --
local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("ADDON_LOADED");
loadHelper:RegisterEvent("MERCHANT_UPDATE");
loadHelper:RegisterEvent("GUILDBANK_UPDATE_MONEY");
loadHelper:RegisterEvent("HEIRLOOMS_UPDATED");
loadHelper:RegisterEvent("BAG_UPDATE");
loadHelper:RegisterEvent("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL");
loadHelper:RegisterEvent("MERCHANT_SHOW");

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == "Krowi_MerchantFrameExtended" then -- This always needs to load
            KrowiMFE_InjectOptions:SetOptionsTable(addon.Options.OptionsTable);
            KrowiMFE_InjectOptions:SetOptions(addon.Options.Defaults.profile);

            -- addon.Data.AutoJunk.Load();

            -- addon.Objects.ItemType.Load();

            addon.Options.Load(); -- Needs ItemType

            -- KrowiV_SavedData = KrowiV_SavedData or {};
            -- KrowiV_SavedData.IgnoredItems = KrowiV_SavedData.IgnoredItems or {};
            -- KrowiV_SavedData.JunkItems = KrowiV_SavedData.JunkItems or {};
            -- addon.GUI.ItemListFrame.JunkList.Init(true);
            -- addon.GUI.ItemListFrame.IgnoreList.Init(true);

            addon.GUI.MerchantFrame:Load();

            addon.Icon.Load();

            -- addon.GUI.ItemTooltip.Load();
        end
    elseif event == "MERCHANT_UPDATE" then
        -- print("MERCHANT_UPDATE");
    elseif event == "GUILDBANK_UPDATE_MONEY" then
    --     print("GUILDBANK_UPDATE_MONEY");
    elseif event == "HEIRLOOMS_UPDATED" then
    --     print("HEIRLOOMS_UPDATED");
    elseif event == "BAG_UPDATE" then
        -- print("BAG_UPDATE");
    elseif event == "MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL" then
    --     print("MERCHANT_CONFIRM_TRADE_TIMER_REMOVAL");
    elseif event == "MERCHANT_SHOW" then
    --     print("MERCHANT_SHOW");
    end
end
loadHelper:SetScript("OnEvent", loadHelper.OnEvent);
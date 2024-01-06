-- [[ Namespaces ]] --
local addonName, addon = ...;

-- [[ Version data ]] --
local version = (GetBuildInfo());
local major = string.match(version, "(%d+)%.(%d+)%.(%d+)(%w?)");
addon.IsWrathClassic = major == "3";
addon.IsDragonflightRetail = major == "10";

-- [[ Ace ]] --
addon.L = LibStub(addon.Libs.AceLocale):GetLocale(addonName);

-- [[ Load addon ]] --
local loadHelper = CreateFrame("Frame");
loadHelper:RegisterEvent("ADDON_LOADED");

function loadHelper:OnEvent(event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then -- This always needs to load
            addon.Plugins:InjectOptions();
            addon.Options:Load(true);

            addon.Plugins:Load();

            addon.Gui.MerchantItemsContainer:LoadMaxNumItemSlots();

            addon.Icon:Load();

            addon.Api.Load();

            -- local frame = CreateFrame("Frame", "Test", UIParent, "KrowiV_SingleItemListFrame_Template");
            -- -- frame:SetResizable(true);
            -- -- frame:SetScript("OnDragStart", function(self) self:StartSizing() end);
            -- -- frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end);
            -- frame:SetSize(250,250);
            -- frame:SetPoint("CENTER");
            -- frame:Show();
        end
    end
end
loadHelper:SetScript("OnEvent", loadHelper.OnEvent);
-- [[ Namespaces ]] --
local _, addon = ...
if addon.NotLoaded then return end

addon.Gui.BulkPurchase = {}
local bulkPurchase = addon.Gui.BulkPurchase

function bulkPurchase:Load()
    MerchantFrame:HookScript('OnHide', function()
        KrowiEVU_BulkPurchaseFrame:Hide()
    end)
end
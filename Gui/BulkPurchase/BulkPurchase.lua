-- [[ Namespaces ]] --
local _, addon = ...

addon.Gui.BulkPurchase = {}
local bulkPurchase = addon.Gui.BulkPurchase

function bulkPurchase:Load()
    MerchantFrame:HookScript('OnHide', function()
        KrowiEVU_BulkPurchaseFrame:Hide()
    end)
end
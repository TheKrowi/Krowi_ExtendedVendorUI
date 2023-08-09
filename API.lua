-- [[ Namespaces ]] --
local _, addon = ...;
addon.Api = {};
local api = addon.Api;

function api.Load()
	KrowiMFE_MerchantItemsContainer = addon.Gui.MerchantItemsContainer;
end
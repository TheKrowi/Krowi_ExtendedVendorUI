local _, addon = ...
local elv = {}
local pluginName = 'ElvUI'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, elv)

local function IsLoaded()
    return ElvUI ~= nil
end

local doSkin, engine, skins
local isModern = addon.Util.IsMainline
local hasCurrencyIconSkin = not isModern and not addon.Util.IsMistsClassic -- ElvUI's TBC and Classic (Era) merchant skins

-- ElvUI's skins for MerchantItemN (ElvUI/Game/<client>/Modules/Skins/Merchant.lua) only reach Blizzard's slots, so the addon's slots get the same steps here
local function QuestIcon_SetTexture(iconQuest, texture)
	if texture == TEXTURE_ITEM_QUEST_BANG then
		iconQuest:SetTexture(engine.Media.Textures.BagQuestIcon)
	end
end

-- Mainline Merchant.lua:100-131
local function SkinModernItemSlot(item)
	local itemName = item:GetName()
	item:Size(155, 45)
	item:StripTextures(true)
	item:CreateBackdrop('Transparent')
	item.backdrop:Point('TOPLEFT', -3, 2)
	item.backdrop:Point('BOTTOMRIGHT', 2, -3)

	local slot = _G[itemName .. 'SlotTexture']
	item.Name:Point('LEFT', slot, 'RIGHT', -5, 5)
	item.Name:Size(110, 30)

	local button = _G[itemName .. 'ItemButton']
	button:StripTextures()
	button:StyleButton()
	button:SetTemplate(nil, true)
	button:Point('TOPLEFT', item, 'TOPLEFT', 4, -4)

	local icon = button.icon
	icon:SetTexCoords()
	icon:ClearAllPoints()
	icon:Point('TOPLEFT', 1, -1)
	icon:Point('BOTTOMRIGHT', -1, 1)

	local questIcon = button.IconQuestTexture
	questIcon:SetTexCoord(0, 1, 0, 1)
	questIcon:SetInside()

	hooksecurefunc(questIcon, 'SetTexture', QuestIcon_SetTexture)

	skins:HandleIconBorder(button.IconBorder)
end

-- Mists, TBC and Classic Merchant.lua:33-62, plus the alternate currency icons of the TBC and Classic skins
local function SkinClassicItemSlot(item)
	local itemName = item:GetName()
	local button = _G[itemName .. 'ItemButton']
	local icon = _G[itemName .. 'ItemButtonIconTexture']
	local money = _G[itemName .. 'MoneyFrame']
	local nameFrame = _G[itemName .. 'NameFrame']
	local name = _G[itemName .. 'Name']
	local slot = _G[itemName .. 'SlotTexture']

	item:StripTextures(true)
	item:CreateBackdrop('Transparent')
	item.backdrop:Point('TOPLEFT', -1, 3)
	item.backdrop:Point('BOTTOMRIGHT', 2, -3)

	button:StripTextures()
	button:StyleButton()
	button:SetTemplate(nil, true)
	button:Size(40)
	button:Point('TOPLEFT', item, 'TOPLEFT', 4, -2)

	icon:SetTexCoords()
	icon:SetInside()

	nameFrame:Point('LEFT', slot, 'RIGHT', -6, -17)

	name:Point('LEFT', slot, 'RIGHT', -4, 5)

	money:ClearAllPoints()
	money:Point('BOTTOMLEFT', button, 'BOTTOMRIGHT', 3, 0)

	if hasCurrencyIconSkin then
		for j = 1, 2 do
			local currencyItem = _G[itemName .. 'AltCurrencyFrameItem' .. j]
			local currencyIcon = _G[itemName .. 'AltCurrencyFrameItem' .. j .. 'Texture']

			currencyIcon.backdrop = CreateFrame('Frame', nil, currencyItem)
			currencyIcon.backdrop:SetTemplate()
			currencyIcon.backdrop:OffsetFrameLevel(nil, currencyItem)
			currencyIcon.backdrop:SetOutside(currencyIcon)

			currencyIcon:SetTexCoords()
			currencyIcon:SetParent(currencyIcon.backdrop)
		end
	end
end

-- Mainline Merchant.lua:39-56, run after each draw since drawing anchors the prices again
local function PlaceModernPrices(item)
	local itemName = item:GetName()
	local button = _G[itemName .. 'ItemButton']

	local money = _G[itemName .. 'MoneyFrame']
	money:ClearAllPoints()
	money:Point('BOTTOMLEFT', button, 'BOTTOMRIGHT', 5, -3)

	local currency = _G[itemName .. 'AltCurrencyFrame']
	currency:ClearAllPoints()

	if button.price and button.extendedCost then
		currency:Point('LEFT', money, 'RIGHT', -8, 0)
	else
		currency:Point('BOTTOMLEFT', button, 'BOTTOMRIGHT', 5, -3)
	end
end

-- Mists Merchant.lua:128-153 (the same in TBC and Classic), for every slot instead of MerchantItem1-12
local function ColorClassicItemSlot(item)
	local itemName = item:GetName()
	local button = _G[itemName .. 'ItemButton']
	local name = _G[itemName .. 'Name']

	if button.link then
		local quality = C_Item.GetItemQualityByID(button.link)
		if quality and quality > 1 then
			local r, g, b = engine:GetItemQualityColor(quality)
			button:SetBackdropBorderColor(r, g, b)
			name:SetTextColor(r, g, b)
		else
			button:SetBackdropBorderColor(unpack(engine.media.bordercolor))
			name:SetTextColor(1, 1, 1)
		end
	else
		button:SetBackdropBorderColor(unpack(engine.media.bordercolor))
		name:SetTextColor(1, 1, 1)
	end
end

-- Mainline Merchant.lua:166-169; Mists Merchant.lua:66-75, TBC and Classic Merchant.lua:84-93
local function SkinPageControls()
	local prevButton, nextButton, pageText = KrowiEVU_MerchantPrevPageButton, KrowiEVU_MerchantNextPageButton, KrowiEVU_MerchantPageText
	if isModern then
		skins:HandleNextPrevButton(nextButton, nil, nil, true, true)
		skins:HandleNextPrevButton(prevButton, nil, nil, true, true)
		nextButton:ClearAllPoints()
		nextButton:Point('LEFT', pageText, 'RIGHT', 100, 4)
	else
		pageText:SetTextColor(1, 1, 1)
		pageText:Point('BOTTOM', -2, 10)

		skins:HandleNextPrevButton(nextButton, nil, nil, nil, true)
		nextButton:Point('BOTTOMRIGHT', MerchantFrame, 'BOTTOMRIGHT', -11, 10)
		nextButton:Size(24)

		skins:HandleNextPrevButton(prevButton, nil, nil, nil, true)
		prevButton:Point('TOPLEFT', nextButton, 'TOPLEFT', -30, 0)
		prevButton:Size(24)
	end
end

-- ElvUI skins at PLAYER_LOGIN, after this addon loads, so the page controls and the buyback fix wait for the first merchant window
local initialized
local function OnFirstShow()
	if initialized then
		return
	end
	initialized = true

	SkinPageControls()

	if not isModern then
		-- ElvUI's Classic buyback hook moves MerchantItem1-12 with PointXY (MerchantItemPoint); this hook comes after it and puts them back
		hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function()
			addon.Gui.MerchantItemsContainer:PlaceBuybackItemSlots()
		end)
	end
end

local function AddInfo(localizationName, getFunction, hidden)
    return {
        order = KrowiEVU.UtilApi.InjectOptions.AutoOrderPlusPlus(), type = 'toggle', width = 'full',
        name = addon.L[L_Prefix .. localizationName],
        desc = addon.L[L_Prefix .. localizationName .. '_Desc'],
        descStyle = 'inline',
        get = getFunction,
        disabled = true,
        hidden = hidden
    }
end

function elv:InjectOptions()
    local pluginTable = KrowiEVU.UtilApi.InjectOptions:AddPluginTable(
        'ElvUI',
        addon.L[L_Prefix .. 'Name'],
        addon.L[L_Prefix .. 'Desc'],
        function()
            return IsLoaded()
        end
    )
    KrowiEVU.UtilApi.InjectOptions:AddTable(pluginTable, 'SkinMerchant', AddInfo('SkinMerchant', function() return doSkin.Merchant end))
    KrowiEVU.UtilApi.InjectOptions:AddTable(pluginTable, 'SkinMiscFrames', AddInfo('SkinMiscFrames', function() return doSkin.MiscFrames end))
    KrowiEVU.UtilApi.InjectOptions:AddTable(pluginTable, 'SkinTooltip', AddInfo('SkinTooltip', function() return doSkin.Tooltip end))

end

-- function elv:LoadLocalization(L)
--     L['ElvUI Skin Merchant'] = 'Skin Merchant'
--     L['ElvUI Skin Merchant Desc'] = [=[Applies the ElvUI skin to the Merchant Frame.
-- -> Blizzard + Merchant Frame]=]
--     L['ElvUI Skin Misc Frames'] = 'Skin Misc Frames'
--     L['ElvUI Skin Misc Frames Desc'] = [=[Applies the ElvUI skin to the Filter Menu, Right Click Menu and Popup Dialog.
-- -> Blizzard + Misc Frames]=]
--     L['ElvUI Skin Tooltip'] = 'Skin Tooltip'
--     L['ElvUI Skin Tooltip Desc'] = [=[Applies the ElvUI skin to the Tooltips.
-- -> Blizzard + Tooltip]=]
-- end

function elv:Load()
    doSkin = {}

    if not IsLoaded() then
        return
    end

    engine = unpack(ElvUI)
    skins = engine:GetModule('Skins')
    local privateSkins = engine.private.skins
    local blizzardSkins = privateSkins.blizzard

    doSkin.Merchant = blizzardSkins.enable and blizzardSkins.merchant
    doSkin.MiscFrames = blizzardSkins.enable and blizzardSkins.misc
    doSkin.Tooltip = blizzardSkins.enable and blizzardSkins.tooltip

    if not doSkin.Merchant then
        return
    end

    MerchantFrame:HookScript('OnShow', OnFirstShow)

    hooksecurefunc(addon.Gui.FilterButton, 'Load', function()
        skins:HandleDropDownBox(KrowiEVU_FilterButton)
    end)

    hooksecurefunc(addon.Gui.SearchBox, 'Load', function()
        skins:HandleEditBox(KrowiEVU_SearchBox)
        KrowiEVU_SearchBox:SetHeight(22)
        addon.Gui.SearchBox:SetPointOffsetXY(nil, 0)
    end)

    if not isModern then
        hooksecurefunc(addon.Gui.OptionsButton, 'Load', function()
            skins:HandleButton(KrowiEVU_OptionsButton)
        end)
    end

    hooksecurefunc('MerchantFrame_Update', function()
        addon.Gui.MerchantFrame.UpdateRepairButtons()
    end)

    KrowiEVU_MerchantButtonsInset:StripTextures()
    KrowiEVU_MerchantButtonsInset:CreateBackdrop('Transparent')
	KrowiEVU_MerchantButtonsInset.backdrop:Point('TOPLEFT', 2, -2)
	KrowiEVU_MerchantButtonsInset.backdrop:Point('BOTTOMRIGHT', -2, 2)
    KrowiEVU_MerchantBuybackInset:StripTextures()
    KrowiEVU_MerchantEmptyInset:StripTextures()

    hooksecurefunc(addon.Gui.TokenBanner, 'Load', function()
        KrowiEVU_TokenBanner:StripTextures()
        KrowiEVU_TokenBanner:CreateBackdrop('Transparent')
    end)
end

function elv:OnItemSlotCreated(item)
    if not (doSkin and doSkin.Merchant) then
        return
    end
    if isModern then
        SkinModernItemSlot(item)
    else
        SkinClassicItemSlot(item)
    end
end

function elv:OnItemSlotUpdated(item, index)
    if not (doSkin and doSkin.Merchant) then
        return
    end
    if isModern then
        PlaceModernPrices(item)
    elseif index then
        ColorClassicItemSlot(item)
    end
end
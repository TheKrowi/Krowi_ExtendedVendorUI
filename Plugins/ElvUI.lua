local _, addon = ...
if addon.Util.IsForever then
    return -- Skins on WoW Forever are not supported yet: the grid stays unskinned there (Krowi, 2026-10-21)
end
local elv = {}
local pluginName = 'ElvUI'
local L_Prefix = 'Plugin_' .. pluginName .. '_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, elv)

local function IsLoaded()
    return ElvUI ~= nil
end

local doSkin, engine, skins
local isModern = addon.Util.IsMainline

-- This addon's own ElvUI slot skin for Classic, as in 22.2, applied when a slot is created. 22.2's Retail skin is gone:
-- ElvSkinItemSlot below repeats every step of it.
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
end

-- ElvUI v16's merchant skin (ElvUI/Game/Shared/Skins/Merchant.lua, one file for every client) skins MerchantItem1 up to
-- MERCHANT_ITEMS_PER_PAGE on each merchant update, on top of the skin above; until 22.2 that included this addon's slots.
-- The same steps, in the same order: on the first draw of each slot, after the skin above.
local QUEST_ICON = [[Interface\ContainerFrame\UI-Icon-QuestBang]] -- Merchant.lua:14

local function ElvQuestIcon_SetTexture(iconQuest, texture)
	if texture == QUEST_ICON then
		iconQuest:SetTexture(engine.Media.Textures.BagQuestIcon)
	end
end

-- Merchant.lua:70-114 (HandleMerchantItem)
local elvSkinned = setmetatable({}, { __mode = 'k' })
local function ElvSkinItemSlot(item)
	if elvSkinned[item] then
		return
	end
	elvSkinned[item] = true

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

	if isModern then -- engine.Modern in ElvUI v16, missing before it
		local questIcon = button.IconQuestTexture
		questIcon:SetTexCoord(0, 1, 0, 1)
		questIcon:SetInside()

		hooksecurefunc(questIcon, 'SetTexture', ElvQuestIcon_SetTexture)
	end

	button.IconOverlay:SetInside(button, 1, 1) -- Decor items

	skins:HandleIconBorder(button.IconBorder)

	for j = 1, MAX_ITEM_COST do
		_G[itemName .. 'AltCurrencyFrameItem' .. j .. 'Texture']:SetTexCoords()
	end
end

-- Merchant.lua:47-57
local function SetQualityColor(button, name, link)
	local quality = link and C_Item.GetItemQualityByID(link)
	if quality and quality > 1 then
		local r, g, b = engine:GetItemQualityColor(quality)
		button:SetBackdropBorderColor(r, g, b)
		name:SetTextColor(r, g, b)
	else
		button:SetBackdropBorderColor(unpack(engine.media.bordercolor))
		name:SetTextColor(1, 1, 1)
	end
end

-- Merchant.lua:133-154 for one slot, after each draw since drawing anchors the prices again
local function UpdateItemSlot(item, index)
	local itemName = item:GetName()
	local button = _G[itemName .. 'ItemButton']

	if not isModern and index then -- Classic merchants have no quality borders; only filled slots
		SetQualityColor(button, _G[itemName .. 'Name'], button.link)
	end

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

-- Merchant.lua:228-231
local function SkinPageControls()
	skins:HandleNextPrevButton(KrowiEVU_MerchantNextPageButton, nil, nil, true, true)
	skins:HandleNextPrevButton(KrowiEVU_MerchantPrevPageButton, nil, nil, true, true)
	KrowiEVU_MerchantNextPageButton:ClearAllPoints()
	KrowiEVU_MerchantNextPageButton:Point('LEFT', KrowiEVU_MerchantPageText, 'RIGHT', 100, 4)
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

-- ElvUI skins at PLAYER_LOGIN, after this addon loads, so the page controls and the buyback fix wait for the first draw
function elv:OnFirstDraw()
    if not (doSkin and doSkin.Merchant) then
        return
    end

    SkinPageControls()

    if not isModern then
        -- ElvUI before v16 moved MerchantItem1-12 with PointXY in its Classic buyback hook (MerchantItemPoint); this hook comes after it
        -- and puts them back. Harmless with v16, which no longer moves them.
        hooksecurefunc('MerchantFrame_UpdateBuybackInfo', function()
            addon.Gui.MerchantItemsContainer:PlaceBuybackItemSlots()
        end)
    end
end

function elv:OnItemSlotCreated(item)
    if not (doSkin and doSkin.Merchant) or isModern then
        return
    end
    SkinClassicItemSlot(item)
end

function elv:OnItemSlotUpdated(item, index)
    if not (doSkin and doSkin.Merchant) then
        return
    end
    ElvSkinItemSlot(item)
    UpdateItemSlot(item, index)
end
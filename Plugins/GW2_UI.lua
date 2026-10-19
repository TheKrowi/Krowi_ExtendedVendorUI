local _, addon = ...
local gw2 = {}
local pluginName = 'GW2_UI'
local L_Prefix = 'Plugin_GW2UI_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, gw2)

-- GW2_UI skins Blizzard's MerchantItemN (GW2_UI/Games/Shared/Immersive/Skins/merchant.lua, GW2_UI 12.1.0), which the merchant tab
-- no longer shows. The addon's slots get the same steps here, through the functions GW2_UI exposes as GW2_ADDON.

local ITEM_BORDER = 'Interface/AddOns/GW2_UI/textures/bag/bagitemborder.png' -- merchant.lua:4

local function IsLoaded()
    return C_AddOns.IsAddOnLoaded(pluginName)
end

-- GW2_ADDON when its merchant skin is on and every function this plugin uses exists
local function GetSkin()
    local gw = GW2_ADDON
    if not (gw and gw.settings and gw.settings.skins and gw.settings.skins.merchant and gw.settings.skins.merchant.enabled) then
        return
    end
    if not (gw.HandleIcon and gw.HandleIconBorder and gw.HandleNextPrevButton and gw.BackdropTemplates
        and gw.BackdropTemplates.DefaultWithSmallBorder and gw.BackdropTemplates.ColorableBorderOnly
        and gw.Colors and gw.Colors.FallbackWhite and MerchantFrame.GwStripTextures) then
        return
    end
    return gw
end

local skin -- nil until the first merchant window, then GW2_ADDON or false
local pendingItemSlots = {}

-- merchant.lua:17-22
local function StyleItemIcon(icon)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:ClearAllPoints()
    icon:SetPoint('TOPLEFT', 1, -1)
    icon:SetPoint('BOTTOMRIGHT', -1, 1)
end

-- merchant.lua:25-44 (SkinMerchantFrameItemButton, which only finds MerchantItemN)
local function SkinItemSlot(itemSlot)
    itemSlot:GwStripTextures(true)
    itemSlot:GwCreateBackdrop(skin.BackdropTemplates.DefaultWithSmallBorder, true, 6, 6)
    itemSlot.backdrop:SetFrameLevel(itemSlot:GetFrameLevel())

    local button = itemSlot.ItemButton
    button:GwStripTextures()
    button:GwStyleButton()
    button:SetPoint('TOPLEFT', itemSlot, 'TOPLEFT', 4, -4)
    StyleItemIcon(button.icon)

    button.IconBorder:SetTexture(ITEM_BORDER)
    button.IconBorder:SetAllPoints(button)
    skin.HandleIcon(button.icon, true, skin.BackdropTemplates.ColorableBorderOnly)
    skin.HandleIconBorder(button.IconBorder, button.icon.backdrop)
end

-- merchant.lua:52-67 (PlacePrices), run after each draw since drawing anchors the prices again
local function PlacePrices(itemSlot)
    local itemSlotName = itemSlot:GetName()
    local button = itemSlot.ItemButton
    local money = _G[itemSlotName .. 'MoneyFrame']
    local currency = _G[itemSlotName .. 'AltCurrencyFrame']

    money:ClearAllPoints()
    money:SetPoint('BOTTOMLEFT', button, 'BOTTOMRIGHT', 5, -3)
    currency:ClearAllPoints()
    if button.price and button.extendedCost then
        currency:SetPoint('LEFT', money, 'RIGHT', -8, 0)
    else
        currency:SetPoint('BOTTOMLEFT', button, 'BOTTOMRIGHT', 5, -3)
    end
end

-- merchant.lua:87-105 (ColorByQuality from ColorItemsByQuality), Mists only, as in GW2_UI
local function ColorByQuality(itemSlot)
    local button = itemSlot.ItemButton
    local quality = button.link and C_Item.GetItemQualityByID(button.link)
    local r, g, b = skin.Colors.FallbackWhite:GetRGB()
    if quality and quality > Enum.ItemQuality.Common then
        r, g, b = C_Item.GetItemQualityColor(quality)
    end
    button.icon.backdrop:SetBackdropBorderColor(r, g, b)
    _G[itemSlot:GetName() .. 'Name']:SetTextColor(r, g, b)
end

-- merchant.lua:195-206 (part of SkinButtons)
local function SkinPageControls()
    for _, button in ipairs({ KrowiEVU_MerchantNextPageButton, KrowiEVU_MerchantPrevPageButton }) do
        skin.HandleNextPrevButton(button, nil, true)
        for _, region in ipairs({ button:GetRegions() }) do
            if region:GetObjectType() == 'FontString' then
                region:SetTextColor(skin.Colors.FallbackWhite:GetRGB())
                break
            end
        end
    end
    KrowiEVU_MerchantPageText:SetTextColor(skin.Colors.FallbackWhite:GetRGB())
    KrowiEVU_MerchantNextPageButton:ClearAllPoints()
    KrowiEVU_MerchantNextPageButton:SetPoint('LEFT', KrowiEVU_MerchantPageText, 'RIGHT', 100, 4)
end

-- GW2_UI skins from a timer after PLAYER_LOGIN, after this addon loads, so everything waits for the first merchant window
local function OnFirstShow()
    if skin ~= nil then
        return
    end
    skin = GetSkin() or false
    if not skin then
        wipe(pendingItemSlots)
        return
    end

    SkinPageControls()
    for _, itemSlot in ipairs(pendingItemSlots) do
        SkinItemSlot(itemSlot)
    end
    wipe(pendingItemSlots)
    addon.Gui.MerchantItemsContainer:Update()
end

function gw2:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc'], IsLoaded)
end

function gw2:Load()
    if not IsLoaded() then
        return
    end
    MerchantFrame:HookScript('OnShow', OnFirstShow)
end

function gw2:OnItemSlotCreated(itemSlot)
    if skin then
        SkinItemSlot(itemSlot)
    elseif skin == nil and IsLoaded() then
        tinsert(pendingItemSlots, itemSlot)
    end
end

function gw2:OnItemSlotUpdated(itemSlot, index)
    if not skin then
        return
    end
    PlacePrices(itemSlot)
    if skin.Mists and index then
        ColorByQuality(itemSlot)
    end
end
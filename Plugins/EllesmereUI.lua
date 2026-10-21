local _, addon = ...
if not addon.Util.IsMainline then
    return -- EllesmereUI only exists on Retail
end

local ellesmere = {}
local pluginName = 'EllesmereUI'
local L_Prefix = 'Plugin_EllesmereUI_'
KrowiEVU.PluginsApi:RegisterPlugin(pluginName, ellesmere)

-- EllesmereUI's merchant tile skin and item levels (EllesmereUIBlizzardSkin_WindowPacks.lua, EllesmereUI 9.6) draw on Blizzard's
-- MerchantItemN through its private skin engine, which no other addon can call. The addon's slots get the same look from this
-- plugin's own code and EllesmereUI's public functions; EllesmereUI reserves all rights to its code, so none of it is copied here.

local FILL_R, FILL_G, FILL_B, FILL_A = 0.08, 0.08, 0.08, 0.92 -- EllesmereUI's card fill
local BORDER_R, BORDER_G, BORDER_B, BORDER_A = 0.2, 0.2, 0.2, 1 -- and its border
local QUALITY_CHROMA = 0.1 -- Poor and common rings are grey or white, uncommon and up are coloured
local CURRENCY_LIFT = 6

local function IsLoaded()
    return EllesmereUI ~= nil and not EUI_CLIENT_BLOCKED and C_AddOns.IsAddOnLoaded('EllesmereUIBlizzardSkin')
end

local function GetBorderApi()
    local pp = EllesmereUI.PanelPP or EllesmereUI.PP
    if pp and pp.CreateBorder and pp.SetBorderColor then
        return pp
    end
end

local function IsWindowSkinOn()
    return type(EllesmereUI.GetBlizzWindowStyle) == 'function' and EllesmereUI.GetBlizzWindowStyle('merchant') ~= 'off'
end

-- EllesmereUI's list mode shows every item in its own scroll list over the merchant window; switching it takes a reload
local function IsListModeOn()
    return IsWindowSkinOn() and EllesmereUIDB and EllesmereUIDB.merchantShowAsList == true
end

local function IsTileSkinOn()
    return IsWindowSkinOn() and not (EllesmereUIDB and EllesmereUIDB.merchantShowAsList) and GetBorderApi() ~= nil
end

local function IsItemLevelOn()
    return EllesmereUIDB and EllesmereUIDB.merchantShowItemLevel == true
end

local loaded -- Set at Load
local tileSkinOn, listModeOn -- nil until the first draw, then true or false
local pendingItemSlots = {}
local slotData = setmetatable({}, { __mode = 'k' })

-- [[ Tile ]] --
local function FadeArt(itemSlot)
    local data = slotData[itemSlot]
    if not data then
        return
    end
    for _, region in ipairs({ itemSlot:GetRegions() }) do
        if region ~= data.fill and region:IsObjectType('Texture') then
            region:SetAlpha(0)
        end
    end
    local button = itemSlot.ItemButton
    local normalTexture = button:GetNormalTexture()
    if normalTexture then
        normalTexture:SetAlpha(0)
    end
    button.IconBorder:SetAlpha(0) -- The round quality ring; its colour moves to the square border
end

-- A square border one pixel outside the icon in the ring's colour, black for poor, common and empty slots
local function PaintQualityBorder(button)
    local data = slotData[button]
    if not (data and data.qualityBorder) then
        return
    end
    local r, g, b
    local ring = button.IconBorder
    if ring and ring:IsShown() then
        local ringR, ringG, ringB = ring:GetVertexColor()
        if type(ringR) == 'number' and math.max(ringR, ringG, ringB) - math.min(ringR, ringG, ringB) > QUALITY_CHROMA then
            r, g, b = ringR, ringG, ringB
        end
    end
    GetBorderApi().SetBorderColor(data.qualityBorder, r or 0, g or 0, b or 0, 1)
end

-- Raises a money or currency frame by CURRENCY_LIFT every time drawing anchors it
local function LiftCurrency(frame)
    local applying = false
    local function Lift()
        local points = {}
        for i = 1, frame:GetNumPoints() do
            local point, relativeTo, relativePoint, x, y = frame:GetPoint(i)
            points[i] = { point, relativeTo, relativePoint, x or 0, (y or 0) + CURRENCY_LIFT }
        end
        if #points == 0 then
            return
        end
        frame:ClearAllPoints()
        for _, p in ipairs(points) do
            frame:SetPoint(p[1], p[2], p[3], p[4], p[5])
        end
    end
    -- Runs inside the addon's draw, outside the plugin error guard, so it guards itself
    local function Apply()
        if applying then
            return
        end
        applying = true
        local ok, err = pcall(Lift)
        applying = false
        if not ok then
            geterrorhandler()(err)
        end
    end
    hooksecurefunc(frame, 'SetPoint', Apply)
    Apply()
end

local function SkinTile(itemSlot)
    local borderApi = GetBorderApi()
    local itemSlotName = itemSlot:GetName()
    local data = {}
    slotData[itemSlot] = data

    data.fill = itemSlot:CreateTexture(nil, 'BACKGROUND', nil, -7)
    data.fill:SetColorTexture(FILL_R, FILL_G, FILL_B, FILL_A)
    data.fill:SetPoint('TOPLEFT', 2, -1)
    data.fill:SetPoint('BOTTOMRIGHT', -2, 1)
    local border = borderApi.CreateBorder(itemSlot, BORDER_R, BORDER_G, BORDER_B, BORDER_A, 1, 'BORDER', -7)
    if border and border.SetFrameLevel then
        border:SetFrameLevel(itemSlot:GetFrameLevel())
    end
    FadeArt(itemSlot)

    itemSlot.Name:SetWordWrap(true)
    itemSlot.Name:SetMaxLines(2)

    local button = itemSlot.ItemButton
    local icon = button.Icon or button.icon or _G[button:GetName() .. 'IconTexture']
    if icon and (not icon.GetNumMaskTextures or icon:GetNumMaskTextures() == 0) and pcall(icon.SetTexCoord, icon, 0.08, 0.92, 0.08, 0.92) then
        local qualityBorder = CreateFrame('Frame', nil, button)
        qualityBorder:SetPoint('TOPLEFT', icon, 'TOPLEFT', -1, 1)
        qualityBorder:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 1, -1)
        qualityBorder:SetFrameLevel(button:GetFrameLevel() + 6)
        borderApi.CreateBorder(qualityBorder, 0, 0, 0, 1, 1, 'OVERLAY', 7)
        local buttonData = slotData[button] or {} -- May already hold the item level text
        buttonData.qualityBorder = qualityBorder
        slotData[button] = buttonData
        PaintQualityBorder(button) -- And after every draw, from OnItemSlotUpdated
    end

    -- The icon centred in the row instead of at its top
    button:ClearAllPoints()
    button:SetPoint('LEFT', itemSlot, 'LEFT', 0, 0)

    LiftCurrency(_G[itemSlotName .. 'MoneyFrame'])
    LiftCurrency(_G[itemSlotName .. 'AltCurrencyFrame'])
end

-- [[ Item level ]] --
local function UpdateItemLevel(itemSlot, index)
    local button = itemSlot.ItemButton
    local data = slotData[button]
    if not data then
        data = {}
        slotData[button] = data
    end

    local text = data.itemLevel
    if not IsItemLevelOn() then
        if text then
            text:SetText('')
        end
        return
    end
    if not text then
        text = button:CreateFontString(nil, 'OVERLAY', nil, 7)
        text:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1)
        local fontPath = type(EllesmereUI.GetFontPath) == 'function' and (EllesmereUI.GetFontPath()) or 'Fonts\\FRIZQT__.TTF'
        local fontFlag = type(EllesmereUI.SlugFlag) == 'function' and (EllesmereUI.SlugFlag('OUTLINE, SLUG')) or 'OUTLINE'
        text:SetFont(fontPath, 12, fontFlag)
        data.itemLevel = text
    end

    text:SetText('')
    local link = index and GetMerchantItemLink(index)
    if not link then
        return
    end
    local classId = select(6, C_Item.GetItemInfoInstant(link))
    if classId ~= Enum.ItemClass.Weapon and classId ~= Enum.ItemClass.Armor then
        return
    end
    local itemLevel = C_Item.GetDetailedItemLevelInfo(link)
    if itemLevel and itemLevel > 0 then
        text:SetText(itemLevel)
        local quality = select(3, C_Item.GetItemInfo(link))
        local color = type(EllesmereUI.GetItemLevelColor) == 'function' and EllesmereUI.GetItemLevelColor(link, quality)
        if color then
            text:SetTextColor(color.r or 1, color.g or 1, color.b or 1, 1)
        end
    end
end

-- [[ Plugin ]] --
-- EllesmereUI skins at PLAYER_LOGIN, after this addon loads, so the tile skin waits for the first draw
local function SkinPending()
    for _, itemSlot in ipairs(pendingItemSlots) do
        SkinTile(itemSlot)
    end
end

function ellesmere:InjectOptions()
    addon.InjectOptions:AddPluginTable(pluginName, addon.L[L_Prefix .. 'Name'], addon.L[L_Prefix .. 'Desc'], IsLoaded)
end

function ellesmere:Load()
    loaded = IsLoaded()
    if not loaded then
        return
    end
    if type(EllesmereUI._Merchant_RefreshItemLevels) == 'function' then
        -- EllesmereUI's item level option, toggled while a merchant window is open
        hooksecurefunc(EllesmereUI, '_Merchant_RefreshItemLevels', function()
            if MerchantFrame:IsShown() then
                addon.Gui.MerchantItemsContainer:RequestUpdate()
            end
        end)
    end
end

function ellesmere:OnFirstDraw()
    listModeOn = loaded and IsListModeOn() and true or false
    tileSkinOn = loaded and IsTileSkinOn() and true or false
    if tileSkinOn then
        local ok, err = pcall(SkinPending)
        if not ok then
            tileSkinOn = false -- EllesmereUI changed under the plugin: leave the slots unskinned instead of erroring on every draw
            geterrorhandler()(err)
        end
    end
    wipe(pendingItemSlots)
end

function ellesmere:OnItemSlotCreated(itemSlot)
    if tileSkinOn then
        SkinTile(itemSlot)
    elseif tileSkinOn == nil and loaded then
        tinsert(pendingItemSlots, itemSlot)
    end
end

function ellesmere:OnItemSlotUpdated(itemSlot, index)
    if not loaded or listModeOn then
        return
    end
    if tileSkinOn then
        FadeArt(itemSlot)
        PaintQualityBorder(itemSlot.ItemButton)
    end
    UpdateItemLevel(itemSlot, index)
end

-- In list mode the grid steps aside, the way it does for Krowi_Vendorer's tabs: EllesmereUI's list reads the merchant API itself,
-- so only Blizzard's server-side filters (class, specialization) reach it, not this addon's own filters or the search
-- (Krowi, 2026-10-21: hide only the grid, keep the window, buttons and token banner)
function ellesmere:OnItemSlotsUpdated()
    if listModeOn then
        addon.Gui.MerchantItemsContainer:HideAll()
    end
end
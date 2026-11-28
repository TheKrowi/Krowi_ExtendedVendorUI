local _, addon = ...
if addon.NotLoaded then return end
local merchantFrame = addon.Gui.MerchantFrame

-- [[ Resize grip ]] --
-- A grip in the merchant tab's bottom-right corner sizes the grid in whole columns and rows (#139,
-- docs/work/138-139-move-resize). It writes the gear menu's Rows and Columns through merchantFrame.ResizeTo, so both stay
-- one setting. The addon's own button: MerchantFrame is never made resizable; its size is set as the gear menu sets it.
addon.Gui.ResizeGrip = {}
local resizeGrip = addon.Gui.ResizeGrip

-- Temporary for the look gate: Snap redraws the grid at each new column or row, Outline shows the new size and redraws once
-- on release. /kevugrip snap|outline switches for the session.
resizeGrip.Mode = 'Snap'

local TEXTURES = 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-' -- The chat window's grip, on every client
local OUTLINE_THICKNESS = 2
local OUTLINE_R, OUTLINE_G, OUTLINE_B = 1, 0.82, 0 -- Blizzard's gold (NORMAL_FONT_COLOR)

local grip = CreateFrame('Button', 'KrowiEVU_MerchantResizeGrip', MerchantFrame)
grip:SetSize(16, 16)
grip:SetPoint('BOTTOMRIGHT', MerchantFrame, 'BOTTOMRIGHT', -3, 3)
grip:SetFrameLevel(MerchantMoneyInset:GetFrameLevel() + 5)
grip:SetNormalTexture(TEXTURES .. 'Up')
grip:SetPushedTexture(TEXTURES .. 'Down')
grip:SetHighlightTexture(TEXTURES .. 'Highlight')
grip:Hide()

local outline = CreateFrame('Frame', 'KrowiEVU_MerchantResizeOutline', MerchantFrame)
outline:SetPoint('TOPLEFT', MerchantFrame, 'TOPLEFT')
outline:SetFrameLevel(grip:GetFrameLevel() + 1)
outline:Hide()
do
    local function Edge(point1, point2, horizontal)
        local edge = outline:CreateTexture(nil, 'OVERLAY')
        edge:SetColorTexture(OUTLINE_R, OUTLINE_G, OUTLINE_B, 1)
        edge:SetPoint(point1)
        edge:SetPoint(point2)
        if horizontal then
            edge:SetHeight(OUTLINE_THICKNESS)
        else
            edge:SetWidth(OUTLINE_THICKNESS)
        end
    end
    Edge('TOPLEFT', 'TOPRIGHT', true)
    Edge('BOTTOMLEFT', 'BOTTOMRIGHT', true)
    Edge('TOPLEFT', 'BOTTOMLEFT')
    Edge('TOPRIGHT', 'BOTTOMRIGHT')
    outline.Text = outline:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightLarge')
    outline.Text:SetPoint('BOTTOMRIGHT', -24, 24)
end

local startX, startY, startColumns, startRows, targetColumns, targetRows

-- The cursor in the window's own units, the units of a column and a row
local function GetCursor()
    local x, y = GetCursorPosition()
    local scale = MerchantFrame:GetEffectiveScale()
    return x / scale, y / scale
end

local function ShowOutline(numColumns, numRows)
    outline:SetSize(merchantFrame.GetMerchantInfoSize(numColumns, numRows, addon.Gui.Paging:IsShown()))
    outline.Text:SetText(('%d x %d'):format(numColumns, numRows))
    outline:Show()
end

local function OnUpdate()
    local x, y = GetCursor()
    local columnWidth, rowHeight = merchantFrame.GetGridStep()
    local numColumns = startColumns + math.floor((x - startX) / columnWidth + 0.5)
    local numRows = startRows + math.floor((startY - y) / rowHeight + 0.5)
    numColumns, numRows = merchantFrame.ClampGrid(numColumns, numRows)
    if numColumns == targetColumns and numRows == targetRows then
        return
    end
    targetColumns, targetRows = numColumns, numRows
    if resizeGrip.Mode == 'Outline' then
        ShowOutline(numColumns, numRows)
    else
        merchantFrame.ResizeTo(numColumns, numRows)
    end
end

local function Stop(apply)
    if not startX then
        return
    end
    grip:SetScript('OnUpdate', nil)
    outline:Hide()
    if apply and resizeGrip.Mode == 'Outline' then
        merchantFrame.ResizeTo(targetColumns, targetRows)
    end
    startX, startY = nil, nil
end

grip:SetScript('OnMouseDown', function(self, button)
    if button ~= 'LeftButton' then
        return
    end
    local profile = addon.Options.db.profile
    startColumns, startRows = profile.NumColumns, profile.NumRows
    targetColumns, targetRows = startColumns, startRows
    startX, startY = GetCursor()
    if resizeGrip.Mode == 'Outline' then
        ShowOutline(startColumns, startRows)
    end
    self:SetScript('OnUpdate', OnUpdate)
end)

grip:SetScript('OnMouseUp', function(_, button)
    if button == 'LeftButton' then
        Stop(true)
    end
end)

grip:SetScript('OnHide', function()
    Stop(false) -- The window closed or switched to Buyback mid-drag
end)

grip:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText(addon.L['Resize grip'])
    GameTooltip:AddLine(addon.L['Resize grip Desc'], 1, 1, 1, true)
    GameTooltip:Show()
end)
grip:SetScript('OnLeave', GameTooltip_Hide)

-- [[ Temporary switch for the look gate ]] --
SLASH_KEVUGRIP1 = '/kevugrip'
SlashCmdList.KEVUGRIP = function(message)
    message = (message or ''):lower()
    if message == 'snap' then
        resizeGrip.Mode = 'Snap'
    elseif message == 'outline' then
        resizeGrip.Mode = 'Outline'
    end
    print(addon.Metadata.Title .. ': grip ' .. resizeGrip.Mode)
end
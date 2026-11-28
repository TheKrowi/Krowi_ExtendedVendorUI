local _, addon = ...
if addon.NotLoaded then return end
local merchantFrame = addon.Gui.MerchantFrame

-- [[ Resize grip ]] --
-- A grip in the merchant tab's bottom-right corner sizes the grid in whole columns and rows (#139,
-- docs/work/138-139-move-resize). It writes the gear menu's Rows and Columns through merchantFrame.ResizeTo, so both stay
-- one setting, and the grid redraws at each new column or row while dragging (Krowi, 2026-11-28, chosen over an outline
-- applied on release). The addon's own button: MerchantFrame is never made resizable; its size is set as the gear menu sets it.
local TEXTURES = 'Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-' -- The chat window's grip, on every client

local grip = CreateFrame('Button', 'KrowiEVU_MerchantResizeGrip', MerchantFrame)
grip:SetSize(16, 16)
grip:SetPoint('BOTTOMRIGHT', MerchantFrame, 'BOTTOMRIGHT', -3, 3)
grip:SetFrameLevel(MerchantMoneyInset:GetFrameLevel() + 5)
grip:SetNormalTexture(TEXTURES .. 'Up')
grip:SetPushedTexture(TEXTURES .. 'Down')
grip:SetHighlightTexture(TEXTURES .. 'Highlight')
grip:Hide()

local startX, startY, startColumns, startRows, targetColumns, targetRows

-- The cursor in the window's own units, the units of a column and a row
local function GetCursor()
    local x, y = GetCursorPosition()
    local scale = MerchantFrame:GetEffectiveScale()
    return x / scale, y / scale
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
    merchantFrame.ResizeTo(numColumns, numRows)
end

local function Stop()
    grip:SetScript('OnUpdate', nil)
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
    self:SetScript('OnUpdate', OnUpdate)
end)

grip:SetScript('OnMouseUp', function(_, button)
    if button == 'LeftButton' then
        Stop()
    end
end)

grip:SetScript('OnHide', Stop) -- The window closed or switched to Buyback mid-drag

grip:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText(addon.L['Resize grip'])
    GameTooltip:AddLine(addon.L['Resize grip Desc'], 1, 1, 1, true)
    GameTooltip:Show()
end)
grip:SetScript('OnLeave', function(self)
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end)
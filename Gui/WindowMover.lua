local _, addon = ...
if addon.NotLoaded then return end

-- [[ Window mover ]] --
-- Moving the vendor window with Krowi_AchievementFilter's Window > Movable settings (#138, docs/work/138-139-move-resize).
-- MerchantFrame is a UI panel: Blizzard's panel manager places it at every open and whenever another panel opens or closes
-- (live Shared/UIParentPanelManager.lua:623-637), always through the global UpdateUIPanelPositions (securecall by name in
-- SetUIPanel and MoveUIPanel, live 488 and 515). A post-hook on that global puts a moved window back after each layout.
-- Only method calls and post-hooks on MerchantFrame: it is movable in Blizzard's own XML on every client.
addon.Gui.WindowMover = {}
local windowMover = addon.Gui.WindowMover

local sessionPosition -- {X, Y}: the spot for the rest of the session, nil while the window is where Blizzard places it
local blizzardPoint -- The last point the panel manager gave the window, for Reset
local lastApplied -- {X, Y} as the addon last set it, to tell its own point from Blizzard's
local mouseDownLeft, mouseDownTop
local moving

local MIN_ON_SCREEN_X, MIN_ON_SCREEN_Y = 40, 20 -- How much of the window's top strip always stays on screen
local MIN_MOVE = 4 -- Pixels the window must move for a press on its background to count as a move, not a click

local function GetSettings()
    return addon.Options.db and addon.Options.db.profile.Window
end

-- BlizzMove handles the window unless the player disabled it there (BlizzMoveAPI.lua:114); MoveAny moves it while its Move
-- Frames setting is on, its default, which sits in its private namespace (moveframes.lua:3, 317), so being loaded counts
function windowMover.GetOtherMover()
    if BlizzMoveAPI and BlizzMoveAPI.IsFrameDisabled then
        local ok, disabled = pcall(BlizzMoveAPI.IsFrameDisabled, BlizzMoveAPI, 'BlizzMove', 'MerchantFrame')
        if ok and not disabled then
            return 'BlizzMove'
        end
    end
    if C_AddOns.IsAddOnLoaded('MoveAny') then
        return 'MoveAny'
    end
end

function windowMover.CanDrag()
    local settings = GetSettings()
    return settings and settings.Movable and not windowMover.GetOtherMover() or false
end

function windowMover.GetPosition()
    if sessionPosition then
        return sessionPosition
    end
    local settings = GetSettings()
    return settings and settings.RememberPosition and settings.Position or nil
end

function windowMover.GetBlizzardPoint()
    return blizzardPoint
end

-- The spot, kept so the window's top strip stays on screen (another resolution or UI scale since it was saved)
function windowMover.Clamp(x, y)
    local ratio = UIParent:GetEffectiveScale() / MerchantFrame:GetEffectiveScale()
    local screenWidth, screenHeight = UIParent:GetWidth() * ratio, UIParent:GetHeight() * ratio
    local width = MerchantFrame:GetWidth()
    x = math.max(MIN_ON_SCREEN_X - width, math.min(x, screenWidth - MIN_ON_SCREEN_X))
    y = math.max(MIN_ON_SCREEN_Y - screenHeight, math.min(y, 0))
    return x, y
end

local function ReadPosition()
    local left, top = MerchantFrame:GetLeft(), MerchantFrame:GetTop()
    if not left or not top then
        return
    end
    local ratio = UIParent:GetEffectiveScale() / MerchantFrame:GetEffectiveScale()
    return left, top - UIParent:GetTop() * ratio
end

local function CanSetPoint()
    return MerchantFrame:IsShown() and not (InCombatLockdown() and MerchantFrame:IsProtected())
end

-- The panel manager always sets TOPLEFT against UIParent's TOPLEFT (live Shared/UIParentPanelManager.lua:634); after one of
-- its layouts a point that is not the addon's own is Blizzard's. Only read then: after a drag the client's own anchor can be
-- TOPLEFT against UIParent too.
local function NoteBlizzardPoint()
    local point, relativeTo, relativePoint, x, y = MerchantFrame:GetPoint(1)
    if point ~= 'TOPLEFT' or relativePoint ~= 'TOPLEFT' or (relativeTo ~= UIParent and relativeTo ~= nil) then
        return
    end
    if lastApplied and math.abs(x - lastApplied.X) < 0.5 and math.abs(y - lastApplied.Y) < 0.5 then
        return
    end
    blizzardPoint = { 'TOPLEFT', UIParent, 'TOPLEFT', x, y }
end

local function PlaceAtPosition()
    local position = windowMover.GetPosition()
    if not position or not CanSetPoint() then
        return
    end
    local x, y = windowMover.Clamp(position.X, position.Y)
    lastApplied = { X = x, Y = y }
    MerchantFrame:ClearAllPoints()
    MerchantFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x, y)
end

-- After a layout of the panel manager (or the open): notes where Blizzard put the window, then puts it at the moved spot
function windowMover.Apply()
    if not CanSetPoint() then
        return
    end
    NoteBlizzardPoint()
    PlaceAtPosition()
end

local function PlaceAtBlizzardPoint()
    lastApplied = nil
    if blizzardPoint and CanSetPoint() then
        MerchantFrame:ClearAllPoints()
        MerchantFrame:SetPoint(unpack(blizzardPoint))
    end
end

-- Another profile, or a reset one: its remembered spot, or Blizzard's place, and the session's spot dropped
function windowMover.OnProfileChanged()
    sessionPosition = nil
    if windowMover.GetPosition() then
        PlaceAtPosition()
    else
        PlaceAtBlizzardPoint()
    end
end

-- The spot for this session, and saved while Remember Window Position is on
function windowMover.SetPosition(x, y)
    sessionPosition = { X = x, Y = y }
    local settings = GetSettings()
    if settings and settings.RememberPosition then
        settings.Position = { X = x, Y = y }
    end
end

-- Back where Blizzard places the window, at once while it is shown, and the moved spot forgotten
function windowMover.Reset()
    sessionPosition = nil
    local settings = GetSettings()
    if settings then
        settings.Position = nil
    end
    PlaceAtBlizzardPoint()
end

-- Remember Window Position: on keeps the session's spot for later sessions too, off resets (as Krowi_AchievementFilter)
function windowMover.SetRememberPosition(value)
    local settings = GetSettings()
    settings.RememberPosition = value
    if value then
        if sessionPosition then
            settings.Position = { X = sessionPosition.X, Y = sessionPosition.Y }
        end
    else
        windowMover.Reset()
    end
end

-- For /kevutest, which puts the spot back as it found it
function windowMover.GetState()
    local settings = GetSettings()
    return {
        Session = sessionPosition and { X = sessionPosition.X, Y = sessionPosition.Y },
        Saved = settings and settings.Position and { X = settings.Position.X, Y = settings.Position.Y },
        RememberPosition = settings and settings.RememberPosition,
    }
end

function windowMover.SetState(state)
    sessionPosition = state.Session
    local settings = GetSettings()
    settings.RememberPosition = state.RememberPosition
    settings.Position = state.Saved
    if windowMover.GetPosition() then
        windowMover.Apply()
    else
        windowMover.Reset()
    end
end

-- [[ Dragging ]] --
-- A left-button drag on the window's background, as Krowi_AchievementFilter's windows move (Gui/MovableFrames.lua:41-46);
-- item slots, buttons and tabs take their own clicks. Mouse down and up rather than RegisterForDrag, which BlizzMove's own
-- OnMouseUp stop could miss. A spot is stored only when the window moved, also after BlizzMove or MoveAny moved it.
MerchantFrame:HookScript('OnMouseDown', function(self, button)
    if button ~= 'LeftButton' then
        return
    end
    mouseDownLeft, mouseDownTop = self:GetLeft(), self:GetTop()
    -- An item on the cursor is sold by Blizzard's OnMouseUp on the window (MerchantFrame.xml:620-628), so no drag then;
    -- StartMoving is protected, so none either if another addon ever made the window protected in combat
    if windowMover.CanDrag() and not GetCursorInfo() and CanSetPoint() then
        self:StartMoving()
        moving = true
    end
end)

MerchantFrame:HookScript('OnMouseUp', function(self, button)
    if button ~= 'LeftButton' then
        return
    end
    local wasMoving = moving
    if moving then
        moving = nil
        self:StopMovingOrSizing()
        self:SetUserPlaced(false) -- Keeps the client's layout cache off a UI panel
    end
    local downLeft, downTop = mouseDownLeft, mouseDownTop
    mouseDownLeft, mouseDownTop = nil, nil
    local left, top = self:GetLeft(), self:GetTop()
    if not (downLeft and left) then
        return
    end
    if math.abs(left - downLeft) < MIN_MOVE and math.abs(top - downTop) < MIN_MOVE then
        if wasMoving then -- A click with a twitch: back where it was, nothing stored
            if windowMover.GetPosition() then
                PlaceAtPosition()
            else
                PlaceAtBlizzardPoint()
            end
        end
        return
    end
    local x, y = ReadPosition()
    if x then
        windowMover.SetPosition(x, y)
        PlaceAtPosition() -- The addon's own TOPLEFT anchor in place of the client's drag anchor, not taken for Blizzard's
    end
end)

MerchantFrame:HookScript('OnHide', function(self)
    if moving then -- Closed while dragging (Escape, walking away)
        moving = nil
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
    end
end)

-- [[ Putting it back ]] --
local function OnLayout()
    windowMover.Apply()
end
hooksecurefunc('UpdateUIPanelPositions', OnLayout)
hooksecurefunc('UpdateScaleForFitForOpenPanels', OnLayout) -- UI scale changes lay out through the delegate's own method
MerchantFrame:HookScript('OnShow', OnLayout)
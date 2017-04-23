-- locals and speed
local AddonName, Addon = ...

local _G = _G
local pairs = pairs

local CastingBarFrame_ApplyAlpha = CastingBarFrame_ApplyAlpha
local CompactUnitFrame_IsTapDenied = CompactUnitFrame_IsTapDenied
local CreateFrame = CreateFrame
local C_NamePlate = C_NamePlate
local GetUnitName = GetUnitName
local InCombatLockdown = InCombatLockdown
local ShouldShowName = ShouldShowName
local UnitAffectingCombat = UnitAffectingCombat
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitClassification = UnitClassification
local UnitThreatSituation = UnitThreatSituation
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitIsEnemy = UnitIsEnemy
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitLevel = UnitLevel
local UnitReaction = UnitReaction
local UnitSelectionColor = UnitSelectionColor
local SetCVar = SetCVar

-- constants
local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local ICON = {
  Alliance = '\124TInterface/PVPFrame/PVP-Currency-Alliance:16\124t',
  Horde = '\124TInterface/PVPFrame/PVP-Currency-Horde:16\124t'
}

local NAME_FADE_VALUE = .6
local BAR_FADE_VALUE = .4

-- helper functions
local function IsTanking(unit)
  local isTanking = UnitDetailedThreatSituation('player', unit)
  return isTanking
end

local function InCombat(unit)
  return UnitAffectingCombat(unit) and UnitCanAttack('player', unit)
end

local function IsOnThreatList(unit)
  local status = UnitThreatSituation('player', unit)
  return status and status > 0
end

local function GetBorderBackdrop(size)
  return {
    bgFile = nil,
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    tile = false,
    edgeSize = size,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  }
end

local function GetClassificationShort(classification)
  return (classification == 'elite') and '+' or
  (classification == 'minus') and '-' or
  (classification == 'rare') and 'r' or
  (classification == 'rareelite') and 'r+'
end

-- main
function Addon:Load()
  do
    local eventHandler = CreateFrame('Frame', nil)

    -- set OnEvent handler
    eventHandler:SetScript('OnEvent', function(handler, ...)
        self:OnEvent(...)
      end)

    eventHandler:RegisterEvent('PLAYER_LOGIN')
  end
end

-- frame events
function Addon:OnEvent(event, ...)
  local action = self[event]

  if (action) then
    action(self, event, ...)
  end
end

function Addon:PLAYER_LOGIN()
  self:ConfigNamePlates()
  self:HookActionEvents()
end

function Addon:ConfigNamePlates()
  if (not InCombatLockdown()) then
    -- set distance back to 40 (down from 60)
    SetCVar('nameplateMaxDistance', 40)

    -- stop nameplates from clamping to screen
    SetCVar('nameplateOtherTopInset', -1)
    SetCVar('nameplateOtherBottomInset', -1)

    -- hide class color on health bar for enemy players
    SetCVar('ShowClassColorInNameplate', 0)

    -- prevent nameplates from fading when you move away
    SetCVar('nameplateMaxAlpha', 1)
    SetCVar('nameplateMinAlpha', 1)

    -- Prevent nameplates from getting smaller when you move away
    SetCVar('nameplateMaxScale', 1)
    SetCVar('nameplateMinScale', 1)
  end
end

-- hooks
do
  local function Frame_SetupNamePlateInternal(frame, setupOptions, frameOptions)
    Addon:SetupNamePlateInternal(frame, setupOptions, frameOptions)
  end

  local function Frame_UpdateName(frame)
    Addon:UpdateName(frame)
  end

  function Addon:HookActionEvents()
    hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlateInternal)
    hooksecurefunc('CompactUnitFrame_UpdateName', Frame_UpdateName)
  end
end

function Addon:SetupNamePlateInternal(frame, setupOptions, frameOptions)
  local _, instanceType = GetInstanceInfo()
  if (instanceType == 'party' or instanceType == 'raid') then return end

  -- set bar color and textures for health bar
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar')
  frame.healthBar.background:SetVertexColor(0, 0, 0, .5)
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

  -- remove default health bar border
  frame.healthBar.border:Hide()
  for _, texture in pairs(frame.healthBar.border.Textures) do
    texture:Hide()
  end

  -- create a new border around the health bar
  if (not frame.healthBar.barBorder) then
    frame.healthBar.barBorder = self:CreateBorder(frame.healthBar)
  end

  -- and casting bar
  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar')
  frame.castBar.background:SetVertexColor(0, 0, 0, .5)
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')

  -- create a border just like the one around the health bar
  if (not frame.castBar.barBorder) then
    frame.castBar.barBorder = self:CreateBorder(frame.castBar)
  end

  frame.castBar.Icon:ClearAllPoints()

  -- cut the default icon border embedded in icons
  frame.castBar.Icon:SetTexCoord(.1, .9, .1, .9)

  if (setupOptions.useLargeNameFont) then
    -- get nameplate cast bar height
    local barHeight = frame.castBar:GetHeight()

    -- adjust cast bar icon size and position
    frame.castBar.Icon:SetSize(barHeight, barHeight)
    frame.castBar.Icon:ClearAllPoints()
    frame.castBar.Icon:SetPoint('RIGHT', frame.castBar, 'LEFT', -5, 0)

    -- adjust cast bar shield
    frame.castBar.BorderShield:SetSize(barHeight, barHeight)
    frame.castBar.BorderShield:ClearAllPoints()
    frame.castBar.BorderShield:SetPoint('RIGHT', frame.castBar, 'LEFT', -5, 0)
  else
    -- get nameplate health bar height
    local oldHealthBarHeight = frame.healthBar:GetHeight()

    -- increase nameplate health bar height by 2 px
    local healthBarHeight = oldHealthBarHeight + 2
    frame.healthBar:SetHeight(healthBarHeight)

    -- get nameplate cast bar height
    local castBarHeight = frame.castBar:GetHeight()

    -- calculate total height
    local totalHeight = healthBarHeight + castBarHeight + 2

    -- adjust cast bar icon size and position
    frame.castBar.Icon:SetSize(totalHeight, totalHeight)
    frame.castBar.Icon:ClearAllPoints()
    frame.castBar.Icon:SetPoint('TOPRIGHT', frame.healthBar, 'TOPLEFT', -5, 0)

    -- adjust cast bar shield
    frame.castBar.BorderShield:SetSize(totalHeight, totalHeight)
    frame.castBar.BorderShield:ClearAllPoints()
    frame.castBar.BorderShield:SetPoint('TOPRIGHT', frame.healthBar, 'TOPLEFT', -5, 0)

    -- when using small nameplates move the text below the casting bar
    frame.castBar.Text:ClearAllPoints()
    frame.castBar.Text:SetPoint('CENTER', frame.castBar, 'CENTER', 0, -16)
    frame.castBar.Text:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
  end

  if (frame.ClassificationFrame and frame.ClassificationFrame.classificationIndicator) then
    frame.ClassificationFrame.classificationIndicator:SetAlpha(0)
  end
end

function Addon:UpdateName(frame)
  local _, instanceType = GetInstanceInfo()
  if (instanceType == 'party' or instanceType == 'raid') then return end

  if (ShouldShowName(frame) and frame.optionTable.colorNameBySelection) then
    local level = UnitLevel(frame.unit)
    local name = GetUnitName(frame.unit, false)
    local classification = UnitClassification(frame.unit)
    local classificationShort = GetClassificationShort(classification)

    if (UnitIsPlayer(frame.unit)) then
      local isPVP = UnitIsPVP(frame.unit)
      local faction = UnitFactionGroup(frame.unit)

      -- set unit player name
      if (InCombat(frame.unit)) then
        -- unit player in combat
        frame.name:SetText((isPVP and faction) and ICON[faction]..' '..name..' ('..level..') **' or name..' ('..level..') **')
      else
        -- unit player out of combat
        frame.name:SetText((isPVP and faction) and ICON[faction]..' '..name..' ('..level..')' or name..' ('..level..')')
      end

      -- set unit player name color
      if (UnitIsEnemy('player', frame.unit)) then
        local _, class = UnitClass(frame.unit)
        local color = CLASS_COLORS[class]

        -- color enemy players name with class color
        frame.name:SetVertexColor(color.r, color.g, color.b)
      else
        local _, class = UnitClass(frame.unit)
        local color = CLASS_COLORS[class]

        -- color friendly players name white
        frame.name:SetVertexColor(1, 1, 1)
        -- color friendly players health bar with class color
        frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
      end
    elseif (level == -1) then
      -- set boss name text
      if (InCombat(frame.unit)) then
        frame.name:SetText(name..' (??) **')
      else
        frame.name:SetText(name..' (??)')
      end

      -- set boss name color
      if (frame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatList(frame.displayedUnit)) then
        frame.name:SetVertexColor(1, 0, 0)
      elseif (UnitCanAttack('player', frame.unit)) then
        frame.name:SetVertexColor(1, .8, .8)
      else
        frame.name:SetVertexColor(.8, 1, .8)
      end
    else
      -- set name text
      if (InCombat(frame.unit)) then
        frame.name:SetText(classificationShort and name..' ('..level..classificationShort..') **' or name..' ('..level..') **')
      else
        frame.name:SetText(classificationShort and name..' ('..level..classificationShort..')' or name..' ('..level..')')
      end

      -- set name color
      if (frame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatList(frame.displayedUnit)) then
        frame.name:SetVertexColor(1, 0, 0)
      elseif (UnitCanAttack('player', frame.unit)) then
        frame.name:SetVertexColor(1, .8, .8)
      else
        frame.name:SetVertexColor(.8, 1, .8)
      end
    end

    if (UnitGUID('target') == nil) then
      frame.name:SetAlpha(1)
      frame.healthBar:SetAlpha(1)
      CastingBarFrame_ApplyAlpha(frame.castBar, 1)
    else
      local tNameplate = C_NamePlate.GetNamePlateForUnit('target')
      if (tNameplate) then
        frame.name:SetAlpha(NAME_FADE_VALUE)
        frame.healthBar:SetAlpha(BAR_FADE_VALUE)
        if (not UnitCanAttack('player', frame.unit)) then
          CastingBarFrame_ApplyAlpha(frame.castBar, BAR_FADE_VALUE)
        end

        tNameplate.UnitFrame.name:SetAlpha(1)
        tNameplate.UnitFrame.healthBar:SetAlpha(1)
        CastingBarFrame_ApplyAlpha(tNameplate.UnitFrame.castBar, 1)
      else
        -- we have a target but unit has no nameplate
        -- keep casting bars faded to indicate we have a target
        frame.name:SetAlpha(NAME_FADE_VALUE)
        frame.healthBar:SetAlpha(BAR_FADE_VALUE)
        if (not UnitCanAttack('player', frame.unit)) then
          CastingBarFrame_ApplyAlpha(frame.castBar, BAR_FADE_VALUE)
        end
      end
    end
  end
end

function Addon:CreateBorder(frame)
  local textures = {}

  local layers = 3
  local size = 2

  for i = 1, layers do
    local backdrop = GetBorderBackdrop(size)

    local texture = CreateFrame('Frame', nil, frame)
    texture:SetBackdrop(backdrop)
    texture:SetPoint('TOPRIGHT', size, size)
    texture:SetPoint('BOTTOMLEFT', -size, -size)
    texture:SetFrameStrata('LOW')
    texture:SetBackdropBorderColor(0, 0, 0, (1 / layers))

    size = size - .5

    textures[#textures + 1] = texture
  end

  return textures
end

-- call
Addon:Load()

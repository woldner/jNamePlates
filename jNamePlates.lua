-- locals and speed
local AddonName, Addon = ...;

local _G = _G;
local select = select;
local pairs = pairs;

local CompactUnitFrame_IsTapDenied = CompactUnitFrame_IsTapDenied;
local CreateColor = CreateColor;
local CreateFrame = CreateFrame;
local GetUnitName = GetUnitName;
local InCombatLockdown = InCombatLockdown;
local ShouldShowName = ShouldShowName;
local UnitAffectingCombat = UnitAffectingCombat;
local UnitCanAttack = UnitCanAttack;
local UnitClass = UnitClass;
local UnitClassification = UnitClassification;
local UnitDetailedThreatSituation = UnitDetailedThreatSituation;
local UnitExists = UnitExists;
local UnitFactionGroup = UnitFactionGroup;
local UnitGUID = UnitGUID;
local UnitIsEnemy = UnitIsEnemy;
local UnitIsPlayer = UnitIsPlayer;
local UnitIsPVP = UnitIsPVP;
local UnitLevel = UnitLevel;
local SetCVar = SetCVar;
local wipe = wipe;

-- constants
local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
local ICON = {
  Alliance = '\124TInterface/PVPFrame/PVP-Currency-Alliance:16\124t',
  Horde = '\124TInterface/PVPFrame/PVP-Currency-Horde:16\124t'
}

local NAME_FADE_VALUE = .6;
local BAR_FADE_VALUE = .4;

-- helper functions
local function IsTanking(unit)
  return select(1, UnitDetailedThreatSituation('player', unit));
end

local function InCombat(unit)
  return UnitAffectingCombat(unit) and UnitCanAttack('player', unit);
end

local function IsOnThreatList(unit)
  return select(2, UnitDetailedThreatSituation('player', unit)) ~= nil;
end

-- identical to CastingBarFrame_ApplyAlpha
local function ApplyCastingBarAlpha(frame, alpha)
  frame:SetAlpha(alpha);
  if (frame.additionalFadeWidgets) then
    for widget in pairs(frame.additionalFadeWidgets) do
      widget:SetAlpha(alpha);
    end
  end
end

local function GetBorderBackdrop(size)
  return {
    bgFile = nil,
    edgeFile = 'Interface\\Buttons\\WHITE8x8',
    tile = false,
    edgeSize = size,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  };
end

local function AbbrClassification(classification)
  return (classification == 'elite') and '+' or
  (classification == 'minus') and '-' or
  (classification == 'rare') and 'r' or
  (classification == 'rareelite') and 'r+';
end

-- main
function Addon:Load()
  do
    local eventHandler = CreateFrame('Frame', nil);

    -- set OnEvent handler
    eventHandler:SetScript('OnEvent', function(handler, ...)
        self:OnEvent(...);
      end)

    eventHandler:RegisterEvent('PLAYER_LOGIN');
  end
end

-- frame events
function Addon:OnEvent(event, ...)
  local action = self[event];

  if (action) then
    action(self, event, ...);
  end
end

function Addon:PLAYER_LOGIN()
  self:ConfigNamePlates();
  self:HookActionEvents();
end

-- configuration (credits to Ketho)
function Addon:ConfigNamePlates()
  if (not InCombatLockdown()) then
    -- set distance back to 40 (down from 60)
    SetCVar('nameplateMaxDistance', 40);

    -- stop nameplates from clamping to screen
    SetCVar('nameplateOtherTopInset', -1);
    SetCVar('nameplateOtherBottomInset', -1);

    -- hide class color on health bar for enemy players
    SetCVar('ShowClassColorInNameplate', 0);

    -- prevent nameplates from fading when you move away
    SetCVar('nameplateMaxAlpha', 1);
    SetCVar('nameplateMinAlpha', 1);

    -- Prevent nameplates from getting smaller when you move away
    SetCVar('nameplateMaxScale', 1);
    SetCVar('nameplateMinScale', 1);

    -- enable class colors on friendly nameplates
    DefaultCompactNamePlateFriendlyFrameOptions.useClassColors = true;

    -- set the selected border color on friendly nameplates
    DefaultCompactNamePlateFriendlyFrameOptions.selectedBorderColor = CreateColor(0, 0, 0, 1);
    DefaultCompactNamePlateFriendlyFrameOptions.tankBorderColor = CreateColor(0, 0, 0, 1);
    DefaultCompactNamePlateFriendlyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 1);

    -- disable the classification indicator on nameplates
    DefaultCompactNamePlateEnemyFrameOptions.showClassificationIndicator = false;

    -- set the selected border color on enemy nameplates
    DefaultCompactNamePlateEnemyFrameOptions.selectedBorderColor = CreateColor(0, 0, 0, 1);
    DefaultCompactNamePlateEnemyFrameOptions.tankBorderColor = CreateColor(0, 0, 0, 1);
    DefaultCompactNamePlateEnemyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 1);

    -- override any enabled cvar
    C_Timer.After(.1, function ()
        -- disable class colors on enemy nameplates
        DefaultCompactNamePlateEnemyFrameOptions.useClassColors = false;
      end)

    -- always show names on nameplates
    for _, i in pairs({
        'Friendly',
        'Enemy'
      }) do
      for _, j in pairs({
          'displayNameWhenSelected',
          'displayNameByPlayerNameRules'
        }) do
        _G['DefaultCompactNamePlate'..i..'FrameOptions'][j] = false;
      end
    end
  end
end

-- hooks
do
  local function Frame_SetupNamePlateInternal(frame, setupOptions, frameOptions)
    Addon:SetupNamePlateInternal(frame, setupOptions, frameOptions);
  end

  local function Frame_UpdateHealthColor(frame)
    Addon:UpdateHealthColor(frame);
  end

  local function Frame_UpdateName(frame)
    Addon:UpdateName(frame);
  end

  local function Frame_ApplyAlpha(frame, alpha)
    Addon:ApplyAlpha(frame, alpha);
  end

  function Addon:HookActionEvents()
    hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlateInternal);
    hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateHealthColor);
    hooksecurefunc('CompactUnitFrame_UpdateName', Frame_UpdateName);
    hooksecurefunc('CastingBarFrame_ApplyAlpha', Frame_ApplyAlpha);
  end
end

function Addon:SetupNamePlateInternal(frame, setupOptions, frameOptions)
  -- set bar color and textures for health bar
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.healthBar.background:SetVertexColor(0, 0, 0, .5);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- remove default health bar border
  frame.healthBar.border:Hide();
  for _, texture in pairs(frame.healthBar.border.Textures) do
    texture:SetTexture(nil);
  end
  wipe(frame.healthBar.border.Textures);

  -- create a new border around the health bar
  if (not frame.healthBar.barBorder) then
    frame.healthBar.barBorder = self:CreateBorder(frame.healthBar);
  end

  -- and casting bar
  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0, 0, 0, .5);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border just like the one around the health bar
  if (not frame.castBar.barBorder) then
    frame.castBar.barBorder = self:CreateBorder(frame.castBar);
  end

  -- when using small nameplates move the text below the casting bar
  if (not setupOptions.useLargeNameFont) then
    frame.castBar.Text:ClearAllPoints();
    frame.castBar.Text:SetPoint('CENTER', frame.castBar, 'CENTER', 0, -16);
  end

  local fontName, fontSize, fontFlags = frame.castBar.Text:GetFont();
  frame.castBar.Text:SetFont(fontName, setupOptions.castBarFontHeight + 6, fontFlags);
end

function Addon:UpdateHealthColor(frame)
  if (UnitExists(frame.displayedUnit) and IsTanking(frame.displayedUnit)) then
    -- color of name plate of unit targeting us
    local r, g, b = 1, .3, 1;
    if (CompactUnitFrame_IsTapDenied(frame)) then
      r, g, b = r / 2, g / 2, b / 2;
    end

    if (r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b) then
      frame.healthBar:SetStatusBarColor(r, g, b);
      frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
    end
  end
end

function Addon:UpdateName(frame)
  if (ShouldShowName(frame) and frame.optionTable.colorNameBySelection) then
    local level = UnitLevel(frame.unit);
    local name = GetUnitName(frame.unit, false);
    local classification = UnitClassification(frame.unit);
    local classificationAbbr = AbbrClassification(classification);

    if (UnitIsPlayer(frame.unit)) then
      local isPVP = UnitIsPVP(frame.unit);
      local faction = UnitFactionGroup(frame.unit);

      -- set unit player name
      if (InCombat(frame.unit)) then
        -- unit player in combat
        frame.name:SetText((isPVP and faction) and ICON[faction]..' '..name..' ('..level..') **' or name..' ('..level..') **');
      else
        -- unit player out of combat
        frame.name:SetText((isPVP and faction) and ICON[faction]..' '..name..' ('..level..')' or name..' ('..level..')');
      end

      -- set unit player name color
      if (UnitIsEnemy('player', frame.unit)) then
        local _, class = UnitClass(frame.unit);
        local color = CLASS_COLORS[class];

        -- color enemy players name with class color
        frame.name:SetVertexColor(color.r, color.g, color.b);
      else
        -- color friendly players name white
        frame.name:SetVertexColor(1, 1, 1);
      end
    elseif (level == -1) then
      -- set boss name text
      if (InCombat(frame.unit)) then
        frame.name:SetText(name..' (??) **');
      else
        frame.name:SetText(name..' (??)');
      end

      -- set boss name color
      if (frame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatList(frame.displayedUnit)) then
        frame.name:SetVertexColor(1, 0, 0);
      elseif (UnitCanAttack('player', frame.unit)) then
        frame.name:SetVertexColor(1, .8, .8);
      else
        frame.name:SetVertexColor(.8, 1, .8);
      end
    else
      -- set name text
      if (InCombat(frame.unit)) then
        frame.name:SetText(classificationAbbr and name..' ('..level..classificationAbbr..') **' or name..' ('..level..') **');
      else
        frame.name:SetText(classificationAbbr and name..' ('..level..classificationAbbr..')' or name..' ('..level..')');
      end

      -- set name color
      if (frame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatList(frame.displayedUnit)) then
        frame.name:SetVertexColor(1, 0, 0);
      elseif (UnitCanAttack('player', frame.unit)) then
        frame.name:SetVertexColor(1, .8, .8);
      else
        frame.name:SetVertexColor(.8, 1, .8);
      end
    end

    if (UnitGUID('target') == nil) then
      frame.name:SetAlpha(1);
      frame.healthBar:SetAlpha(1);
      ApplyCastingBarAlpha(frame.castBar, 1);
    else
      local nameplate = C_NamePlate.GetNamePlateForUnit('target');
      if (nameplate) then
        frame.name:SetAlpha(NAME_FADE_VALUE);
        frame.healthBar:SetAlpha(BAR_FADE_VALUE);
        if (not UnitCanAttack('player', frame.unit)) then
          ApplyCastingBarAlpha(frame.castBar, BAR_FADE_VALUE);
        end

        nameplate.UnitFrame.name:SetAlpha(1);
        nameplate.UnitFrame.healthBar:SetAlpha(1);
        ApplyCastingBarAlpha(nameplate.UnitFrame.castBar, 1);
      else
        -- we have a target but unit has no nameplate
        -- keep casting bars faded to indicate we have a target
        frame.name:SetAlpha(NAME_FADE_VALUE);
        frame.healthBar:SetAlpha(BAR_FADE_VALUE);
        if (not UnitCanAttack('player', frame.unit)) then
          ApplyCastingBarAlpha(frame.castBar, BAR_FADE_VALUE);
        end
      end
    end
  end
end

function Addon:ApplyAlpha(frame, alpha)
  if (not UnitCanAttack('player', frame.unit)) then
    local parent = frame:GetParent();

    if (parent.healthBar) then
      local healthBarAlpha = parent.healthBar:GetAlpha();

      -- frame is faded
      if (healthBarAlpha == BAR_FADE_VALUE) then
        local value = (alpha * BAR_FADE_VALUE);
        ApplyCastingBarAlpha(frame, value);
      end
    end
  end
end

function Addon:CreateBorder(frame)
  local textures = {};

  local layers = 3;
  local size = 2;

  for i = 1, layers do
    local backdrop = GetBorderBackdrop(size);

    local texture = CreateFrame('Frame', nil, frame);
    texture:SetBackdrop(backdrop);
    texture:SetPoint('TOPRIGHT', size, size);
    texture:SetPoint('BOTTOMLEFT', -size, -size);
    texture:SetFrameStrata('LOW');
    texture:SetBackdropBorderColor(0, 0, 0, (1 / layers));

    size = size - .5;

    textures[#textures + 1] = texture;
  end

  return textures;
end

-- call
Addon:Load();

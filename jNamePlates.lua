-- locals and speed
local AddonName, Addon = ...;

local _G = _G;
local pairs = pairs;
local strfind = string.find;

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
local ICON = {
  Alliance = '\124TInterface/PVPFrame/PVP-Currency-Alliance:16\124t',
  Horde = '\124TInterface/PVPFrame/PVP-Currency-Horde:16\124t'
}

local NAME_FADE_VALUE = .6;
local BAR_FADE_VALUE = .4;

local BAR_BACKDROP = {
  bgFile = nil,
  edgeFile = 'Interface\\AddOns\\jNamePlates\\Textures\\GlowTexture',
  -- edgeFile = 'Interface\\AddOns\\jNamePlates\\Textures\\BorderSharp',
  tile = false,
  edgeSize = 4,
  insets = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0
  }
}

-- helper functions
local function IsTanking(unit)
  local isTanking = UnitDetailedThreatSituation('player', unit);
  return isTanking;
end

local function InCombat(unit)
  local inCombat = UnitAffectingCombat(unit) and UnitCanAttack('player', unit);
  return inCombat;
end

local function IsOnThreatList(unit)
  local _, threatStatus = UnitDetailedThreatSituation('player', unit);
  return threatStatus ~= nil;
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

local function SetBackdrop(frame, backdrop)
  frame:SetBackdrop(backdrop);
  local offset = backdrop.edgeSize;

  for _, texture in pairs({
      frame:GetRegions()
    }) do
    for i = 1, texture:GetNumPoints() do
      if (texture:GetObjectType() == 'Texture' and texture:GetTexture() == backdrop.edgeFile) then
        local point, relativeTo, relativePoint, xOfs, yOfs = texture:GetPoint(i);

        if (strfind(point, 'TOP', 1, true)) then yOfs = yOfs + offset end
        if (strfind(point, 'BOTTOM', 1, true)) then yOfs = yOfs - offset end
        if (strfind(point, 'LEFT', 1, true)) then xOfs = xOfs - offset end
        if (strfind(point, 'RIGHT', 1, true)) then xOfs = xOfs + offset end

        texture:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs);
      end
    end
  end
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
    SetCVar('nameplateOtherTopInset', 0);
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

function Addon:CreateCastingBarBorder(frame)
  local NamePlateCastingBarBorder = {};
  NamePlateCastingBarBorder.textures = {};

  -- first top
  NamePlateCastingBarBorder.textures.firstTopBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.firstTopBorder:SetPoint('BOTTOMRIGHT', frame.castBar, 'TOPRIGHT');
  NamePlateCastingBarBorder.textures.firstTopBorder:SetPoint('BOTTOMLEFT', frame.castBar, 'TOPLEFT');
  NamePlateCastingBarBorder.textures.firstTopBorder:SetHeight(2);
  NamePlateCastingBarBorder.textures.firstTopBorder:SetColorTexture(0, 0, 0, .2);

  -- first right
  NamePlateCastingBarBorder.textures.firstRightBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.firstRightBorder:SetPoint('TOPLEFT', frame.castBar, 'TOPRIGHT', 0, 2);
  NamePlateCastingBarBorder.textures.firstRightBorder:SetPoint('BOTTOMLEFT', frame.castBar, 'BOTTOMRIGHT', 0, -2);
  NamePlateCastingBarBorder.textures.firstRightBorder:SetWidth(2);
  NamePlateCastingBarBorder.textures.firstRightBorder:SetColorTexture(0, 0, 0, .2);

  -- first bottom
  NamePlateCastingBarBorder.textures.firstBottomBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.firstBottomBorder:SetPoint('TOPRIGHT', frame.castBar, 'BOTTOMLEFT');
  NamePlateCastingBarBorder.textures.firstBottomBorder:SetPoint('TOPLEFT', frame.castBar, 'BOTTOMRIGHT');
  NamePlateCastingBarBorder.textures.firstBottomBorder:SetHeight(2);
  NamePlateCastingBarBorder.textures.firstBottomBorder:SetColorTexture(0, 0, 0, .2);

  -- first left
  NamePlateCastingBarBorder.textures.firstLeftBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.firstLeftBorder:SetPoint('TOPRIGHT', frame.castBar, 'TOPLEFT', 0, 2);
  NamePlateCastingBarBorder.textures.firstLeftBorder:SetPoint('BOTTOMRIGHT', frame.castBar, 'BOTTOMLEFT', 0, -2);
  NamePlateCastingBarBorder.textures.firstLeftBorder:SetWidth(2);
  NamePlateCastingBarBorder.textures.firstLeftBorder:SetColorTexture(0, 0, 0, .2);

  -- second top
  NamePlateCastingBarBorder.textures.secondTopBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.secondTopBorder:SetPoint('BOTTOMRIGHT', frame.castBar, 'TOPRIGHT');
  NamePlateCastingBarBorder.textures.secondTopBorder:SetPoint('BOTTOMLEFT', frame.castBar, 'TOPLEFT');
  NamePlateCastingBarBorder.textures.secondTopBorder:SetHeight(1.5);
  NamePlateCastingBarBorder.textures.secondTopBorder:SetColorTexture(0, 0, 0, .2);

  -- second right
  NamePlateCastingBarBorder.textures.secondRightBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.secondRightBorder:SetPoint('TOPLEFT', frame.castBar, 'TOPRIGHT', 0, 1.5);
  NamePlateCastingBarBorder.textures.secondRightBorder:SetPoint('BOTTOMLEFT', frame.castBar, 'BOTTOMRIGHT', 0, -1.5);
  NamePlateCastingBarBorder.textures.secondRightBorder:SetWidth(1.5);
  NamePlateCastingBarBorder.textures.secondRightBorder:SetColorTexture(0, 0, 0, .2);

  -- second bottom
  NamePlateCastingBarBorder.textures.secondBottomBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.secondBottomBorder:SetPoint('TOPRIGHT', frame.castBar, 'BOTTOMLEFT');
  NamePlateCastingBarBorder.textures.secondBottomBorder:SetPoint('TOPLEFT', frame.castBar, 'BOTTOMRIGHT');
  NamePlateCastingBarBorder.textures.secondBottomBorder:SetHeight(1.5);
  NamePlateCastingBarBorder.textures.secondBottomBorder:SetColorTexture(0, 0, 0, .2);

  -- second left
  NamePlateCastingBarBorder.textures.secondLeftBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.secondLeftBorder:SetPoint('TOPRIGHT', frame.castBar, 'TOPLEFT', 0, 1.5);
  NamePlateCastingBarBorder.textures.secondLeftBorder:SetPoint('BOTTOMRIGHT', frame.castBar, 'BOTTOMLEFT', 0, -1.5);
  NamePlateCastingBarBorder.textures.secondLeftBorder:SetWidth(1.5);
  NamePlateCastingBarBorder.textures.secondLeftBorder:SetColorTexture(0, 0, 0, .2);

  -- third top
  NamePlateCastingBarBorder.textures.thirdTopBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.thirdTopBorder:SetPoint('BOTTOMRIGHT', frame.castBar, 'TOPRIGHT');
  NamePlateCastingBarBorder.textures.thirdTopBorder:SetPoint('BOTTOMLEFT', frame.castBar, 'TOPLEFT');
  NamePlateCastingBarBorder.textures.thirdTopBorder:SetHeight(1);
  NamePlateCastingBarBorder.textures.thirdTopBorder:SetColorTexture(0, 0, 0, .2);

  -- third right
  NamePlateCastingBarBorder.textures.thirdRightBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.thirdRightBorder:SetPoint('TOPLEFT', frame.castBar, 'TOPRIGHT', 0, 1);
  NamePlateCastingBarBorder.textures.thirdRightBorder:SetPoint('BOTTOMLEFT', frame.castBar, 'BOTTOMRIGHT', 0, -1);
  NamePlateCastingBarBorder.textures.thirdRightBorder:SetWidth(1);
  NamePlateCastingBarBorder.textures.thirdRightBorder:SetColorTexture(0, 0, 0, .2);

  -- third bottom
  NamePlateCastingBarBorder.textures.thirdBottomBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.thirdBottomBorder:SetPoint('TOPRIGHT', frame.castBar, 'BOTTOMLEFT');
  NamePlateCastingBarBorder.textures.thirdBottomBorder:SetPoint('TOPLEFT', frame.castBar, 'BOTTOMRIGHT');
  NamePlateCastingBarBorder.textures.thirdBottomBorder:SetHeight(1);
  NamePlateCastingBarBorder.textures.thirdBottomBorder:SetColorTexture(0, 0, 0, .2);

  -- third left
  NamePlateCastingBarBorder.textures.thirdLeftBorder = frame.castBar:CreateTexture(nil, 'BACKGROUND', -8);
  NamePlateCastingBarBorder.textures.thirdLeftBorder:SetPoint('TOPRIGHT', frame.castBar, 'TOPLEFT', 0, 1);
  NamePlateCastingBarBorder.textures.thirdLeftBorder:SetPoint('BOTTOMRIGHT', frame.castBar, 'BOTTOMLEFT', 0, -1);
  NamePlateCastingBarBorder.textures.thirdLeftBorder:SetWidth(1);
  NamePlateCastingBarBorder.textures.thirdLeftBorder:SetColorTexture(0, 0, 0, .2);

  function NamePlateCastingBarBorder:SetColorTexture(...) return end

  function NamePlateCastingBarBorder:SetVertexColor(...) return end

  function NamePlateCastingBarBorder:SetAlpha(...) return end

  return NamePlateCastingBarBorder;
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
  frame.healthBar.background:SetVertexColor(0, 0, 0, .4);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- remove default health bar border
  frame.healthBar.border:Hide();
  for _, texture in ipairs(frame.healthBar.border.Textures) do
    texture:SetTexture(nil);
  end
  wipe(frame.healthBar.border.Textures);

  SetBackdrop(frame.healthBar, BAR_BACKDROP);
  frame.healthBar:SetBackdropColor(1, 1, 1, 1);
  frame.healthBar:SetBackdropBorderColor(0, 0, 0, .85);

  -- and casting bar
  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0, 0, 0, .4);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border from template just like the one around the health bar
  SetBackdrop(frame.castBar, BAR_BACKDROP);
  frame.castBar:SetBackdropColor(1, 1, 1, 1);
  frame.castBar:SetBackdropBorderColor(0, 0, 0, .85);

  -- when using small nameplates move the text below the casting bar
  if (setupOptions.useLargeNameFont) then
    frame.castBar.Text:ClearAllPoints();
    frame.castBar.Text:SetAllPoints(frame.castBar);
  else
    frame.castBar.Text:ClearAllPoints();
    frame.castBar.Text:SetPoint('CENTER', frame.castBar, 'CENTER', 0, -16);
  end

  local fontName, fontSize, fontFlags = frame.castBar.Text:GetFont();
  frame.castBar.Text:SetFont(fontName, setupOptions.castBarFontHeight + 6, fontFlags);
end

function Addon:UpdateHealthColor(frame)
  if ((UnitExists(frame.unit) or UnitExists(frame.displayedUnit)) and frame.isTanking or IsTanking(frame.displayedUnit)) then
    -- color of name plate of unit targeting us
    local r, g, b = 1, 0, 1;

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

    if (UnitIsPlayer(frame.unit)) then
      local isPVP = UnitIsPVP(frame.unit);
      local faction = UnitFactionGroup(frame.unit);

      -- set unit player name
      if (InCombat(frame.unit)) then
        -- unit player in combat
        frame.name:SetText((isPVP and faction) and ICON[faction]..' '..name..' ('..level..') *' or name..' ('..level..') *');
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
        frame.name:SetText((classification ~= 'normal') and name..' (?? '..classification..')' or name..' (??) *');
      else
        frame.name:SetText((classification ~= 'normal') and name..' (?? '..classification..')' or name..' (??)');
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
        frame.name:SetText((classification ~= 'normal') and name..' ('..level..' '..classification..') *' or name..' ('..level..') *');
      else
        frame.name:SetText((classification ~= 'normal') and name..' ('..level..' '..classification..')' or name..' ('..level..')');
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

-- call
Addon:Load();

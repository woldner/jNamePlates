-- locals and speed
local AddonName, Addon = ...;

local _G = _G;
local pairs = pairs;

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
local ICON = {
  Alliance = '\124TInterface/PVPFrame/PVP-Currency-Alliance:16\124t',
  Horde = '\124TInterface/PVPFrame/PVP-Currency-Horde:16\124t'
}

-- helper functions
local function IsTanking(unit)
  local isTanking = UnitDetailedThreatSituation('player', unit);
  return isTanking;
end

local function InCombat(unit)
  return (UnitAffectingCombat(unit) and UnitCanAttack('player', unit));
end

local function IsOnThreatList(unit)
  local _, threatStatus = UnitDetailedThreatSituation('player', unit);
  return threatStatus ~= nil;
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

    -- disable the classification indicator on nameplates
    DefaultCompactNamePlateEnemyFrameOptions.showClassificationIndicator = false;

    -- override any enabled cvar
    C_Timer.After(.1, function ()
        -- disable class colors on enemy nameplates
        DefaultCompactNamePlateEnemyFrameOptions.useClassColors = false;

        -- set the selected border color on enemy nameplates
        DefaultCompactNamePlateEnemyFrameOptions.selectedBorderColor = CreateColor(0, 0, 0, 1);
        DefaultCompactNamePlateEnemyFrameOptions.tankBorderColor = CreateColor(0, 0, 0, 1);
        DefaultCompactNamePlateEnemyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 1);

        -- set the selected border color on friendly nameplates
        DefaultCompactNamePlateFriendlyFrameOptions.selectedBorderColor = CreateColor(0, 0, 0, 1);
        DefaultCompactNamePlateFriendlyFrameOptions.tankBorderColor = CreateColor(0, 0, 0, 1);
        DefaultCompactNamePlateFriendlyFrameOptions.defaultBorderColor = CreateColor(0, 0, 0, 1);
      end)

    -- always show names on nameplates
    for _, x in pairs({
        'Friendly',
        'Enemy'
      }) do
      for _, y in pairs({
          'displayNameWhenSelected',
          'displayNameByPlayerNameRules'
        }) do
        _G['DefaultCompactNamePlate'..x..'FrameOptions'][y] = false;
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

  local function Frame_UpdateHealthBorder(frame)
    Addon:UpdateHealthBorder(frame);
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
    hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', Frame_UpdateHealthBorder);
    hooksecurefunc('CompactUnitFrame_UpdateName', Frame_UpdateName);

    hooksecurefunc('CastingBarFrame_ApplyAlpha', Frame_ApplyAlpha);
  end
end

function Addon:SetupNamePlateInternal(frame, setupOptions, frameOptions)
  -- set bar color and textures for health bar
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.healthBar.background:SetVertexColor(0, 0, 0, .4);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- and cast bar
  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0, 0, 0, .4);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border from template just like the one around the health bar
  -- frame.castBar.border = CreateFrame('Frame', nil, frame.castBar, 'NamePlateSecondaryBarBorderTemplate');
  frame.castBar.border = CreateFrame('Frame', nil, frame.castBar, 'NamePlateFullBorderTemplate');

  -- when using small nameplates move the text below the cast bar
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

function Addon:UpdateHealthBorder(frame)
  if (frame.castBar and frame.castBar.border) then
    -- color of nameplate cast bar border
    local r, g, b, a = 0, 0, 0, 1;

    if (r ~= frame.castBar.border.r or g ~= frame.castBar.border.g or b ~= frame.castBar.border.b or a ~= frame.castBar.border.a) then
      frame.castBar.border:SetVertexColor(r, g, b, a);
    end
  end
end

function Addon:UpdateName(frame)
  if (ShouldShowName(frame) and frame.optionTable.colorNameBySelection) then
    local level = UnitLevel(frame.unit);
    local name = GetUnitName(frame.unit, false);

    if (UnitIsPlayer(frame.unit)) then
      local isPVP = UnitIsPVP(frame.unit);
      local faction = UnitFactionGroup(frame.unit);

      -- set unit player name
      if (InCombat(frame.unit)) then
        -- unit player in combat
        frame.name:SetText((isPVP and faction) and ICON[faction] .. ' ' .. name .. ' (' .. level .. ') *' or name .. ' (' .. level .. ') *');
      else
        -- unit player out of combat
        frame.name:SetText((isPVP and faction) and ICON[faction] .. ' ' .. name .. ' (' .. level .. ')' or name .. ' (' .. level .. ')');
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
        frame.name:SetText(name .. ' (??) *');
      else
        frame.name:SetText(name .. ' (??)');
      end

      -- set boss name color
      if (frame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatList(frame.displayedUnit)) then
        frame.name:SetVertexColor(1, 0, 0);
      elseif (UnitCanAttack('player', frame.unit)) then
        frame.name:SetVertexColor(1, .5, .5);
      else
        frame.name:SetVertexColor(.5, 1, .5);
      end
    else
      -- set name text
      if (InCombat(frame.unit)) then
        frame.name:SetText(name .. ' (' .. level .. ') *');
      else
        frame.name:SetText(name .. ' (' .. level .. ')');
      end

      -- set name color
      if (frame.optionTable.considerSelectionInCombatAsHostile and IsOnThreatList(frame.displayedUnit)) then
        frame.name:SetVertexColor(1, 0, 0);
      elseif (UnitCanAttack('player', frame.unit)) then
        frame.name:SetVertexColor(1, .5, .5);
      elseif (UnitIsPlayer(frame.unit)) then
        -- friendly player
        frame.name:SetVertexColor(1, 1, 1);
      else
        -- friendly npc
        frame.name:SetVertexColor(.5, 1, .5);
      end
    end

    if (UnitGUID('target') == nil) then
      frame:SetAlpha(1);
    else
      local nameplate = C_NamePlate.GetNamePlateForUnit('target');
      if (nameplate) then
        frame:SetAlpha(.5);
        nameplate.UnitFrame:SetAlpha(1);
      else
        -- we have a target but unit has no nameplate
        -- keep frames faded to indicate we have a target
        frame:SetAlpha(.5);
      end
    end
  end
end

do
  -- borrowed from CastingBarFrame.lua
  local function SetAlpha(frame, alpha)
    frame:SetAlpha(alpha);
    if (frame.additionalFadeWidgets) then
      for widget in pairs(frame.additionalFadeWidgets) do
        widget:SetAlpha(alpha);
      end
    end
  end

  function Addon:ApplyAlpha(frame, alpha)
    -- casting bar unit is friendly
    if (not UnitCanAttack('player', frame.unit) and alpha > 0) then
      if (UnitGUID('target') == nil) then
        SetAlpha(frame, alpha);
      else
        local nameplate = C_NamePlate.GetNamePlateForUnit('target');
        if (nameplate) then
          SetAlpha(nameplate.UnitFrame.castBar, alpha);
        end
      end
    end
  end
end

-- call
Addon:Load();

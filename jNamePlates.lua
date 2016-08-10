-- locals and speed
local AddonName, Addon = ...;

local _G = _G;
local pairs = pairs;
local select = select;

-- helper functions
local function IsTanking(unit)
  return select(1, UnitDetailedThreatSituation('player', unit));
end

local function InCombat(unit)
  return (UnitAffectingCombat(unit) and UnitCanAttack('player', unit));
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

    -- show class color on health bar for hostile opposite faction characters
    SetCVar('ShowClassColorInNameplate', 1);

    -- override any enabled cvar
    DefaultCompactNamePlateEnemyFrameOptions.useClassColors = true;

    -- disable the classification indicator on nameplates
    DefaultCompactNamePlateEnemyFrameOptions.showClassificationIndicator = false;

    -- set the selected border color on nameplates
    DefaultCompactNamePlateEnemyFrameOptions.selectedBorderColor = CreateColor(1.0, 0.0, 0.0, 1.0);

    -- prevent nameplates from fading when you move away
    SetCVar('nameplateMaxAlpha', 1);
    SetCVar('nameplateMinAlpha', 1);

    -- Prevent nameplates from getting smaller when you move away
    SetCVar('nameplateMaxScale', 1);
    SetCVar('nameplateMinScale', 1);

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
  local function Frame_SetupNamePlate(frame, setupOptions, frameOptions)
    Addon:SetupNamePlate(frame, setupOptions, frameOptions);
  end

  local function Frame_UpdateHealthColor(frame)
    Addon:UpdateHealthColor(frame);
  end

  local function Frame_UpdateName(frame)
    Addon:UpdateName(frame);
  end

  function Addon:HookActionEvents()
    hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlate);
    hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateHealthColor);
    hooksecurefunc('CompactUnitFrame_UpdateName', Frame_UpdateName);
  end
end

function Addon:SetupNamePlate(frame, setupOptions, frameOptions)
  -- set bar color and textures for health bar
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.healthBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.33);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- and cast bar
  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.33);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border from template just like the one around the health bar
  frame.castBar.border = CreateFrame('Frame', nil, frame.castBar, 'NamePlateFullBorderTemplate');
  frame.castBar.border:SetVertexColor(0.0, 0.0, 0.0, 0.8);
end

function Addon:UpdateHealthColor(frame)
  if (UnitExists(frame.unit) and frame.isTanking or IsTanking(frame.unit)) then
    -- color of name plate of unit targeting us
    local r, g, b = 1.0, 0.0, 1.0;

    if (r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b) then
      frame.healthBar:SetStatusBarColor(r, g, b);
      frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
    end
  end
end

function Addon:UpdateName(frame)
  if (ShouldShowName(frame) and frame.optionTable.colorNameBySelection) then
    local level = UnitLevel(frame.unit);
    if (level == -1) then
      if (InCombat(frame.unit)) then
        frame.name:SetText(GetUnitName(frame.unit, true)..'* (??)');
      else
        frame.name:SetText(GetUnitName(frame.unit, true)..' (??)');
      end
    else
      if (InCombat(frame.unit)) then
        frame.name:SetText(GetUnitName(frame.unit, true)..'* ('..level..')');
      else
        frame.name:SetText(GetUnitName(frame.unit, true)..' ('..level..')');
      end
    end

    if (UnitGUID('target') == nil) then
      frame.healthBar:SetAlpha(1.0);
    else
      local nameplate = C_NamePlate.GetNamePlateForUnit('target');
      if (nameplate) then
        frame.healthBar:SetAlpha(0.5);
        nameplate.UnitFrame.healthBar:SetAlpha(1.0);
      end
    end

    if (IsTanking(frame.unit)) then
      frame.name:SetVertexColor(1.0, 0.0, 0.0);
    else
      frame.name:SetVertexColor(1.0, 1.0, 1.0);
    end
  end
end

-- call
Addon:Load();

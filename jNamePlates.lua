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

    -- prevent nameplates from fading when you move away
    SetCVar('nameplateMaxAlpha', 1);
    SetCVar('nameplateMinAlpha', 1);

    -- Prevent nameplates from getting smaller when you move away
    SetCVar('nameplateMaxScale', 1);
    SetCVar('nameplateMinScale', 1);

    -- override any enabled cvar
    C_Timer.After(.1, function ()
        -- enable class colors on enemy nameplates
        DefaultCompactNamePlateEnemyFrameOptions.useClassColors = true;

        -- disable the classification indicator on nameplates
        DefaultCompactNamePlateEnemyFrameOptions.showClassificationIndicator = false;

        -- set the selected border color on enemy nameplates
        DefaultCompactNamePlateEnemyFrameOptions.selectedBorderColor = CreateColor(0, 0, 0, 1);

        -- set the selected border color on friendly nameplates
        DefaultCompactNamePlateFriendFrameOptions.selectedBorderColor = CreateColor(0, 0, 0, 1);
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
  local function Frame_SetupNamePlate(frame, setupOptions, frameOptions)
    Addon:SetupNamePlate(frame, setupOptions, frameOptions);
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

  function Addon:HookActionEvents()
    hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlate);
    hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateHealthColor);
    hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', Frame_UpdateHealthBorder);
    hooksecurefunc('CompactUnitFrame_UpdateName', Frame_UpdateName);
  end
end

function Addon:SetupNamePlate(frame, setupOptions, frameOptions)
  -- set bar color and textures for health bar
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.healthBar.background:SetVertexColor(0, 0, 0, .4);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- and cast bar
  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0, 0, 0, .4);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border from template just like the one around the health bar
  frame.castBar.border = CreateFrame('Frame', nil, frame.castBar, 'NamePlateFullBorderTemplate');
  frame.castBar.border:SetVertexColor(0, 0, 0, 1);
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
    -- color of nameplate castbar border
    local r, g, b = 0, 0, 0;

    if (r ~= frame.castBar.border.r or g ~= frame.castBar.border.g or b ~= frame.castBar.border.b) then
      frame.castBar.border:SetVertexColor(r, g, b);
    end
  end
end

function Addon:UpdateName(frame)
  if (ShouldShowName(frame) and frame.optionTable.colorNameBySelection) then
    local level = UnitLevel(frame.unit);
    local name = GetUnitName(frame.unit, false);

    if (level == -1) then
      if (InCombat(frame.unit)) then
        frame.name:SetText(name..'* (??)');
      else
        frame.name:SetText(name..' (??)');
      end
    else
      if (InCombat(frame.unit)) then
        frame.name:SetText(name..'* ('..level..')');
      else
        frame.name:SetText(name..' ('..level..')');
      end
    end

    if (UnitGUID('target') == nil) then
      frame.healthBar:SetAlpha(1);
      frame.name:SetAlpha(1);
    else
      local nameplate = C_NamePlate.GetNamePlateForUnit('target');
      if (nameplate) then
        frame.healthBar:SetAlpha(.3);
        frame.name:SetAlpha(.5);

        nameplate.UnitFrame.healthBar:SetAlpha(1);
        nameplate.UnitFrame.name:SetAlpha(1);
      else
        -- we have a target but unit has no nameplate
        -- keep frames faded
        frame.healthBar:SetAlpha(.3);
        frame.name:SetAlpha(.5);
      end
    end

    if (IsTanking(frame.displayedUnit)) then
      frame.name:SetVertexColor(1, 0, 0);
    else
      frame.name:SetVertexColor(1, 1, 1);
    end
  end
end

-- call
Addon:Load();

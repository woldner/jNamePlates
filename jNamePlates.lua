-- locals
local AddonName, Addon = ...;

-- helper functions
local function IsTanking(unit)
  return select(1, UnitDetailedThreatSituation('player', unit));
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
  self:HookActionEvents();
end

-- hooks
do
  local function Frame_SetupNamePlate(frame, setupOptions, frameOptions)
    Addon:SetupNamePlate(frame, setupOptions, frameOptions);
  end

  local function Frame_UpdateHealthColor(frame)
    Addon:UpdateHealthColor(frame);
  end

  function Addon:HookActionEvents()
    hooksecurefunc('DefaultCompactNamePlateFrameSetupInternal', Frame_SetupNamePlate);
    hooksecurefunc('CompactUnitFrame_UpdateHealthColor', Frame_UpdateHealthColor);
  end
end

function Addon:SetupNamePlate(frame, setupOptions, frameOptions)
  -- set bar color and textures for health- and cast bar
  frame.healthBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.healthBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
  frame.healthBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  frame.castBar.background:SetTexture('Interface\\TargetingFrame\\UI-StatusBar');
  frame.castBar.background:SetVertexColor(0.0, 0.0, 0.0, 0.2);
  frame.castBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar');

  -- create a border from template just like the one around the health bar
  frame.castBar.border = CreateFrame('Frame', nil, frame.castBar, 'NamePlateFullBorderTemplate');

  -- disable the classification indicator if enabled
  if (frame.optionTable.showClassificationIndicator) then
    frame.optionTable.showClassificationIndicator = false;
  end
end

function Addon:UpdateHealthColor(frame)
  if (UnitExists(frame.unit) and frame.isTanking or IsTanking(frame.displayedUnit)) then
    -- color of name plate of unit targeting us
    local r, g, b = 1.0, 0.0, 1.0;

    if (r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b) then
      frame.healthBar:SetStatusBarColor(r, g, b);
      frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b;
    end
  end
end

-- call
Addon:Load();

DNotify = { }
DNotify.RegisteredThinks = { }
DNotify.NotificationsSlideLeft = { }
DNotify.NotificationsSlideRight = { }
local X_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '0', {
  FCVAR_ARCHIVE
}, 'Shift at X of DNotify slide notifications')
local Y_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '15', {
  FCVAR_ARCHIVE
}, 'Shift at Y of DNotify slide notifications')
DNOTIFY_SIDE_LEFT = 1
DNOTIFY_SIDE_RIGHT = 2
DNOTIFY_POS_TOP = 3
DNOTIFY_POS_BOTTOM = 4
DNotify.newLines = function(str)
  if str == nil then
    str = ''
  end
  return string.Explode('\n', str)
end
DNotify.allowedOrign = function(enum)
  return enum == TEXT_ALIGN_LEFT or enum == TEXT_ALIGN_RIGHT or enum == TEXT_ALIGN_CENTER
end
local HUDPaint
HUDPaint = function()
  local yShift = 0
  local x = X_SHIFT_CVAR:GetInt()
  local y = Y_SHIFT_CVAR:GetInt()
  for k, func in pairs(DNotify.NotificationsSlideLeft) do
    if func:IsValid() then
      local status, currShift = pcall(func.Draw, func, x, y + yShift)
      if status then
        yShift = yShift + currShift
      else
        print('[DNotify] ERROR ', currShift)
      end
    else
      DNotify.NotificationsSlideLeft[k] = nil
    end
  end
  yShift = 0
  x = ScrW() - X_SHIFT_CVAR:GetInt()
  y = Y_SHIFT_CVAR:GetInt()
  for k, func in pairs(DNotify.NotificationsSlideRight) do
    if func:IsValid() then
      local status, currShift = pcall(func.Draw, func, x, y + yShift)
      if status then
        yShift = yShift + currShift
      else
        print('[DNotify] ERROR ', currShift)
      end
    else
      DNotify.NotificationsSlideRight[k] = nil
    end
  end
end
local Think
Think = function()
  for k, func in pairs(DNotify.RegisteredThinks) do
    if func:IsValid() then
      func:Think()
    else
      DNotify.RegisteredThinks[k] = nil
    end
  end
end
hook.Add('HUDPaint', 'DNotify', HUDPaint)
hook.Add('Think', 'DNotify', Think)
include('dnotify/font_obj.lua')
include('dnotify/base_class.lua')
include('dnotify/slide_class.lua')
return nil

DNotify = { }
DNotify.DefaultDispatchers = { }
local X_SHIFT_CVAR = CreateConVar('dnofity_x_shift', '0', {
  FCVAR_ARCHIVE
}, 'Shift at X of DNotify slide notifications')
local Y_SHIFT_CVAR = CreateConVar('dnofity_y_shift', '45', {
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
DNotify.allowedOrigin = function(enum)
  return enum == TEXT_ALIGN_LEFT or enum == TEXT_ALIGN_RIGHT or enum == TEXT_ALIGN_CENTER
end
DNotify.Clear = function()
  for i, obj in pairs(DNotify.DefaultDispatchers) do
    obj:Clear()
  end
end
DNotify.CreateSlide = function(...)
  return DNotify.DefaultDispatchers.slide:Create(...)
end
DNotify.CreateCentered = function(...)
  return DNotify.DefaultDispatchers.center:Create(...)
end
DNotify.CreateDefaultDispatchers = function()
  DNotify.DefaultDispatchers = { }
  local slideData = {
    x = X_SHIFT_CVAR:GetInt(),
    getx = function(self)
      return X_SHIFT_CVAR:GetInt()
    end,
    y = Y_SHIFT_CVAR:GetInt(),
    gety = function(self)
      return Y_SHIFT_CVAR:GetInt()
    end,
    width = ScrW(),
    height = ScrH(),
    getheight = ScrH,
    getwidth = ScrW
  }
  local centerData = {
    x = 0,
    y = 0,
    width = ScrW(),
    height = ScrH(),
    getheight = ScrH,
    getwidth = ScrW
  }
  DNotify.DefaultDispatchers.slide = DNotify.SlideNotifyDispatcher(slideData)
  DNotify.DefaultDispatchers.center = DNotify.CenteredNotifyDispatcher(centerData)
end
local HUDPaint
HUDPaint = function()
  for i, dsp in pairs(DNotify.DefaultDispatchers) do
    dsp:Draw()
  end
end
local Think
Think = function()
  for i, dsp in pairs(DNotify.DefaultDispatchers) do
    dsp:Think()
  end
end
hook.Add('HUDPaint', 'DNotify', HUDPaint)
hook.Add('Think', 'DNotify', Think)
timer.Simple(0, DNotify.CreateDefaultDispatchers)
include('dnotify/font_obj.lua')
include('dnotify/base_class.lua')
include('dnotify/templates.lua')
include('dnotify/animated_base.lua')
include('dnotify/slide_class.lua')
include('dnotify/centered_class.lua')
return nil

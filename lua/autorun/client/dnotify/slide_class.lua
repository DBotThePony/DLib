local insert, remove
do
  local _obj_0 = table
  insert, remove = _obj_0.insert, _obj_0.remove
end
local newLines, allowedOrign, DNotifyBase, DNotifyAnimated
do
  local _obj_0 = DNotify
  newLines, allowedOrign, DNotifyBase, DNotifyAnimated = _obj_0.newLines, _obj_0.allowedOrign, _obj_0.DNotifyBase, _obj_0.DNotifyAnimated
end
surface.CreateFont('DNotifySlide', {
  font = 'Roboto',
  size = 16,
  weight = 500
})
local SlideNotify
do
  local _class_0
  local _parent_0 = DNotifyAnimated
  local _base_0 = {
    GetBackgroundColor = function(self)
      return self.m_backgroundColor
    end,
    GetBackColor = function(self)
      return self.m_backgroundColor
    end,
    ShouldDrawBackground = function(self)
      return self.m_background
    end,
    ShouldDrawBack = function(self)
      return self.m_background
    end,
    GetSide = function(self)
      return self.m_side
    end,
    Start = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      if self.m_isDrawn then
        return self
      end
      if self.m_animated and self.m_animin then
        self.m_shift = -(self.m_sizeOfTextX * 1.2)
      else
        self.m_shift = 0
      end
      if self.m_side == DNOTIFY_SIDE_RIGHT then
        self.m_shift = -self.m_shift
      end
      if self.m_side == DNOTIFY_SIDE_LEFT then
        insert(DNotify.NotificationsSlideLeft, self)
      else
        insert(DNotify.NotificationsSlideRight, self)
      end
      return _class_0.__parent.__base.Start(self)
    end,
    SetBackgroundColor = function(self, val)
      if val == nil then
        val = Color(255, 255, 255)
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(val.r and val.g and val.b and val.a, 'Not a valid color')
      self.m_backgroundColor = val
      return self
    end,
    SetSide = DNotify.SetSideFunc,
    SetShouldDrawBackground = function(self, val)
      if val == nil then
        val = true
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(type(val) == 'boolean', 'must be a boolean')
      self.m_background = val
      return self
    end,
    SetText = function(self, ...)
      _class_0.__parent.__base.SetText(self, ...)
      self:CalculateTimer()
      return self
    end,
    CalculateTimer = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      local newLen = 2
      for i, object in pairs(self.m_text) do
        if type(object) == 'string' then
          newLen = newLen + ((#object) ^ (1 / 2))
        end
      end
      self:SetLength(math.Clamp(newLen, 4, 10))
      return self
    end,
    Draw = function(self, x, y)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      local SetTextPos, SetDrawColor, DrawRect, SetFont, SetTextColor, DrawText
      do
        local _obj_0 = surface
        SetTextPos, SetDrawColor, DrawRect, SetFont, SetTextColor, DrawText = _obj_0.SetTextPos, _obj_0.SetDrawColor, _obj_0.DrawRect, _obj_0.SetFont, _obj_0.SetTextColor, _obj_0.DrawText
      end
      x = x + self.m_shift
      if self.m_side == DNOTIFY_SIDE_RIGHT then
        x = x - (self.m_sizeOfTextX + 4)
      end
      SetTextPos(x + 2, y + 2)
      if self.m_background then
        SetDrawColor(self.m_backgroundColor)
        DrawRect(x, y, self.m_sizeOfTextX + 4, self.m_sizeOfTextY + 4)
      end
      for i, line in pairs(self.m_cache) do
        local lineX = line.lineX
        local shiftX = line.shiftX
        local maxY = line.maxY
        local nextY = line.nextY
        for i, strData in pairs(line.content) do
          SetFont(strData.font)
          if self.m_shadow then
            SetTextColor(0, 0, 0)
            SetTextPos(x + shiftX + strData.x + 2 + self.m_shadowSize, y + nextY + 2 + self.m_shadowSize)
            DrawText(strData.content)
          end
          SetTextColor(strData.color)
          SetTextPos(x + shiftX + strData.x + 2, y + nextY + 2)
          DrawText(strData.content)
        end
      end
      return self.m_sizeOfTextY + 4
    end,
    ThinkTimer = function(self, deltaThink, cTime)
      if self.m_animated then
        local deltaIn = self.m_start + 1 - cTime
        local deltaOut = cTime - self.m_finish
        if deltaIn >= 0 and deltaIn <= 1 and self.m_animin then
          self.m_shift = -(self.m_sizeOfTextX * 1.2) * deltaIn
        elseif deltaOut >= 0 and deltaOut < 1 and self.m_animout then
          self.m_shift = -(self.m_sizeOfTextX * 1.2) * deltaOut
        else
          self.m_shift = 0
        end
      else
        self.m_shift = 0
      end
      if self.m_side == DNOTIFY_SIDE_RIGHT then
        self.m_shift = -self.m_shift
      end
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      self.m_side = DNOTIFY_SIDE_LEFT
      self.m_defSide = DNOTIFY_SIDE_LEFT
      self.m_allowedSides = {
        DNOTIFY_SIDE_LEFT,
        DNOTIFY_SIDE_RIGHT
      }
      self.m_shift = -150
      self.m_background = true
      self.m_backgroundColor = Color(0, 0, 0, 150)
      self.m_shadow = false
      self.m_font = 'DNotifySlide'
      _class_0.__parent.__init(self, ...)
      return self:CalculateTimer()
    end,
    __base = _base_0,
    __name = "SlideNotify",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  SlideNotify = _class_0
end
DNotify.Slide = SlideNotify
DNotify.slide = SlideNotify
DNotify.SlideNotify = SlideNotify

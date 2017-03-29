local insert, remove
do
  local _obj_0 = table
  insert, remove = _obj_0.insert, _obj_0.remove
end
local newLines, allowedOrign
do
  local _obj_0 = DNotify
  newLines, allowedOrign = _obj_0.newLines, _obj_0.allowedOrign
end
local DNotifyBase
do
  local _class_0
  local _base_0 = {
    GetAlign = function(self)
      return self.m_align
    end,
    GetTextAlign = function(self)
      return self.m_align
    end,
    GetSound = function(self)
      return self.m_sound
    end,
    HasSound = function(self)
      return self.m_sound ~= ''
    end,
    GetStart = function(self)
      return self.m_start
    end,
    GetLength = function(self)
      return self.m_length
    end,
    GetFinishFinal = function(self)
      return self.m_finishFinal
    end,
    FinishesOn = function(self)
      return self.m_finish
    end,
    StopsOn = function(self)
      return self.m_finish
    end,
    IsTimer = function(self)
      return self.m_timer
    end,
    GetText = function(self)
      return self.m_text
    end,
    GetFont = function(self)
      return self.m_font
    end,
    GetColor = function(self)
      return self.m_color
    end,
    GetColor = function(self)
      return self.m_color
    end,
    GetDrawShadow = function(self)
      return self.m_shadow
    end,
    GetShadowSize = function(self)
      return self.m_shadowSize
    end,
    IsValid = function(self)
      return self.m_isValid
    end,
    Start = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      if self.m_isDrawn then
        return self
      end
      self.m_isDrawn = true
      if self.m_sound ~= '' then
        surface.PlaySound(self.m_sound)
      end
      self:SetStart()
      insert(DNotify.RegisteredThinks, self)
      return self
    end,
    Remove = function(self)
      if not self.m_isDrawn then
        return false
      end
      self.m_isValid = false
      return true
    end,
    SetAlign = function(self, val)
      if val == nil then
        val = TEXT_ALIGN_LEFT
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(allowedOrign(val), 'Not a valid align')
      self.m_align = val
      self:CompileCache()
      return self
    end,
    SetTextAlign = function(self, ...)
      return self:SetAlign(...)
    end,
    SetDrawShadow = function(self, val)
      if val == nil then
        val = true
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(type(val) == 'boolean', 'must be boolean')
      self.m_shadow = val
      return self
    end,
    SetShadowSize = function(self, val)
      if val == nil then
        val = 2
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(type(val) == 'number', 'must be number')
      self.m_shadowSize = val
      return self
    end,
    SetColor = function(self, val)
      if val == nil then
        val = Color(255, 255, 255)
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(val.r and val.g and val.b and val.a, 'Not a valid color')
      self.m_color = val
      return self
    end,
    FixFont = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      local result = pcall(surface.SetFont, self.m_font)
      if not result then
        print('[DNotify] ERROR: Invalid font: ' .. self.m_font)
        print(debug.traceback())
        self.m_font = 'Default'
      end
      return self
    end,
    SetFont = function(self, val)
      if val == nil then
        val = 'Default'
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      self.m_font = val
      self:FixFont()
      self.m_fontobj:SetFont(val)
      self:CompileCache()
      return self
    end,
    __setTextInternal = function(self, tab)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      self.m_text = { }
      for i, value in pairs(tab) do
        if type(value) == 'table' and value.r and value.g and value.b and value.a then
          insert(self.m_text, value)
        elseif type(value) == 'string' then
          insert(self.m_text, value)
        end
      end
    end,
    SetText = function(self, ...)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      local tryTable = {
        ...
      }
      local tryFirst = tryTable[1]
      if type(tryFirst) == 'string' then
        self:__setTextInternal(tryTable)
        return self
      elseif type(tryFirst) == 'table' then
        if (not tryFirst.r or not tryFirst.g or not tryFirst.b or not tryFirst.a) and not tryFirst.m_dnotify_type then
          self:__setTextInternal(tryFirst)
        else
          self:__setTextInternal(tryTable)
        end
        return self
      else
        error('Unknown argument!')
      end
      self:CompileCache()
      return self
    end,
    SetStart = function(self, val, resetTimer)
      if val == nil then
        val = CurTime()
      end
      if resetTimer == nil then
        resetTimer = true
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(type(val) == 'number', '#1 must be a number')
      assert(type(resetTimer) == 'boolean', '#2 must be a boolean')
      self.m_start = val
      if resetTimer then
        self:ResetTimer()
      end
      return self
    end,
    ClearSound = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      self.m_sound = ''
      return self
    end,
    SetSound = function(self, newSound)
      if newSound == nil then
        newSound = ''
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(type(newSound) == 'string', 'SetSound - must be a string')
      self.m_sound = newSound
      return self
    end,
    ResetTimer = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      self.m_start = CurTime()
      self.m_finish = self.m_start + self.m_length
      self.m_finishFinal = self.m_finish + 1
      return self
    end,
    StopTimer = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      self.m_timer = false
      return self
    end,
    StartTimer = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      self.m_timer = true
      return self
    end,
    SetLength = function(self, new)
      if new == nil then
        new = 4
      end
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      assert(type(new) == 'number', 'must be a number')
      if new < 3 then
        new = 3
      end
      self.m_length = new
      self.m_lengthFinal = new + 1
      self:ResetTimer()
      return self
    end,
    SetThink = function(self, val)
      if val == nil then
        val = (function() end)
      end
      assert(type(val) == 'function', 'must be a function')
      self.m_thinkf = val
      return self
    end,
    CompileCache = function(self)
      self.m_cache = { }
      self.m_sizeOfTextX = 0
      self.m_sizeOfTextY = 0
      local lineX = 0
      local maxX = 0
      local maxY = 0
      local nextY = 0
      local currentLine = { }
      local lastColor = self.m_color
      local lastFont = self.m_font
      surface.SetFont(self.m_font)
      for i, object in pairs(self.m_text) do
        if type(object) == 'table' then
          if object.m_dnotify_type then
            if object.m_dnotify_type == 'font' then
              surface.SetFont(object:GetFont())
              lastFont = object:GetFont()
            end
          else
            lastColor = object
          end
        elseif type(object) == 'string' then
          local split = newLines(object)
          local first = true
          for i, str in pairs(split) do
            local sizeX, sizeY = surface.GetTextSize(str)
            if not first then
              maxY = maxY + 4
              insert(self.m_cache, {
                content = currentLine,
                lineX = lineX,
                shiftX = 0,
                maxY = maxY,
                nextY = nextY
              })
              currentLine = { }
              self.m_sizeOfTextY = self.m_sizeOfTextY + maxY
              nextY = nextY + maxY
              if lineX > maxX then
                maxX = lineX
              end
              lineX = 0
              maxY = 0
            end
            first = false
            insert(currentLine, {
              color = lastColor,
              content = str,
              x = lineX,
              font = lastFont
            })
            lineX = lineX + sizeX
            if sizeY > maxY then
              maxY = sizeY
            end
          end
        end
      end
      self.m_sizeOfTextY = self.m_sizeOfTextY + maxY
      insert(self.m_cache, {
        content = currentLine,
        lineX = lineX,
        shiftX = 0,
        maxY = maxY,
        nextY = nextY
      })
      self.m_sizeOfTextX = maxX
      if self.m_align == TEXT_ALIGN_RIGHT then
        for i, line in pairs(self.m_cache) do
          line.shiftX = self.m_sizeOfTextX - line.lineX
        end
      elseif self.m_align == TEXT_ALIGN_CENTER then
        for i, line in pairs(self.m_cache) do
          line.shiftX = (self.m_sizeOfTextX - line.lineX) / 2
        end
      end
      return self
    end,
    Draw = function(self, x, y)
      if x == nil then
        x = 0
      end
      if y == nil then
        y = 0
      end
      print('Non overriden version!')
      print(debug.traceback())
      return 0
    end,
    Think = function(self)
      assert(self:IsValid(), 'tried to use a finished Slide Notification!')
      local deltaThink = CurTime() - self.m_lastThink
      if not self.m_timer then
        self.m_created = self.m_created + deltaThink
        self.m_finish = self.m_finish + deltaThink
        self.m_finishFinal = self.m_finishFinal + deltaThink
        if self.ThinkNotTimer then
          self:ThinkNotTimer(deltaThink)
        end
      else
        local cTime = CurTime()
        if self.m_finishFinal <= cTime then
          self:Remove()
          return false
        end
        if self.ThinkTimer then
          self:ThinkTimer(deltaThink, cTime)
        end
      end
      if self.m_thinkf then
        self:m_thinkf()
      end
      return self
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, contents)
      if contents == nil then
        contents = {
          'Sample Text'
        }
      end
      if type(contents) == 'string' then
        contents = {
          contents
        }
      end
      self.m_text = contents
      if not self.m_sound then
        self.m_sound = ''
      end
      if not self.m_font then
        self.m_font = 'Default'
      end
      if not self.m_color then
        self.m_color = Color(255, 255, 255)
      end
      if not self.m_length then
        self.m_length = 4
      end
      self.m_lastThink = CurTime()
      self.m_created = self.m_lastThink
      self.m_start = self.m_created
      self.m_finish = self.m_start + self.m_length
      self.m_timer = true
      if not self.m_align then
        self.m_align = TEXT_ALIGN_LEFT
      end
      self.m_isDrawn = false
      self.m_isValid = true
      if self.m_shadow == nil then
        self.m_shadow = true
      end
      if self.m_shadowSize == nil then
        self.m_shadowSize = 2
      end
      self.m_fontobj = DNotify.Font(self.m_font)
      return self:CompileCache()
    end,
    __base = _base_0,
    __name = "DNotifyBase"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DNotifyBase = _class_0
end
DNotify.DNotifyBase = DNotifyBase

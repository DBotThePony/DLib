local DNotifyFont
do
  local _class_0
  local _base_0 = {
    Setup = function(self)
      surface.SetFont(self.m_font)
      local x, y = surface.GetTextSize('W')
      self.m_height = y
    end,
    FixFont = function(self)
      if not self.IsValidFont(self.m_font) then
        self.m_font = 'Default'
      end
      return self
    end,
    IsValidFont = function(font)
      local result = pcall(surface.SetFont, font)
      return result
    end,
    SetFont = function(self, val)
      if val == nil then
        val = 'Default'
      end
      self.m_font = val
      self:FixFont()
      self:Setup()
      return self
    end,
    GetFont = function(self)
      return self.m_font
    end,
    GetTextSize = function(self, text)
      assert(type(text) == 'string', 'Not a string')
      surface.SetFont(self.m_font)
      return self
    end,
    GetHeight = function(self)
      return self.m_height
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, val)
      if val == nil then
        val = 'Default'
      end
      self.m_font = val
      self.m_dnotify_type = 'font'
      return self:FixFont()
    end,
    __base = _base_0,
    __name = "DNotifyFont"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  DNotifyFont = _class_0
end
DNotify.Font = DNotifyFont

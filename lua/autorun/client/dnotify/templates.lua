local HasValue
HasValue = table.HasValue
DNotify.SetSideFunc = function(self, val, affectAlign)
  if val == nil then
    val = self.m_defSide
  end
  if affectAlign == nil then
    affectAlign = true
  end
  assert(self:IsValid(), 'tried to use a finished Slide Notification!')
  assert(HasValue(self.m_allowedSides, val), 'Only left or right sides are allowed')
  assert(type(affectAlign) == 'boolean', 'Only left or right sides are allowed')
  assert(not self.m_isDrawn, 'Can not change side while drawing')
  self.m_side = val
  if affectAlign and val == DNOTIFY_SIDE_RIGHT then
    self:SetAlign(TEXT_ALIGN_RIGHT)
  elseif affectAlign and val == DNOTIFY_SIDE_LEFT then
    self:SetAlign(TEXT_ALIGN_LEFT)
  end
  return self
end

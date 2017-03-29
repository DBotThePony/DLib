
--
-- Copyright (C) 2017 DBot
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 

import HasValue from table

DNotify.SetSideFunc = (val = @m_defSide, affectAlign = true) =>
	assert(@IsValid!, 'tried to use a finished Slide Notification!')
	assert(HasValue(@m_allowedSides, val), 'Only left or right sides are allowed')
	assert(type(affectAlign) == 'boolean', 'Only left or right sides are allowed')
	assert(not @m_isDrawn, 'Can not change side while drawing')
	@m_side = val
	
	if affectAlign and val == DNOTIFY_SIDE_RIGHT
		@SetAlign(TEXT_ALIGN_RIGHT)
	elseif affectAlign and val == DNOTIFY_SIDE_LEFT
		@SetAlign(TEXT_ALIGN_LEFT)
	
	return @
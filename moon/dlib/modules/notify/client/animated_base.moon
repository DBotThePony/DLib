
--
-- Copyright (C) 2017-2018 DBot
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

import insert, remove from table
import newLines, allowedOrign, NotifyBase from Notify

class NotifyAnimated extends NotifyBase
	new: (...) =>
		super(...)
		@m_animated = true
		@m_animin = true
		@m_animout = true

		@m_lengthFinal = 5
		@m_finishFinal = @m_finish + 1

	GetAnimated: => @m_animated
	GetIsAnimated: => @m_animated
	GetAnimatedIn: => @m_animin
	GetAnimatedOut: => @m_animout
	GetFinishFinal: => @m_finishFinal

	ResetTimer: =>
		super!
		@m_finishFinal = @m_finish + 1
		return @

	SetLength: (new = 4) =>
		super(new)
		@m_lengthFinal = new + 1
		return @

	ResetTimer: =>
		super!
		@m_finishFinal = @m_finish + 1
		return @

	SetAnimatedOut: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_animout = val
		return @

	SetAnimatedIn: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_animin = val
		return @

	SetAnimated: (val = true) =>
		assert(@IsValid!, 'tried to use a finished Slide Notification!')
		assert(type(val) == 'boolean', 'must be a boolean')
		@m_animated = val
		return @

	SetFinish: (new = CurTimeL! + 4) =>
		super(new)
		@m_finishFinal = @m_finish + 1
		return @

	ThinkNotTimer: (deltaThink) =>
		@m_finishFinal += deltaThink

	GetNonValidTime: => @m_finishFinal

Notify.NotifyAnimated = NotifyAnimated


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

class DLib.SequenceBase
	new: (parent, data) =>
		{
			'name': @name
			'repeat': @dorepeat
			'frames': @frames
			'time': @time
			'func': @func
			'reset': @resetfunc
			'create': @createfunc
		} = data

		@valid = false
		@paused = false
		@pausedSequences = {}
		@deltaAnim = 1
		@speed = 1
		@scale = 1
		@frame = 0
		@start = RealTime()
		@finish = @start + @time
		@parent = parent

	Launch: =>
		@valid = true
		@createfunc() if @createfunc
		@resetfunc() if @resetfunc

	__tostring: => "[#{@@__name}:#{@name}]"

	SetTime: (newTime = @time, refresh = true) =>
		@frame = 0
		@start = RealTime() if refresh
		@time = newTime
		@finish = @start + @time

	SetInfinite: (val) => @dorepeat = val
	SetIsInfinite: (val) => @dorepeat = val
	GetInfinite: => @dorepeat
	GetIsInfinite: => @dorepeat

	Reset: =>
		@frame = 0
		@start = RealTime()
		@finish = @start + @time
		@deltaAnim = 1
		@resetfunc() if @resetfunc

	GetName: => @name
	GetRepeat: => @dorepeat
	GetFrames: => @frames
	GetFrame: => @frames
	GetTime: => @time
	GetThinkFunc: => @func
	GetCreatFunc: => @createfunc
	GetSpeed: => @speed
	GetAnimationSpeed: => @speed
	GetScale: => @scale
	IsValid: => @valid

	Think: (delta = 0) =>
		if @paused
			@finish += delta
			@start += delta
		else
			if @HasFinished()
				@Stop()
				return false

			@deltaAnim = (@finish - RealTime()) / @time
			if @deltaAnim < 0
				@deltaAnim = 1
				@frame = 0
				@start = RealTime()
				@finish = @start + @time
			@frame += 1

			if @func
				status = @func(delta, 1 - @deltaAnim)
				if status == false
					@Stop()
					return false

		return true

	Pause: =>
		return false if @paused
		@paused = true
		return true

	Resume: =>
		return false if not @paused
		@paused = false
		return true

	PauseSequence: (id = '') =>
		@pausedSequences[id] = true
		@parent\PauseSequence(id) if @parent

	ResumeSequence: (id = '') =>
		@pausedSequences[id] = false
		@parent\ResumeSequence(id) if @parent

	Stop: =>
		for id, bool in pairs @pausedSequences
			@controller\ResumeSequence(id) if bool
		@valid = false

	Remove: => @Stop()

	HasFinished: =>
		return false if @dorepeat
		return RealTime() > @finish

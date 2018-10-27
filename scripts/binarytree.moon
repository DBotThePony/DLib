
-- Copyright (C) 2018 DBot

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

import math from _G

class BinaryTree
	new: (key, value, parent, left, right) =>
		@left = left
		@right = right
		@key = assert(type(key) == 'number' and key, 'Key must be a number')
		@value = value
		@parent = parent

	Comparable: => @key

	CalculateDepth: =>
		if @left and @right
			return math.max(@left\CalculateDepth(), @right\CalculateDepth()) + 1
		elseif @left
			return @left\CalculateDepth() + 1
		elseif @right
			return @right\CalculateDepth() + 1

		return 0

	iterate: =>
		sret = false
		doright = false
		doleft = false
		local cgen

		return ->
			if not sret
				sret = true
				return @value

			return if not @left and not @right

			if not cgen
				if @left
					doleft = true
					cgen = @left\iterate()
				elseif @right
					doright = true
					cgen = @right\iterate()

			val = cgen()

			if val == nil
				return if doright and doleft

				if not doleft and @left
					doleft = true
					cgen = @left\iterate()
				elseif not doright and @right
					doright = true
					cgen = @right\iterate()
				else
					return

				val = cgen()

			return val

	Add: (key, value) =>
		if key >= @key
			if not @right
				@right = IMagic.Heap(key, value, @, nil, nil)
			else
				@right\Add(key, value)
		else
			if not @left
				@left = IMagic.Heap(key, value, @, nil, nil)
			else
				@left\Add(key, value)

		return @Heapify()

	Search: (key) =>
		assert(type(key) == 'number', 'Key must be a number')

		if @key == key
			return @
		elseif @key <= key
			return nil if not @right
			return @right\Search(key)
		else
			return nil if not @left
			return @left\Search(key)

	SetLeft: (left) =>
		@left = left
		return @

	SetRight: (right) =>
		@right = right
		return @

	Heapify: =>
		if @left and @left\Comparable() >= @Comparable()
			left, right = @left.left, @left.right
			@left.parent = @parent
			@left.right = @right
			@left.left = @
			@left = left
			@right = right
			return @Heapify()

		if @right and @right\Comparable() < @Comparable()
			left, right = @right.left, @right.right
			@left.parent = @parent
			@left.right = @
			@left.left = @left
			@left = left
			@right = right
			return @Heapify()

		@left\Heapify() if @left
		@right\Heapify() if @right
		return @

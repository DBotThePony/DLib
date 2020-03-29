
-- Copyright (C) 2020 DBotThePony

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

import DLib, type, luatype, istable, table, string, error from _G

DLib.GON = DLib.GON or {}
GON = DLib.GON

GON.HashRegistry = GON.HashRegistry or {}
GON.Registry = GON.Registry or {}
GON.LongIdentityRegistry = GON.LongIdentityRegistry or {}

GON.FindLongProvider = (identity) ->
	provider = GON.LongIdentityRegistry[identity]
	return provider or false

GON.RegisterProvider = (provider) ->
	identity = provider\GetIdentity()
	identify = provider\LuaTypeIdentify()
	should_put = provider\ShouldPutIntoMainRegistry()

	GON.LongIdentityRegistry[identity] = provider
	GON.HashRegistry[identify] = provider if identify

	if should_put
		for i, provider2 in ipairs(GON.Registry)
			if provider2\GetIdentity() == identity
				GON.Registry[i] = provider
				return

		table.insert(GON.Registry, provider)

	return

class GON.IDataProvider
	@LuaTypeIdentify = => @_IDENTIFY
	@ShouldPutIntoMainRegistry = => @LuaTypeIdentify() == nil

	@GetIdentity = => error('Not implemented')

	@Ask = (value, ltype = luatype(value)) =>
		identify = @LuaTypeIdentify()

		if istable(identify) == 'table'
			return table.qhasValue(identify, ltype)
		else
			return ltype == identify

	@Deserialize = (bytesbuffer, structure, heapid, length) => error('Not implemented')

	new: (structure, id) =>
		@structure = structure
		@heapid = id

	SetValue: (value) =>
		@value = value
		return @

	Serialize: => error('Not implemented')
	GetValue: => @value
	GetStructure: => @structure
	GetHeapID: => @heapid
	GetIdentity: => @@GetIdentity()

class GON.Structure
	@ERROR_MISSING_PROVIDER = 0
	@ERROR_NO_IDENTIFIER = 1

	new: (lowmem = true) =>
		@nextid = 1
		@heap = {}
		@next_reg_id = 0
		@identity_registry = {}
		@_identity_registry = {}

	GetHeapValue: (id) => @heap[id]

	NextHeapIdentifier: =>
		ret = @nextid
		@nextid += 1
		return ret

	FindInHeap: (value) =>
		for provider in *@heap
			if provider and provider\GetValue() == value
				return provider

		return false

	GetIdentityID: (identity) =>
		_get = @_identity_registry[identity]
		return _get if _get
		_get = @next_reg_id
		error('Too many types in a single file! 255 is the maximum!') if _get >= 0x100
		@identity_registry[_get] = identity
		@_identity_registry[identity] = _get
		@next_reg_id += 1
		return _get

	AddToHeap: (value) =>
		if provider = @FindInHeap(value)
			return provider

		ltype = luatype(value)
		provider = GON.HashRegistry[ltype]

		if not provider
			for prov in *GON.Registry
				if prov\Ask(value, ltype)
					provider = prov
					break

		return false, @@ERROR_MISSING_PROVIDER if not provider
		identity = provider\GetIdentity()
		return false, @@ERROR_NO_IDENTIFIER if not identity
		iid = @GetIdentityID(identity)

		id = @NextHeapIdentifier()
		serialized = provider(@, id)
		serialized._identity_id = iid
		@heap[id] = serialized
		@root = serialized if not @root
		serialized\SetValue(value)
		return serialized

	SetRoot: (provider) =>
		error('Provider must be GON.IDataProvider! typeof ' .. luatype(provider)) if not istable(provider) or not provider.GetHeapID
		error('Given provider is not part of this structure heap') if @heap[provider\GetHeapID()] ~= provider
		@root = provider

	WriteHeader: (bytesbuffer) =>
		bytesbuffer\WriteBinary('\xF7\x7FDLib.GON\x00\x01')
		bytesbuffer\WriteUByte(@next_reg_id - 1)
		bytesbuffer\WriteString(@identity_registry[i]) for i = 0, @next_reg_id - 1

	WriteHeap: (bytesbuffer) =>
		bytesbuffer\WriteUInt32(#@heap)

		for provider in *@heap
			bytesbuffer\WriteUByte(provider._identity_id)

			bytesbuffer\WriteUInt16(0)
			pos = bytesbuffer\Tell()
			provider\Serialize(bytesbuffer)
			pos2 = bytesbuffer\Tell()
			len = pos2 - pos
			bytesbuffer\Move(-len - 2)
			bytesbuffer\WriteUInt16(len)
			bytesbuffer\Move(len)

	WriteRoot: (bytesbuffer) =>
		bytesbuffer\WriteUByte(@root and 1 or 0)
		bytesbuffer\WriteUInt32(@root\GetHeapID()) if @root

	ReadHeader: (bytesbuffer) =>
		read = bytesbuffer\ReadBinary(12)
		return false if read ~= '\xF7\x7FDLib.GON\x00\x01'
		@identity_registry = {}
		@_identity_registry = {}

		for i = 0, bytesbuffer\ReadUByte()
			read = bytesbuffer\ReadString()
			@identity_registry[i] = read
			@_identity_registry[read] = i

		return true

	ReadHeap: (bytesbuffer) =>
		@heap = {}
		@nextid = 1

		amount = bytesbuffer\ReadUInt32()

		for i = 1, amount
			heapid = @nextid
			@nextid += 1
			iid = bytesbuffer\ReadUByte()
			regid = @identity_registry[iid]
			provider = GON.FindLongProvider(regid) if regid
			len = bytesbuffer\ReadUInt16()

			if not provider
				bytesbuffer\Move(len)
			else
				pos1 = bytesbuffer\Tell()
				@heap[heapid] = provider\Deserialize(bytesbuffer, @, heapid, len)
				pos2 = bytesbuffer\Tell()
				error('provider read more or less than required (' .. (pos2 - pos1) .. ' vs ' .. len .. ')') if (pos2 - pos1) ~= len

	ReadRoot: (bytesbuffer) =>
		has_root = bytesbuffer\ReadUByte() == 1

		if has_root
			@root = @heap[bytesbuffer\ReadUInt32()]
		else
			@root = nil

	WriteFile: (bytesbuffer) =>
		@WriteHeader(bytesbuffer)
		@WriteHeap(bytesbuffer)
		@WriteRoot(bytesbuffer)
		return bytesbuffer

	ReadFile: (bytesbuffer) =>
		@ReadHeader(bytesbuffer)
		@ReadHeap(bytesbuffer)
		@ReadRoot(bytesbuffer)
		return @

	CreateBuffer: =>
		bytesbuffer = DLib.BytesBuffer()
		return @WriteFile(bytesbuffer)

class GON.StringProvider extends GON.IDataProvider
	@_IDENTIFY = 'string'
	@GetIdentity = => 'builtin:string'
	Serialize: (bytesbuffer) => bytesbuffer\WriteBinary(@value)
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.StringProvider(structure, heapid)\SetValue(bytesbuffer\ReadBinary(length))

class GON.NumberProvider extends GON.IDataProvider
	@_IDENTIFY = 'number'
	@GetIdentity = => 'builtin:number'
	Serialize: (bytesbuffer) => bytesbuffer\WriteDouble(@value)
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.NumberProvider(structure, heapid)\SetValue(bytesbuffer\ReadDouble())

class GON.BooleanProvider extends GON.IDataProvider
	@_IDENTIFY = 'boolean'
	@GetIdentity = => 'builtin:boolean'
	Serialize: (bytesbuffer) => bytesbuffer\WriteUByte(@value and 1 or 0)
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.BooleanProvider(structure, heapid)\SetValue(bytesbuffer\ReadUByte() == 1)

class GON.TableProvider extends GON.IDataProvider
	@_IDENTIFY = 'table'
	@GetIdentity = => 'builtin:table'

	SetSerializedValue: (value) =>
		@_serialized = value
		@was_serialized = true
		@value = nil

	SetValue: (value) =>
		@value = value
		@_serialized = {}
		@was_serialized = false

		for key, value in pairs(value)
			keyHeap = @structure\AddToHeap(key)

			if keyHeap
				keyValue = @structure\AddToHeap(value)

				if keyValue
					@_serialized[keyHeap\GetHeapID()] = keyValue\GetHeapID()

	GetValue: =>
		return @value if not @was_serialized
		@value = {}
		@was_serialized = false

		for key, value in pairs(@_serialized)
			@value[@structure\GetHeapValue(key)\GetValue()] = @structure\GetHeapValue(value)\GetValue()

		return @value

	Serialize: (bytesbuffer) =>
		for key, value in pairs(@_serialized)
			bytesbuffer\WriteUInt32(key)
			bytesbuffer\WriteUInt32(value)

		bytesbuffer\WriteUInt32(0)

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		obj = GON.TableProvider(structure, heapid)
		_serialized = {}

		while true
			readKey = bytesbuffer\ReadUInt32()
			break if readKey == 0
			readValue = bytesbuffer\ReadUInt32()
			break if readValue == 0
			_serialized[readKey] = readValue

		obj\SetSerializedValue(_serialized)
		return obj

GON.RegisterProvider(GON.StringProvider)
GON.RegisterProvider(GON.NumberProvider)
GON.RegisterProvider(GON.BooleanProvider)
GON.RegisterProvider(GON.TableProvider)

class GON.VectorProvider extends GON.IDataProvider
	@_IDENTIFY = 'Vector'
	@GetIdentity = => 'gmod:Vector'

	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteDouble(@value.x)
		bytesbuffer\WriteDouble(@value.y)
		bytesbuffer\WriteDouble(@value.z)

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		GON.VectorProvider(structure, heapid)\SetValue(Vector(bytesbuffer\ReadDouble(), bytesbuffer\ReadDouble(), bytesbuffer\ReadDouble()))

class GON.AngleProvider extends GON.IDataProvider
	@_IDENTIFY = 'Angle'
	@GetIdentity = => 'gmod:Angle'

	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteFloat(@value.x)
		bytesbuffer\WriteFloat(@value.y)
		bytesbuffer\WriteFloat(@value.z)

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		GON.AngleProvider(structure, heapid)\SetValue(Angle(bytesbuffer\ReadFloat(), bytesbuffer\ReadFloat(), bytesbuffer\ReadFloat()))

class GON.ColorProvider extends GON.IDataProvider
	@_IDENTIFY = 'Color'
	@GetIdentity = => 'dlib:Color'

	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteUByte(@value.r)
		bytesbuffer\WriteUByte(@value.g)
		bytesbuffer\WriteUByte(@value.b)
		bytesbuffer\WriteUByte(@value.a)

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		GON.ColorProvider(structure, heapid)\SetValue(Color(bytesbuffer\ReadUByte(), bytesbuffer\ReadUByte(), bytesbuffer\ReadUByte(), bytesbuffer\ReadUByte()))

GON.RegisterProvider(GON.VectorProvider)
GON.RegisterProvider(GON.AngleProvider)
GON.RegisterProvider(GON.ColorProvider)

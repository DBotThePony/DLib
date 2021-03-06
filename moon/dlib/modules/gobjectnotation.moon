
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
GON.IdentityRegistry = GON.IdentityRegistry or {}

GON.FindProvider = (identity) -> GON.IdentityRegistry[identity] or false

GON.RemoveProvider = (provider) ->
	identity = provider\GetIdentity()
	identify = provider\LuaTypeIdentify()

	GON.IdentityRegistry[identity] = nil

	if istable(identify)
		GON.HashRegistry[i] = nil for i in *identify
	elseif isstring(identify)
		GON.HashRegistry[identify] = nil

	for i, provider2 in ipairs(GON.Registry)
		if provider2\GetIdentity() == identity
			GON.Registry[i] = nil
			return

GON.RegisterProvider = (provider, should_put) ->
	identity = provider\GetIdentity()
	identify = provider\LuaTypeIdentify()

	GON.IdentityRegistry[identity] = provider

	if istable(identify)
		GON.HashRegistry[i] = provider for i in *identify
	elseif isstring(identify)
		GON.HashRegistry[identify] = provider

	if should_put
		for i, provider2 in ipairs(GON.Registry)
			if provider2\GetIdentity() == identity
				GON.Registry[i] = provider
				return

		table.insert(GON.Registry, provider)

	return

class GON.IDataProvider
	@LuaTypeIdentify = => @_IDENTIFY

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

	Serialize: (bytesbuffer) => error('Not implemented')
	AnalyzeSize: => false
	GetValue: => @value
	GetStructure: => @structure
	GetHeapID: => @heapid
	GetIdentity: => @@GetIdentity()
	IsKnownValue: => true
	GetRegistryID: => @_identity_id
	IsInstantValue: => true

class GON.UnknownValue
	new: (structure, data, id, registryid) =>
		@structure = structure
		@data = data
		@heapid = id
		@registryid = registryid

	GetHeapID: => @heapid

	Length: => #@data
	IsKnownValue: => false
	BinaryData: => @data
	GetValue: => nil
	GetRegistryID: => @registryid

class GON.Structure
	@ERROR_MISSING_PROVIDER = 0
	@ERROR_NO_IDENTIFIER = 1

	new: (lowmem = false) =>
		@lowmem = lowmem
		@nextid = 1
		@heap = {}
		@_heap = {} if not lowmem
		@next_reg_id = 0
		@identity_registry = {}
		@_identity_registry = {}
		@long_heap = false

	GetHeapValue: (id) => @heap[id]

	NextHeapIdentifier: =>
		ret = @nextid
		@nextid += 1
		return ret

	FindInHeap: (value) =>
		if isnumber(value) and value ~= value
			return @nan_value or false

		if @_heap
			return @_heap[value] or false

		for provider in *@heap
			if provider and provider\IsKnownValue() and provider\GetValue() == value
				return provider

		return false

	GetIdentityID: (identity) =>
		_get = @_identity_registry[identity]
		return _get if _get
		_get = @next_reg_id
		error('Too many different types in a single file! 255 is the maximum!') if _get >= 0x100
		@identity_registry[_get] = identity
		@_identity_registry[identity] = _get
		@next_reg_id += 1
		return _get

	AddToHeap: (value) =>
		if provider = @FindInHeap(value)
			return provider

		ltype = luatype(value)
		provider = GON.HashRegistry[ltype]
		provider = nil if provider and not provider\Ask(value, ltype)

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

		if ltype == 'number' and value ~= value
			@nan_value = serialized
		else
			@_heap[value] = serialized if @_heap

		@root = serialized if not @root
		serialized\SetValue(value)
		return serialized

	SetRoot: (provider) =>
		error('Provider must be GON.IDataProvider! typeof ' .. luatype(provider)) if not istable(provider) or not provider.GetHeapID
		error('Given provider is not part of this structure heap') if @heap[provider\GetHeapID()] ~= provider
		@root = provider

	IsHeapBig: => @long_heap or #@heap >= 0xFFFF

	AnalyzeSize: =>
		size = 12 + 4 + 1

		if @next_reg_id ~= 0
			size += 1
			size += #@identity_registry[i] + 1 for i = 0, @next_reg_id - 1
		else
			size += 2

		for provider in *@heap
			size += 1

			if provider\IsKnownValue()
				size += 2
				analyze = provider\AnalyzeSize()
				return false if not analyze
				size += analyze
			else
				size += 2 + #provider\BinaryData()

		size += @IsHeapBig() and 4 or 2 if @root
		return size

	WriteHeader: (bytesbuffer) =>
		bytesbuffer\WriteBinary('\xF7\x7FDLib.GON\x00\x03')

		if @next_reg_id ~= 0
			bytesbuffer\WriteUByte(@next_reg_id - 1)
			bytesbuffer\WriteString(@identity_registry[i]) for i = 0, @next_reg_id - 1
		else
			bytesbuffer\WriteUShort(0)

	WriteHeap: (bytesbuffer) =>
		bytesbuffer\WriteUInt32(#@heap)

		for provider in *@heap
			bytesbuffer\WriteUByte(provider\GetRegistryID())

			if provider\IsKnownValue()
				bytesbuffer\WriteUInt32(0)
				pos = bytesbuffer\Tell()
				provider\Serialize(bytesbuffer)
				pos2 = bytesbuffer\Tell()
				len = pos2 - pos
				bytesbuffer\Move(-len - 4)
				bytesbuffer\WriteUInt32(len)
				bytesbuffer\Move(len)
			else
				bytesbuffer\WriteUInt32(provider\Length())
				bytesbuffer\WriteBinary(provider\BinaryData())

	WriteRoot: (bytesbuffer) =>
		bytesbuffer\WriteUByte(@root and 1 or 0)
		bytesbuffer\WriteUInt32(@root\GetHeapID()) if @root and @IsHeapBig()
		bytesbuffer\WriteUInt16(@root\GetHeapID()) if @root and not @IsHeapBig()

	ReadHeader: (bytesbuffer) =>
		read = bytesbuffer\ReadBinary(12)

		@long_heap = false

		if read == '\xF7\x7FDLib.GON\x00\x01'
			@old_value_length = true
			@identity_registry = {}
			@_identity_registry = {}

			@next_reg_id = bytesbuffer\ReadUByte() + 1

			for i = 0, @next_reg_id - 1
				read = bytesbuffer\ReadString()
				@identity_registry[i] = read
				@_identity_registry[read] = i

			@long_heap = true

			return true
		elseif read == '\xF7\x7FDLib.GON\x00\x02' or read == '\xF7\x7FDLib.GON\x00\x03'
			@old_value_length = read == '\xF7\x7FDLib.GON\x00\x02'
			@identity_registry = {}
			@_identity_registry = {}

			@next_reg_id = bytesbuffer\ReadUByte() + 1

			for i = 0, @next_reg_id - 1
				read = bytesbuffer\ReadString()

				if read == '' and @next_reg_id == 0
					-- file is empty
					return
				else
					@identity_registry[i] = read
					@_identity_registry[read] = i

			return true

		return false

	ReadHeap: (bytesbuffer) =>
		@heap = {}
		@nextid = 1

		amount = bytesbuffer\ReadUInt32()

		for i = 1, amount
			heapid = @nextid
			@nextid += 1
			iid = bytesbuffer\ReadUByte()
			regid = @identity_registry[iid]
			provider = GON.FindProvider(regid) if regid
			len = @old_value_length and bytesbuffer\ReadUInt16() or bytesbuffer\ReadUInt32()

			if not provider
				@heap[heapid] = GON.UnknownValue(@, bytesbuffer\ReadBinary(len), heapid, iid)
			else
				pos1 = bytesbuffer\Tell()
				p = provider\Deserialize(bytesbuffer, @, heapid, len)
				@heap[heapid] = p
				p._identity_id = iid

				realvalue = p\GetValue() if p\IsInstantValue()

				if realvalue ~= nil
					if isnumber(realvalue) and realvalue ~= realvalue
						@nan_value = p
					else
						@_heap[realvalue] = p if @_heap

				pos2 = bytesbuffer\Tell()
				error('provider read more or less than required (' .. (pos2 - pos1) .. ' vs ' .. len .. ')') if (pos2 - pos1) ~= len

	ReadRoot: (bytesbuffer) =>
		has_root = bytesbuffer\ReadUByte() == 1

		if has_root
			@root = @heap[bytesbuffer\ReadUInt32()] if @IsHeapBig()
			@root = @heap[bytesbuffer\ReadUInt16()] if not @IsHeapBig()
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
		if analyze = @AnalyzeSize()
			bytesbuffer = DLib.BytesBuffer.Allocate(analyze)
			return @WriteFile(bytesbuffer)

		bytesbuffer = DLib.BytesBuffer()
		return @WriteFile(bytesbuffer)

-- Builtin

class GON.StringProvider extends GON.IDataProvider
	@_IDENTIFY = 'string'
	@GetIdentity = => 'builtin:string'
	AnalyzeSize: => #@value
	Serialize: (bytesbuffer) => bytesbuffer\WriteBinary(@value)
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.StringProvider(structure, heapid)\SetValue(bytesbuffer\ReadBinary(length))

class GON.NumberProvider extends GON.IDataProvider
	@_IDENTIFY = 'number'
	@Ask = (value, ltype = luatype(value)) => ltype == 'number' and value == value
	@GetIdentity = => 'builtin:number'
	AnalyzeSize: => 8
	Serialize: (bytesbuffer) => bytesbuffer\WriteDouble(@value)
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.NumberProvider(structure, heapid)\SetValue(bytesbuffer\ReadDouble())

nan = 0 / 0

class GON.NaNProvider extends GON.IDataProvider
	@_IDENTIFY = 'nan'
	@Ask = (value, ltype = luatype(value)) => ltype == 'number' and value ~= value
	@GetIdentity = => 'builtin:nan'
	Serialize: (bytesbuffer) =>
	AnalyzeSize: => 0
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.NaNProvider(structure, heapid)
	GetValue: => nan

class GON.BooleanProvider extends GON.IDataProvider
	@_IDENTIFY = 'boolean'
	@GetIdentity = => 'builtin:boolean'
	AnalyzeSize: => 1
	Serialize: (bytesbuffer) => bytesbuffer\WriteUByte(@value and 1 or 0)
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.BooleanProvider(structure, heapid)\SetValue(bytesbuffer\ReadUByte() == 1)

class GON.TableProvider extends GON.IDataProvider
	@_IDENTIFY = 'table'
	@GetIdentity = => 'builtin:table'

	SetSerializedValue: (value) =>
		@_serialized = value
		@was_serialized = true
		@value = nil

	IsInstantValue: => false

	Rehash: (value = @value, preserveUnknown = true) =>
		@structure._heap[@value] = nil if @value and @structure._heap
		@value = value
		@structure._heap[value] = @ if @structure._heap
		copy = @_serialized
		@_serialized = {}

		if preserveUnknown
			for key, value in pairs(copy)
				_key = @structure\GetHeapValue(key)
				_value = @structure\GetHeapValue(value)
				@_serialized[key] = value if _key and _value and (not _key\IsKnownValue() or not _value\IsKnownValue())

		for key, value in pairs(value)
			keyHeap = @structure\AddToHeap(key)

			if keyHeap
				keyValue = @structure\AddToHeap(value)

				if keyValue
					@_serialized[keyHeap\GetHeapID()] = keyValue\GetHeapID()

		return @

	SetValue: (value) =>
		@Rehash(value, false)
		@was_serialized = false

	GetValue: =>
		return @value if not @was_serialized
		@structure._heap[@value] = nil if @value and @structure._heap
		@value = {}
		@structure._heap[@value] = @ if @structure._heap
		@was_serialized = false

		for key, value in pairs(@_serialized)
			_key = @structure\GetHeapValue(key)
			_value = @structure\GetHeapValue(value)
			@value[_key\GetValue()] = _value\GetValue() if _key and _value and _key\IsKnownValue() and _value\IsKnownValue()

		return @value

	AnalyzeSize: =>
		size = 0
		long_heap = @structure\IsHeapBig()

		if long_heap
			for key, value in pairs(@_serialized)
				size += 8

			size += 4
		else
			for key, value in pairs(@_serialized)
				size += 4

			size += 2

		return size

	Serialize: (bytesbuffer) =>
		long_heap = @structure\IsHeapBig()

		for key, value in pairs(@_serialized)
			if long_heap
				bytesbuffer\WriteUInt32(key)
				bytesbuffer\WriteUInt32(value)
			else
				bytesbuffer\WriteUInt16(key)
				bytesbuffer\WriteUInt16(value)

		bytesbuffer\WriteUInt32(0) if long_heap
		bytesbuffer\WriteUInt16(0) if not long_heap

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		long_heap = structure\IsHeapBig()

		obj = GON.TableProvider(structure, heapid)
		_serialized = {}

		if long_heap
			while true
				readKey = bytesbuffer\ReadUInt32()
				break if readKey == 0
				readValue = bytesbuffer\ReadUInt32()
				break if readValue == 0
				_serialized[readKey] = readValue
		else
			while true
				readKey = bytesbuffer\ReadUInt16()
				break if readKey == 0
				readValue = bytesbuffer\ReadUInt16()
				break if readValue == 0
				_serialized[readKey] = readValue

		obj\SetSerializedValue(_serialized)
		return obj

GON.RegisterProvider(GON.StringProvider)
GON.RegisterProvider(GON.NumberProvider)
GON.RegisterProvider(GON.NaNProvider, true)
GON.RegisterProvider(GON.BooleanProvider)
GON.RegisterProvider(GON.TableProvider)

-- Common

class GON.VectorProvider extends GON.IDataProvider
	@_IDENTIFY = 'Vector'
	@GetIdentity = => 'gmod:Vector'

	AnalyzeSize: => 24

	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteDouble(@value.x)
		bytesbuffer\WriteDouble(@value.y)
		bytesbuffer\WriteDouble(@value.z)

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		GON.VectorProvider(structure, heapid)\SetValue(Vector(bytesbuffer\ReadDouble(), bytesbuffer\ReadDouble(), bytesbuffer\ReadDouble()))

class GON.AngleProvider extends GON.IDataProvider
	@_IDENTIFY = 'Angle'
	@GetIdentity = => 'gmod:Angle'

	AnalyzeSize: => 12

	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteFloat(@value.x)
		bytesbuffer\WriteFloat(@value.y)
		bytesbuffer\WriteFloat(@value.z)

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		GON.AngleProvider(structure, heapid)\SetValue(Angle(bytesbuffer\ReadFloat(), bytesbuffer\ReadFloat(), bytesbuffer\ReadFloat()))

class GON.ColorProvider extends GON.IDataProvider
	@_IDENTIFY = 'Color'
	@GetIdentity = => 'dlib:Color'

	AnalyzeSize: => 4

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

-- Advanced

writeVector = (vec, bytesbuffer) ->
	bytesbuffer\WriteFloat(vec.x)
	bytesbuffer\WriteFloat(vec.y)
	bytesbuffer\WriteFloat(vec.z)

readVector = (bytesbuffer) -> Vector(bytesbuffer\ReadFloat(), bytesbuffer\ReadFloat(), bytesbuffer\ReadFloat())

class GON.ConVarProvider extends GON.IDataProvider
	@_IDENTIFY = 'ConVar'
	@GetIdentity = => 'gmod:ConVar'

	AnalyzeSize: => #@value\GetName() + 1

	Serialize: (bytesbuffer) => bytesbuffer\WriteString(@value\GetName())
	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		GON.ConVarProvider(structure, heapid)\SetValue(ConVar(bytesbuffer\ReadString()))

class GON.VMatrixProvider extends GON.IDataProvider
	@_IDENTIFY = 'VMatrix'
	@GetIdentity = => 'gmod:VMatrix'

	AnalyzeSize: => 8 * 4 * 4

	Serialize: (bytesbuffer) =>
		tab = @value\ToTable()

		for row in *tab
			bytesbuffer\WriteDouble(row[1])
			bytesbuffer\WriteDouble(row[2])
			bytesbuffer\WriteDouble(row[3])
			bytesbuffer\WriteDouble(row[4])

	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		tab = {}

		for i = 1, 4
			table.insert(tab, {
				bytesbuffer\ReadDouble()
				bytesbuffer\ReadDouble()
				bytesbuffer\ReadDouble()
				bytesbuffer\ReadDouble()
			})

		return GON.VMatrixProvider(structure, heapid)\SetValue(Matrix(tab))

class GON.MaterialProvider extends GON.IDataProvider
	@_IDENTIFY = 'IMaterial'
	@GetIdentity = => 'gmod:IMaterial'

	AnalyzeSize: => #@value\GetName() + 1

	Serialize: (bytesbuffer) => bytesbuffer\WriteString(@value\GetName())
	@Deserialize = (bytesbuffer, structure, heapid, length) => GON.MaterialProvider(structure, heapid)\SetValue(Material(bytesbuffer\ReadString()), nil)

class GON.CTakeDamageInfoProvider extends GON.IDataProvider
	@_IDENTIFY = {'CTakeDamageInfo', 'LTakeDamageInfo'}
	@GetIdentity = => 'dlib:LTakeDamageInfo'

	AnalyzeSize: => 80

	@Write = (obj, bytesbuffer) =>
		with bytesbuffer
			\WriteDouble(obj\GetDamage())
			\WriteDouble(obj\GetBaseDamage())
			\WriteDouble(obj\GetMaxDamage())
			\WriteDouble(obj\GetDamageBonus())
			\WriteUInt32(obj\GetDamageCustom())
			\WriteUInt32(obj\GetAmmoType())
			writeVector(obj\GetDamagePosition(), bytesbuffer)
			writeVector(obj\GetDamageForce(), bytesbuffer)
			writeVector(obj\GetReportedPosition(), bytesbuffer)
			\WriteUInt32(obj\GetDamageType())

	@Read = (obj, bytesbuffer) =>
		with bytesbuffer
			obj\SetDamage(\ReadDouble())
			obj\SetBaseDamage(\ReadDouble())
			obj\SetMaxDamage(\ReadDouble())
			obj\SetDamageBonus(\ReadDouble())
			obj\SetDamageCustom(\ReadUInt32())
			obj\SetAmmoType(\ReadUInt32())

			obj\SetDamagePosition(readVector(bytesbuffer))
			obj\SetDamageForce(readVector(bytesbuffer))
			obj\SetReportedPosition(readVector(bytesbuffer))

			obj\SetDamageType(\ReadUInt32())

	Serialize: (bytesbuffer) => @@Write(@value, bytesbuffer)
	@Deserialize = (bytesbuffer, structure, heapid, length) =>
		obj = DLib.LTakeDamageInfo()
		@Read(obj, bytesbuffer)
		return GON.CTakeDamageInfoProvider(structure, heapid)\SetValue(obj)

GON.RegisterProvider(GON.ConVarProvider)
GON.RegisterProvider(GON.VMatrixProvider)
GON.RegisterProvider(GON.MaterialProvider)
GON.RegisterProvider(GON.CTakeDamageInfoProvider)

GON.Serialize = (value, toBuffer = true) ->
	struct = GON.Structure()
	struct\AddToHeap(value)
	return struct if not toBuffer
	return struct\CreateBuffer()

GON.Deserialize = (bufferIn, retreiveValue = true) ->
	struct = GON.Structure()
	struct\ReadFile(bufferIn)
	return struct if not retreiveValue
	return if not struct.root
	return struct.root\GetValue()

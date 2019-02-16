
-- Copyright (C) 2017-2019 DBot

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


import assert, error, DLib, table from _G
type = luatype

jit.on()
DLib.NBT = {}

-- names are deprecated
-- (the @name variable)

Typed = {}
TypedByID = {}
TypeID = {
	TAG_End: 0
	TAG_Byte: 1
	TAG_Short: 2
	TAG_Int: 3
	TAG_Long: 4
	TAG_Float: 5
	TAG_Double: 6
	TAG_Byte_Array: 7
	TAG_String: 8
	TAG_List: 9
	TAG_Compound: 10
	TAG_Int_Array: 11
	TAG_Long_Array: 12
}

class DLib.NBT.Base
	new: (value = @GetDefault()) =>
		@length = 0 if not @length
		@value = value
		@CheckValue(value) if value ~= nil

	GetDefault: => 0
	GetLength: => @length
	CheckValue: (value) => assert(type(value) ~= 'nil', 'value can not be nil')
	GetValue: => @value
	SetValue: (value = @value) =>
		@CheckValue(value)
		@value = value

	Serialize: (bytesbuffer) =>
		error('Method not implemented')

	Deserialize: (bytesbuffer) =>
		error('Method not implemented')

	GetTagID: => @@TAG_ID
	GetPayload: => @GetLength()
	PayloadLength: => @GetPayload()
	Varies: => false
	@FIXED_LENGTH = -1
	FixedPayloadLength: => @@FIXED_LENGTH
	@NAME = 'TAG_Base'
	Name: => @@NAME
	GetName: => @Name()
	Nick: => @Name()
	GetNick: => @Name()
	GetType: => 'undefined'
	MetaName: 'NBTBase'

	IsBase: => @Name() == 'TAG_Base'
	IsEnd: => @Name() == 'TAG_End'
	IsByte: => @Name() == 'TAG_Byte'
	IsShort: => @Name() == 'TAG_Short'
	IsInt: => @Name() == 'TAG_Int'
	IsLong: => @Name() == 'TAG_Long'
	IsFloat: => @Name() == 'TAG_Float'
	IsDouble: => @Name() == 'TAG_Double'
	IsByteArray: => @Name() == 'TAG_Byte_Array'
	IsString: => @Name() == 'TAG_String'
	IsList: => @Name() == 'TAG_List'
	IsTagCompound: => @Name() == 'TAG_Compound'
	IsCompound: => @Name() == 'TAG_Compound'
	IsIntArray: => @Name() == 'TAG_Int_Array'
	IsLongArray: => @Name() == 'TAG_Long_Array'

	__tostring: => @Name() .. '[' .. @@NAME .. '][' .. tostring(@value) .. ']'

class DLib.NBT.TagEnd extends DLib.NBT.Base
	Serialize: (bytesbuffer) => @
	Deserialize: (bytesbuffer) => @
	GetPayload: => 0
	FixedPayloadLength: => 0
	@NAME = 'TAG_End'
	MetaName: 'NBTTagEnd'
	GetType: => 'end'

class DLib.NBT.TagByte extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
		error('Value must be a number! ' .. type(value) .. ' given.') if type(value) ~= 'number'
		assert(value >= -0x80 and value < 0x80, 'value overflow')
	Serialize: (bytesbuffer) => bytesbuffer\WriteByte(@value)
	Deserialize: (bytesbuffer) =>
		@value = bytesbuffer\ReadByte()
		return @
	GetPayload: => 1
	@FIXED_LENGTH = 1
	@NAME = 'TAG_Byte'
	GetType: => 'byte'
	MetaName: 'NBTByte'

class DLib.NBT.TagShort extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
		error('Value must be a number! ' .. type(value) .. ' given.') if type(value) ~= 'number'
		assert(value >= -0x8000 and value < 0x8000, 'value overflow')
	Serialize: (bytesbuffer) => bytesbuffer\WriteInt16(@value)
	Deserialize: (bytesbuffer) =>
		@value = bytesbuffer\ReadInt16()
		return @
	GetPayload: => 2
	@FIXED_LENGTH = 2
	@NAME = 'TAG_Short'
	GetType: => 'short'
	MetaName: 'NBTShort'

class DLib.NBT.TagInt extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
		error('Value must be a number! ' .. type(value) .. ' given.') if type(value) ~= 'number'
		assert(value >= -0x40000000 and value < 0x40000000, 'value overflow')
	Serialize: (bytesbuffer) => bytesbuffer\WriteInt32(@value)
	Deserialize: (bytesbuffer) =>
		@value = bytesbuffer\ReadInt32()
		return @
	GetPayload: => 4
	@FIXED_LENGTH = 4
	@NAME = 'TAG_Int'
	GetType: => 'int'
	MetaName: 'NBTInt'

class DLib.NBT.TagLong extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
		error('Value must be a number! ' .. type(value) .. ' given.') if type(value) ~= 'number'
		assert(value >= -9223372036854775808 and value < 9223372036854775808, 'value overflow')
	Serialize: (bytesbuffer) => bytesbuffer\WriteInt64(@value)
	Deserialize: (bytesbuffer) =>
		@value = bytesbuffer\ReadInt64()
		return @
	GetPayload: => 8
	@FIXED_LENGTH = 8
	@NAME = 'TAG_Long'
	GetType: => 'long'
	MetaName: 'NBTLong'

class DLib.NBT.TagFloat extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
		error('Value must be a number! ' .. type(value) .. ' given.') if type(value) ~= 'number'
	Serialize: (bytesbuffer) => bytesbuffer\WriteFloat(@value)
	Deserialize: (bytesbuffer) =>
		@value = bytesbuffer\ReadFloat()
		return @
	GetPayload: => 4
	@FIXED_LENGTH = 4
	@NAME = 'TAG_Float'
	GetType: => 'float'
	MetaName: 'NBTFloat'

class DLib.NBT.TagDouble extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
		error('Value must be a number! ' .. type(value) .. ' given.') if type(value) ~= 'number'
	Serialize: (bytesbuffer) => bytesbuffer\WriteDouble(@value)
	Deserialize: (bytesbuffer) =>
		@value = bytesbuffer\ReadDouble()
		return @
	GetPayload: => 8
	@FIXED_LENGTH = 8
	@NAME = 'TAG_Double'
	GetType: => 'double'
	MetaName: 'NBTDouble'

class DLib.NBT.TagString extends DLib.NBT.Base
	CheckValue: (value) => super(value) and assert(#value < 65536, 'String is too long!')
	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteUInt16(#@value)
		bytesbuffer\WriteBinary(@value)

	Deserialize: (bytesbuffer) =>
		@length = bytesbuffer\ReadUInt16()
		@value = bytesbuffer\ReadBinary(@length)
		return @

	GetDefault: => ''
	GetLength: => #@value
	GetPayload: => 2 + @GetLength()
	@NAME = 'TAG_String'
	GetType: => 'string'
	MetaName: 'NBTString'

class DLib.NBT.TagArrayBased extends DLib.NBT.Base
	@FIELD_LENGTH = 1
	@RANGE = 4

	new: (values) =>
		super('array', -1)
		@array = {}
		if values
			@AddValue(value) for value in *values

	GetArray: => @array
	ExtractValue: (index = 1) => @array[index]
	GetValue: => [tag\GetValue() for tag in *@array]
	CopyArray: => [tag for tag in *@array]

	AddValue: (value) =>
		error('Method not implemented')

	SerializeLength: (bytesbuffer, length = @length) => bytesbuffer\WriteUInt32(length)
	DeserializeLength: (bytesbuffer) => bytesbuffer\ReadUInt32()
	Serialize: (bytesbuffer) =>
		@SerializeLength(bytesbuffer, @length)
		tag\Serialize(bytesbuffer) for tag in *@array
		return @

	ReadTag: (bytesbuffer) =>
		error('No tag is specified as array type')

	Deserialize: (bytesbuffer) =>
		@length = @DeserializeLength(bytesbuffer)
		@array = [@ReadTag(bytesbuffer) for i = 1, @length]
		return @

	GetPayload: => @length * @@FIELD_LENGTH + @RANGE
	@NAME = 'TAG_Array'
	GetType: => 'array_undefined'
	MetaName: 'NBTArray'

	__tostring: => @Name() .. '[' .. @@NAME .. '][' .. @length .. ']{' .. tostring(@array) .. '}'

class DLib.NBT.TagByteArray extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = 1
	@RANGE = 4

	AddValue: (value) =>
		@length += 1
		table.insert(@GetArray(), DLib.NBT.TagByte(value))
		return @
	ReadTag: (bytesbuffer) => DLib.NBT.TagByte()\Deserialize(bytesbuffer)
	@NAME = 'TAG_Byte_Array'
	GetType: => 'array_bytes'
	MetaName: 'NBTArrayBytes'

class DLib.NBT.TagIntArray extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = 4
	@RANGE = 4

	AddValue: (value) =>
		@length += 1
		table.insert(@GetArray(), DLib.NBT.TagInt(value))
		return @
	ReadTag: (bytesbuffer) => DLib.NBT.TagInt()\Deserialize(bytesbuffer)
	@NAME = 'TAG_Int_Array'
	GetType: => 'array_ints'
	MetaName: 'NBTArrayInt'

class DLib.NBT.TagLongArray extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = 8
	@RANGE = 4

	AddValue: (value) =>
		@length += 1
		table.insert(@GetArray(), DLib.NBT.TagLong(value))
		return @
	ReadTag: (bytesbuffer) => DLib.NBT.TagLong()\Deserialize(bytesbuffer)
	@NAME = 'TAG_Long_Array'
	GetType: => 'array_longs'
	MetaName: 'NBTArrayLong'

class DLib.NBT.TagList extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = -1
	@RANGE = 4

	new: (tagID = 1, values) =>
		@tagID = tagID
		@tagClass = DLib.NBT.GetTyped(tagID)
		error('Invalid tag ID specified as array type - ' .. tagID) if not @tagClass
		super(name)
		if values
			@AddValue(val) for val in ipairs(values)

	Serialize: (bytesbuffer) =>
		bytesbuffer\WriteUByte(@tagID)
		bytesbuffer\WriteUInt32(@length)
		tag\Serialize(bytesbuffer) for tag in *@GetArray()
		return @

	Deserialize: (bytesbuffer) =>
		@tagID = bytesbuffer\ReadUByte()
		@tagClass = DLib.NBT.GetTyped(@tagID)
		error('Invalid tag ID specified as array type - ' .. @tagID) if not @tagClass
		@length = bytesbuffer\ReadUInt32()
		@array = [@ReadTag(bytesbuffer) for i = 1, @length]
		return @

	AddValue: (...) =>
		@length += 1
		classIn = @tagClass
		error('Invalid tag ID specified as array type - ' .. @tagID) if not classIn
		table.insert(@GetArray(), classIn('value', ...))
		return @

	ReadTag: (bytesbuffer) =>
		classIn = @tagClass
		return classIn()\Deserialize(bytesbuffer)

	GetPayload: =>
		output = 5
		output += tag\GetPayload() for tag in *@GetArray()
		return output

	@NAME = 'TAG_List'
	GetType: => 'array'
	MetaName: 'NBTList'
	__tostring: => @Name() .. '[' .. @@NAME .. '][' .. (DLib.NBT.TYPEID_F[@tagClass.TAG_ID] or 'ERROR') .. '][' .. @length .. ']{' .. tostring(@array) .. '}'

class DLib.NBT.TagCompound extends DLib.NBT.Base
	new: (name = 'data', values) =>
		@name = name
		@table = {}

		super()

		if values
			@AddTypedValue(key, value) for key, value in pairs values

	GetTagName: => @name
	TagName: => @GetTagName()
	SetTagName: (name = @name) => @name = name

	ReadFile: (bytesbuffer) =>
		status = ProtectedCall -> @ReadFileProtected(bytesbuffer)
		if not status
			Error('Error reading a NBT file from Bytes Buffer! Is file/buffer a valid NBT file and is not corrupted?\n')
		return status

	ReadFileProtected: (bytesbuffer) =>
		assert(bytesbuffer\ReadUByte() == 10, 'invalid header')

		readNameLen = bytesbuffer\ReadUInt16()
		@SetTagName(bytesbuffer\ReadBinary(readNameLen))

		@Deserialize(bytesbuffer)

	WriteFile: (bytesbuffer) =>
		bytesbuffer\WriteUByte(@GetTagID())

		bytesbuffer\WriteUInt16(#@GetTagName())
		bytesbuffer\WriteBinary(@GetTagName())

		@Serialize(bytesbuffer)

	Serialize: (bytesbuffer) =>
		for key, tag in pairs @table
			bytesbuffer\WriteUByte(tag\GetTagID())
			bytesbuffer\WriteUInt16(#key)
			bytesbuffer\WriteBinary(key)
			tag\Serialize(bytesbuffer)
		bytesbuffer\WriteUByte(0)
		return @

	Deserialize: (bytesbuffer) =>
		while true
			readTagID = bytesbuffer\ReadUByte()
			break if readTagID == 0
			classIn = DLib.NBT.GetTyped(readTagID)
			readIDLen = bytesbuffer\ReadUInt16()
			readID = bytesbuffer\ReadBinary(readIDLen)
			local readTag

			if readTagID == TypeID.TAG_Compound
				readTag = classIn(readID)
			else
				readTag = classIn()

			readTag\Deserialize(bytesbuffer)
			@AddTag(readID, readTag)

		return @

	AddTag: (key = '', value) =>
		@table[tostring(key)] = value
		value\SetTagName(key) if value.SetTagName
		return @

	SetTag: (...) => @AddTag(...)
	SetTag2: (...) => @AddTag2(...)

	AddTag2: (key = '', value) =>
		@AddTag(key, value)
		return value

	RemoveTag: (key = '') =>
		@table[tostring(key)] = nil
		return @

	__tostring: => @Name() .. '[' .. @GetTagName() .. '][?]{' .. tostring(@table) .. '}'
	GetValue: => {key, tag\GetValue() for key, tag in pairs @table}
	iterate: => pairs @table
	iterator: => pairs @table
	pairs: => pairs @table
	HasTag: (key = '') => @table[tostring(key)] ~= nil
	GetTag: (key = '') => @table[tostring(key)]
	GetTagValue: (key = '') => @table[tostring(key)]\GetValue()
	AddByte: (key = '', value) => @AddTag(key, DLib.NBT.TagByte(value))
	AddShort: (key = '', value) => @AddTag(key, DLib.NBT.TagShort(value))
	AddInt: (key = '', value) => @AddTag(key, DLib.NBT.TagInt(value))
	AddFloat: (key = '', value) => @AddTag(key, DLib.NBT.TagFloat(value))
	AddDouble: (key = '', value) => @AddTag(key, DLib.NBT.TagDouble(value))
	AddLong: (key = '', value) => @AddTag(key, DLib.NBT.TagLong(value))
	AddString: (key = '', value) => @AddTag(key, DLib.NBT.TagString(value))
	AddByteArray: (key = '', values) => @AddTag2(key, DLib.NBT.TagByteArray(values))
	AddIntArray: (key = '', values) => @AddTag2(key, DLib.NBT.TagIntArray(values))
	AddLongArray: (key = '', values) => @AddTag2(key, DLib.NBT.TagLongArray(values))
	AddTagList: (key = '', tagID, values) => @AddTag2(key, DLib.NBT.TagList(tagID, value))
	AddTagCompound: (key = '', values) => @AddTag2(key, DLib.NBT.TagCompound(key, value))
	AddTypedValue: (key = '', value) =>
		switch type(value)
			when 'number'
				@AddDouble(key, value)
			when 'string'
				@AddString(key, value)
			when 'table'
				@AddTagCompound(key, vaue)
			else
				error('Unable to tetermine tag type for value - ' .. type(value))

	GetLength: => table.Count(@table)
	@NAME = 'TAG_Compound'
	GetType: => 'table'
	MetaName: 'NBTCompound'

Typed[TypeID[classname.NAME]] = classname for k, classname in pairs DLib.NBT when TypeID[classname.NAME]
TypedByID[classname.NAME] = classname for k, classname in pairs DLib.NBT

classname.TAG_ID = typeid for typeid, classname in pairs Typed

DLib.NBT.TYPEID = TypeID
DLib.NBT.TYPEID_F = {k, v for v, k in pairs TypeID}
DLib.NBT.TYPED = Typed
DLib.NBT.TYPED_BY_ID = TypedByID

DLib.NBT.GetTyped = (index = 0) ->
	error('invalid tag id specified - ' .. index) if not Typed[index]
	Typed[index]
DLib.NBT.GetTypedID = (id = 'TAG_Byte') ->
	error('invalid tag string id specified - '.. index) if not TypedByID[id]
	TypedByID[id]

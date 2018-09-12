
-- Copyright (C) 2017-2018 DBot

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


import assert, error, DLib, table, type from _G

jit.on()
DLib.NBT = {}

class DLib.NBT.Base
	new: (name, value) =>
		if value == nil and name ~= nil
			value = name
			name = 'tag'
		elseif name == nil and value == nil
			name = 'tag'
			value = @GetDefault()
		@length = 0 if not @length
		@value = value
		@name = name

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

	GetTagName: => @name
	GetTagID: => @@TAG_ID
	TagName: => @GetTagName()
	SetTagName: (name = @name) => @name = name
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

	__tostring: => @Name() .. '[' .. @GetTagName() .. '][' .. tostring(@value) .. ']'

class DLib.NBT.TagEnd extends DLib.NBT.Base
	Serialize: (bytesbuffer) => @
	Deserialize: (bytesbuffer) => @
	GetPayload: => 0
	FixedPayloadLength: => 0
	GetTagName: => ''
	@NAME = 'TAG_End'
	MetaName: 'NBTTagEnd'
	GetType: => 'end'

class DLib.NBT.TagByte extends DLib.NBT.Base
	CheckValue: (value) =>
		super(value)
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

	new: (name, values) =>
		if values == nil and name ~= nil
			values = name
			name = 'array'
		elseif name == nil and values == nil
			name = 'array'
			values = {}
		super(name, -1)
		@array = {}
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

	__tostring: => @Name() .. '[' .. @GetTagName() .. '][' .. @length .. ']{' .. tostring(@array) .. '}'

class DLib.NBT.TagByteArray extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = 1
	@RANGE = 4

	AddValue: (value) =>
		@length += 1
		table.insert(@GetArray(), DLib.NBT.TagByte('byte', value))
		return @
	ReadTag: (bytesbuffer) => DLib.NBT.TagByte('byte')\Deserialize(bytesbuffer)
	@NAME = 'TAG_Byte_Array'
	GetType: => 'array_bytes'
	MetaName: 'NBTArrayBytes'

class DLib.NBT.TagIntArray extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = 4
	@RANGE = 4

	AddValue: (value) =>
		@length += 1
		table.insert(@GetArray(), DLib.NBT.TagInt('int', value))
		return @
	ReadTag: (bytesbuffer) => DLib.NBT.TagInt('int')\Deserialize(bytesbuffer)
	@NAME = 'TAG_Int_Array'
	GetType: => 'array_ints'
	MetaName: 'NBTArrayInt'

class DLib.NBT.TagLongArray extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = 8
	@RANGE = 4

	AddValue: (value) =>
		@length += 1
		table.insert(@GetArray(), DLib.NBT.TagLong('long', value))
		return @
	ReadTag: (bytesbuffer) => DLib.NBT.TagLong('long')\Deserialize(bytesbuffer)
	@NAME = 'TAG_Long_Array'
	GetType: => 'array_longs'
	MetaName: 'NBTArrayLong'

class DLib.NBT.TagList extends DLib.NBT.TagArrayBased
	@FIELD_LENGTH = -1
	@RANGE = 4

	new: (name = 'array', tagID = 1) =>
		@tagID = tagID
		@tagClass = DLib.NBT.GetTyped(tagID)
		error('Invalid tag ID specified as array type - ' .. tagID) if not @tagClass
		super(name)

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
		return classIn('value')\Deserialize(bytesbuffer)

	GetPayload: =>
		output = 5
		output += tag\GetPayload() for tag in *@GetArray()
		return output

	@NAME = 'TAG_List'
	GetType: => 'array'
	MetaName: 'NBTList'
	__tostring: => @Name() .. '[' .. @GetTagName() .. '][' .. (DLib.NBT.TYPEID_F[@tagClass.TAG_ID] or 'ERROR') .. '][' .. @length .. ']{' .. tostring(@array) .. '}'

class DLib.NBT.TagCompound extends DLib.NBT.Base
	new: (name = 'data', values) =>
		super(name, -1)
		@table = {}
		if values
			@AddTypedValue(key, value) for key, value in pairs values

	ReadFile: (bytesbuffer) =>
		status = ProtectedCall -> @ReadFileProtected(bytesbuffer)
		if not status
			Error('Error reading a NBT file from Bytes Buffer! Is file/buffer a valid NBT file and is not corrupted?\n')

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
			readTag = classIn(readID)
			readTag\Deserialize(bytesbuffer)
			@AddTag(readID, readTag)
		return @

	AddTag: (key = '', value) =>
		@table[tostring(key)] = value
		value\SetTagName(key)
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
	AddByte: (key = '', value) => @AddTag(key, DLib.NBT.TagByte(key, value))
	AddShort: (key = '', value) => @AddTag(key, DLib.NBT.TagShort(key, value))
	AddInt: (key = '', value) => @AddTag(key, DLib.NBT.TagInt(key, value))
	AddFloat: (key = '', value) => @AddTag(key, DLib.NBT.TagFloat(key, value))
	AddDouble: (key = '', value) => @AddTag(key, DLib.NBT.TagDouble(key, value))
	AddLong: (key = '', value) => @AddTag(key, DLib.NBT.TagLong(key, value))
	AddString: (key = '', value) => @AddTag(key, DLib.NBT.TagString(key, value))
	AddByteArray: (key = '', values) => @AddTag2(key, DLib.NBT.TagByteArray(key, values))
	AddIntArray: (key = '', values) => @AddTag2(key, DLib.NBT.TagIntArray(key, values))
	AddLongArray: (key = '', values) => @AddTag2(key, DLib.NBT.TagLongArray(key, values))
	AddTagList: (key = '', tagID, values) => @AddTag2(key, DLib.NBT.TagList(key, tagID, value))
	AddTagCompound: (key = '', values) => @AddTag2(key, DLib.NBT.TagCompound(key, value))
	AddTypedValue: (key = '', value) =>
		switch type(value)
			when 'number'
				@AddDouble(key, value)
			when 'string'
				@AddString(key, value)
			when 'table'
				@AddTagCompound(key, vaue)

	GetLength: => table.Count(@table)
	@NAME = 'TAG_Compound'
	GetType: => 'table'
	MetaName: 'NBTCompound'

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

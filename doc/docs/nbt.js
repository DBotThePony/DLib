
const output = []

// abstract tag

output.push(`
@fname DLib.NBT.Base
@args any value
@internal

@desc
baseclass for all NBT tags
methods listed on !c:NBTTagBase are available for all tags
yes, this is implementation of reader/writer of Minecraft's NBT Tags
**STREAM MUST BE UNGZIPPED BEFORE READING/WRITING**
@enddesc
`)

output.push(`
@fname NBTTagBase:GetDefault

@returns
any
`)

output.push(`
@fname NBTTagBase:GetLength

@returns
number
`)

output.push(`
@fname NBTTagBase:CheckValue
@args any value

@desc
throws an error if value invalid, true otherswise
@enddesc

@returns
boolean
`)

output.push(`
@fname NBTTagBase:GetValue

@returns
any: value based on current NBT Tag
`)

output.push(`
@fname NBTTagBase:SetValue
@args any value

@desc
throws an error if value invalid
this method is accept values based on current NBT Tag
@enddesc
`)

output.push(`
@fname NBTTagBase:Serialize
@args BytesBuffer buffer

@desc
writes tag to stream
@enddesc
`)

output.push(`
@fname NBTTagBase:Deserialize
@args BytesBuffer buffer

@desc
reads tag from stream
@enddesc
`)

output.push(`
@fname NBTTagBase:GetTagName

@returns
string
`)

output.push(`
@fname NBTTagBase:SetTagName
@args string name
`)

output.push(`
@fname NBTTagBase:GetPayload

@returns
any
`)

output.push(`
@fname NBTTagBase:PayloadLength

@returns
number
`)

output.push(`
@fname NBTTagBase:Varies

@returns
boolean
`)

output.push(`
@fname NBTTagBase:FixedPayloadLength

@returns
number: -1 if varies
`)

output.push(`
@fname NBTTagBase:GetTagID

@desc
use this to determine tag internal NBT ID which appear in binary files
@enddesc

@returns
number
`)

output.push(`
@fname NBTTagBase:GetName

@desc
Use this to determine internal tag string id
@enddesc

@returns
string
`)

output.push(`
@fname NBTTagBase:__tostring

@returns
string
`)

const tags = [
	'IsBase',
	'IsEnd',
	'IsByte',
	'IsShort',
	'IsInt',
	'IsLong',
	'IsFloat',
	'IsDouble',
	'IsByteArray',
	'IsString',
	'IsList',
	'IsTagCompound',
	'IsCompound',
	'IsIntArray',
	'IsLongArray',
]

for (const tag of tags) {
	output.push(`
@fname NBTTagBase:${tag}

@returns
boolean
`)
}

output.push(`
@fname DLib.NBT.TagEnd
@internal

@desc
this tag tells that it is the end of list
@enddesc
`)

// further tags

output.push(`
@fname DLib.NBT.TagByte
@args number byte

@desc
throws an error if number does not fit byte range
(2 in power of 8)
number is signed
\`GetPayload()\` returns \`1\`
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagShort
@args number short

@desc
throws an error if number does not fit short int range
(2 in power of 16)
number is signed
\`GetPayload()\` returns \`2\`
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagInt
@args number int

@desc
throws an error if number does not fit integer range
(2 in power of 32)
number is signed
\`GetPayload()\` returns \`4\`
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagLong
@args number bigint

@desc
throws an error if number does not fit big integer range
(2 in power of 64)
due to precision errors, this tag is not accurate
number is signed
\`GetPayload()\` returns \`8\`
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagFloat
@args number float

@desc
creates a single precision float tag
number is signed
\`GetPayload()\` returns \`4\`
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagDouble
@args number float

@desc
creates a double precision float tag
due to precision errors, this tag is not accurate
number is signed
\`GetPayload()\` returns \`8\`
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagString
@args string value

@desc
CAN contain binary data
maximal length - \`65536\` bytes
@enddesc

@returns
table: newly created tag class
`)

output.push(`
@fname DLib.NBT.TagArrayBased
@args table arrayIn

@internal

@desc
baseclass for arrays
see !c:NBTTagArrayBase
@enddesc
`)

output.push(`
@fname NBTTagArrayBase:GetArray

@desc
baseclass for arrays
see !c:NBTTagArrayBase
@enddesc

@returns
table: array of values based on current tag
`)

output.push(`
@fname NBTTagArrayBase:ExtractValue
@args number index

@returns
any
`)

output.push(`
@fname NBTTagArrayBase:GetValue

@returns
table: copy of array with Lua values
`)

output.push(`
@fname NBTTagArrayBase:CopyArray

@returns
table: copy of array with Tag values. tags are not copied!
`)

output.push(`
@fname NBTTagArrayBase:AddValue
@args any value

@desc
Adds a value in array
@enddesc
`)

output.push(`
@fname NBTTagArrayBase:SerializeLength
@args BytesBuffer stream

@desc
writes unsigned integer to stream with length of array
@enddesc
`)

output.push(`
@fname NBTTagArrayBase:DeserializeLength
@args BytesBuffer stream

@desc
reads unsigned integer from stream with length of array
@enddesc
`)

output.push(`
@fname NBTTagArrayBase:ReadTag
@args BytesBuffer stream

@returns
table: newly read tag, or throws an error
`)

output.push(`
@fname NBTTagArrayBase:GetType

@returns
string
`)

output.push(`
@fname DLib.NBT.TagByteArray
@args table arrayOfBytes

@desc
Call \`NBTTagArrayBase:AddValue(value)\` to add new values after tag creation
this array accepts only signed bytes (2 in power of 8)
@enddesc

@returns
table: newly created tag array
`)

output.push(`
@fname DLib.NBT.TagIntArray
@args table arrayOfIntegers

@desc
Call \`NBTTagArrayBase:AddValue(value)\` to add new values after tag creation
this array accepts only signed integers (2 in power of 32)
@enddesc

@returns
table: newly created tag array
`)

output.push(`
@fname DLib.NBT.TagLongArray
@args table arrayOfBigInts

@desc
Call \`NBTTagArrayBase:AddValue(value)\` to add new values after tag creation
this array accepts only signed big integers (2 in power of 64)
due to precision errors, this tag is not accurate
@enddesc

@returns
table: newly created tag array
`)

output.push(`
@fname DLib.NBT.TagList
@args number tagID

@desc
This tag array can accept any amount of tags of same type,
defined on class creation.
\`:AddValue(...)\` accepts arguments for upvalue tag class, e.g.
if you defined tagID as another \`TagList\`, you need to call \`:AddValue(number tagID)\`
@enddesc

@returns
table: newly created tag array
`)

output.push(`
@fname DLib.NBT.TagCompound
@args table values?

@desc
**This class does not inherit \`DLib.NBT.TagArrayBased\` but \`DLib.NBT.Base\`!**
see !c:NBTTagCompound for methods
@enddesc

@returns
table: newly created key-value table tag
`)

output.push(`
@fname NBTTagCompound:ReadFile
@args BytesBuffer stream

@desc
attempts to read a file from stream
@enddesc

@returns
boolean: whenever read was successful
`)

output.push(`
@fname NBTTagCompound:ReadFileProtected
@args BytesBuffer stream

@desc
attempts to read a file from stream. unlike \`ReadFile\`, this will throw
Lua error on any read error
and does not return anything
@enddesc
`)

output.push(`
@fname NBTTagCompound:WriteFile
@args BytesBuffer stream

@desc
writes a file structure + serialize to the stream
@enddesc
`)

output.push(`
@fname NBTTagCompound:AddTag
@alias NBTTagCompound:SetTag
@args string key, table tag

@desc
tag is any of the available tag classes
@enddesc

@returns
table: self
`)

output.push(`
@fname NBTTagCompound:AddTag2
@alias NBTTagCompound:SetTag2
@args string key, table tag

@desc
same as \`:AddTag()\`, except it returns newly set value back
@enddesc

@returns
table: the \`tag\` passed to this function
`)

output.push(`
@fname NBTTagCompound:RemoveTag
@args string key

@returns
table: self
`)

output.push(`
@fname NBTTagCompound:GetValue

@returns
table: key-value table of Lua values
`)

output.push(`
@fname NBTTagCompound:HasTag
@args string key

@returns
boolean
`)

output.push(`
@fname NBTTagCompound:GetTag
@args string key

@returns
table: tag or nil
`)

output.push(`
@fname NBTTagCompound:GetTagValue
@args string key

@returns
any: or error when tag does not exist
`)

output.push(`
@fname NBTTagCompound:iterate
@alias NBTTagCompound:iterator
@alias NBTTagCompound:pairs

@returns
function: iterator
`)

const m1 = [
	'AddByte',
	'AddShort',
	'AddInt',
	'AddFloat',
	'AddDouble',
	'AddLong',
	'AddString',
]

const m2 = [
	'AddByteArray',
	'AddIntArray',
	'AddLongArray',
	//'AddTagList',
	'AddTagCompound',
	//'AddTypedValue',
]

for (const fname of m1) {
	output.push(`
@fname NBTTagCompound:${fname}
@args string key, any value

@desc
creates a corresponding tag and adds it to compound
@enddesc

@returns
table: self
`)
}

for (const fname of m2) {
	output.push(`
@fname NBTTagCompound:${fname}
@args string key, any value

@desc
creates a corresponding tag and adds it to compound
@enddesc

@returns
table: newly created and added tag
`)
}

output.push(`
@fname NBTTagCompound:AddTagList
@args string key, number tagID, table values

@returns
table: newly created and added tag
`)

output.push(`
@fname NBTTagCompound:AddTypedValue
@args string key, any value

@desc
attempts to determine tag type for given value
throws an error when can't determine tag type
@enddesc

@returns
table: self or created tag
`)

output.push(`
@fname DLib.NBT.GetTyped
@args number tagID

@returns
table: (also a function) of corresponding tag at given ID
`)

output.push(`
@fname DLib.NBT.GetTypedID
@args string tagID

@returns
table: (also a function) of corresponding tag at given ID
`)

return output

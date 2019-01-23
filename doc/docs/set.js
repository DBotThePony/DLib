
const output = []

output.push(`
@fname DLib.Set

@desc
See !c:ArraySet class definitions for documentation
@enddesc

@returns
table: newly created ArraySet
`)

output.push(`
@fname DLib.HashSet

@desc
It inherit everything from !c:ArraySet
except internally it use table as hashmap
See !c:HashSet
@enddesc

@returns
table: newly created HashSet
`)

output.push(`
@fname ArraySet:Add
@args any value

@returns
boolean: true if value was added
`)

output.push(`
@fname ArraySet:AddArray
@args table arrayOfValues
`)

output.push(`
@fname ArraySet:Has
@alias ArraySet:Includes
@alias ArraySet:Contains
@args any value

@returns
boolean
`)

output.push(`
@fname ArraySet:Remove
@alias ArraySet:Delete
@alias ArraySet:UnSet
@args any value

@returns
boolean
`)

output.push(`
@fname ArraySet:GetValues

@returns
table: MODIFIABLE array of set's values
`)

output.push(`
@fname ArraySet:CopyValues

@returns
table: a copy of array of set's values
`)

output.push(`
@fname HashSet:CopyHashTable

@returns
table: value->value
`)

output.push(`
@fname DLib.Enum
@args vararg enumList

@desc
Enum values can be anything, but i suppose you want to use strings
@enddesc

@returns
table: newly created !c:Enum
`)

output.push(`
@fname Enum:Encode
@args any value, number indexOnFailure = 1

@desc
Attempts to return number index for specified values
@enddesc

@returns
number: enum index
`)

output.push(`
@fname Enum:Write
@args any value, number indexOnFailure = 1

@desc
\`:Encode\` + !g:net.WriteUInt
@enddesc
`)

output.push(`
@fname Enum:Decode
@args number value, number indexOnFailure = 1

@desc
Attempts to return enum value at specified index
@enddesc

@returns
any: value at index or value at \`indexOnFailure\`
`)

output.push(`
@fname Enum:Read
@args any value, number indexOnFailure = 1

@desc
!g:net.ReadUInt + \`:Decode\`
@enddesc
`)

return output

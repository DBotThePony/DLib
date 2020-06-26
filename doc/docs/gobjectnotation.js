
return [`
@fname DLib.GON.FindProvider
@args string identity

@returns
any: Provider class table or false
`,`
@fname DLib.GON.RemoveProvider
@args table provider

@desc
Removes registered provider from tables (it have not to be exactly
the same provider as registered earlier, since it does not use memory addresses
rather than identity strings)
@enddesc
`,`
@fname DLib.GON.RegisterProvider
@args table provider

@desc
It have to implement all methods defined by \`DLib.GON.IDataProvider\` class-table

For more info, see \`IDataProvider\` class documentation
@enddesc
`,`
@fname DLib.GON.Serialize
@args any value, boolean toBuffer = true

@desc
Serializes the value. Returns \`DLib.GON.Structure\` if \`toBuffer\` is false,
\`DLib.BytesBuffer\` otherwise.
@enddesc
`,`
@fname DLib.GON.Deserialize
@args table bytesBuffer, boolean retreiveValue = true

@desc
\`bytesBuffer\` is a \`DLib.BytesBuffer\` instance and it will be read from it's current pointer.
Returns \`DLib.GON.Structure\` if \`retreiveValue\` is false,
the (root) value serialized otherwise.
@enddesc
`,`
@fname DLib.GON.IDataProvider:LuaTypeIdentify

@returns
any: lua type identify (string/table)
`,`
@fname DLib.GON.IDataProvider:ShouldPutIntoMainRegistry

@returns
boolean
`,`
@fname DLib.GON.IDataProvider:GetIdentity

@returns
string: identity to be stored in output file and for provider search
`,`
@fname DLib.GON.IDataProvider:Ask
@args table self, any value, string luatype = type(value)

@returns
boolean: whenever provider is suitable for specified value
`,`
@fname DLib.GON.IDataProvider:Deserialize
@args table bytesBuffer, table gonStructure, number heapID, number bytesLength

@desc
\`bytesBuffer\` = \`DLib.BytesBuffer\`
\`gonStructure\` = \`DLib.GON.Structure\`
\`heapID\` is an unique number of this value in file being deserialized
\`bytesLength\` is length in bytes of serialized value
@enddesc

@returns
table: provider class-table. If value is corrupted or unknown, return \`DLib.GON.UnknownValue\` instead
`,`
@fname IDataProvider:new
@args table structure, number id
`,`
@fname IDataProvider:GetValue
@returns
any
`,`
@fname IDataProvider:GetStructure
@returns
table: \`DLib.GON.Structure\`
`,`
@fname IDataProvider:GetHeapID
@returns
number
`,`
@fname IDataProvider:GetIdentity
@returns
string: defaults to \`self.__class:GetIdentity()\`
`,`
@fname IDataProvider:IsKnownValue
@returns
boolean: \`true\`
`,`
@fname IDataProvider:GetRegistryID
@internal
@returns
any: \`self._identity_id\`
`,`
@fname IDataProvider:IsInstantValue
@returns
boolean: return \`false\` if your value depends on other values in heap (e.g. a table), \`true\` otherwise
`,`
@fname IDataProvider:SetValue
@args any value

@returns
table: self
`,`
@fname GONStructure:new

@returns
table: self
`,`
@fname GONStructure:GetHeapValue
@args: number id

@returns
any: table value or nil
`,`
@fname GONStructure:NextHeapIdentifier

@returns
number
`,`
@fname GONStructure:FindInHeap
@args any value

@returns
any: provider with value or false
`,`
@fname GONStructure:GetIdentityID
@internal
@args string identity

@desc
Errors when there is 255 identities already present
@enddesc

@returns
number: numeric identity of specified string identity
`,`
@fname GONStructure:AddToHeap
@args any value

@returns
any: boolean status or provider with serialized value
number: error code (if any)
`,`
@fname GONStructure:SetRoot
@args table provider

@desc
Provider already should be in heap of structure
@enddesc
`,`
@fname GONStructure:IsHeapBig

@returns
boolean: whenever uint is used instead of ushort for heap IDs in target file
`,`
@fname GONStructure:WriteHeader
@internal
@args table bytesBuffer
`,`
@fname GONStructure:WriteHeap
@internal
@args table bytesBuffer
`,`
@fname GONStructure:WriteRoot
@internal
@args table bytesBuffer
`,`
@fname GONStructure:ReadHeader
@internal
@args table bytesBuffer
`,`
@fname GONStructure:ReadHeap
@internal
@args table bytesBuffer
`,`
@fname GONStructure:ReadRoot
@internal
@args table bytesBuffer
`,`
@fname GONStructure:WriteFile
@args table bytesBuffer
`,`
@fname GONStructure:ReadFile
@args table bytesBuffer
`,`
@fname GONStructure:CreateBuffer
@returns
table: \`DLib.BytesBuffer\`
`
]

# Strong Entity Link
### For GLua
It allows you to create "strong links" to entities on client. It means, if entity is gone from PVS and client lagged hard, it would not lost all links
to all entities outside PVS forever, they will just become invalid on GMod side, but not on Lua side, where they were created by StrongEntity() function,
allowing futher changes on entity's table. Also, it will become valid again when entity will be networked by the server again.

Basic usage:

```lua
local myEntity = StrongEntity(4)
print(myEntity)
print(myEntity:IsValid())
<...> more as usual...
```

## BUT!

### Using in native functions
```lua
local myEntity = StrongEntity(84)
local anotherEntity = StrongEntity(104)

myEntity:SetParent(anotherEntity) -- WRONG!
anotherEntity:SetParent(myEntity) -- WRONG!

myEntity:SetParent(anotherEntity:GetEntity()) -- Valid
anotherEntity:SetParent(myEntity:GetEntity()) -- Valid

myEntity:GetEntity():SetParent(anotherEntity:GetEntity()) -- Valid too
anotherEntity:GetEntity():SetParent(myEntity:GetEntity()) -- Valid too
```

### Comparing
```lua
local myEntity = StrongEntity(84)
local anotherEntity = StrongEntity(104)

local myEntityNative = Entity(84)
local anotherEntityNative = Entity(104)

print(myEntity == anotherEntity) -- Valid
print(myEntityNative == anotherEntityNative) -- Valid
print(myEntity == anotherEntityNative) -- Invalid :(
print(anotherEntity == anotherEntityNative) -- Invalid :(

print(anotherEntity == StrongEntity(anotherEntityNative)) -- Valid :)
print(myEntity == StrongEntity(myEntityNative)) -- Valid :)
```

I know that comparing is quite broken, but that's gmod :(

That's all.

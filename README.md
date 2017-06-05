# Strong Entity Link
### For GLua
It allows you to create "strong links" to entities on client. It means, if entity is gone from PVS and client lagged hard, it would not lost all links
to all entities outside PVS forever, they will just become invalid on GMod side, but not on Lua side, where they were created by StrongEntity() function,
allowing futher changes on entity's table. Also, it will become valid again when entity will be networked by the server again.

Basic usage:

```lua
local myEntity = StrongEntity(4)
print(myEntity)
<...> Do something...
```

That's all.

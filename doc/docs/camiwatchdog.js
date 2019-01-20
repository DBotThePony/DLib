
const output = []

output.push(`
@fname DLib.CAMIWatchdog
@args string identifier, number repeatSpeed = 10, vararg permStrings

@desc
Creates a new permission watchdog
@enddesc

@returns
table: newly created CAMIWatchdog
`)

output.push(`
@fname CAMIWatchdog:Track
@args string perm, vararg perms

@desc
Adds passed permission strings to tracked ones
@enddesc

@returns
table: self
`)

output.push(`
@fname CAMIWatchdog:HasPermission
@args Player ply, string perm

@desc
\`ply\` argument can be omitted on client realm
@enddesc

@returns
boolean
`)

output.push(`
@fname CAMIWatchdog:HandlePanel
@args string permission, Panel panel

@client

@desc
Automatically calls !g:Panel:SetEnabled on passed panel based on permission
@enddesc

@returns
table: self
`)

output.push(`
@fname CAMIWatchdog:TriggerUpdate
@internal
`)

output.push(`
@fname CAMIWatchdog:TriggerUpdateClient
@internal
@client
`)

output.push(`
@fname CAMIWatchdog:TriggerUpdateRegular
@internal
`)

return output

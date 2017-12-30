
--
-- Copyright (C) 2017-2018 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

checkForEntity = (ent) -> isentity(ent) or type(ent) == 'table' and ent.GetEntity and isentity(ent\GetEntity())

class DLib.NetworkChangeState
	new: (key = '', keyValid = '', newValue, obj, len = 24, ply = NULL) =>
		@key = key
		@keyValid = keyValid
		@oldValue = obj[key]
		@newValue = newValue
		@ply = ply
		@time = CurTime()
		@rtime = RealTime()
		@stime = SysTime()
		@obj = obj
		@objID = obj.netID
		@len = len
		@rlen = len - 24 -- ID - 16 bits, variable id - 8 bits
		@cantApply = false
		@networkChange = true
	GetPlayer: => @ply
	ChangedByClient: => not @networkChange or IsValid(@ply)
	ChangedByPlayer: => not @networkChange or IsValid(@ply)
	ChangedByServer: => not @networkChange or not IsValid(@ply)
	GetKey: => @keyValid
	GetVariable: => @keyValid
	GetVar: => @keyValid
	GetKeyInternal: => @key
	GetVariableInternal: => @key
	GetVarInternal: => @key
	GetNewValue: => @newValue
	GetValue: => @newValue
	GetCantApply: => @cantApply
	SetCantApply: (val) => @cantApply = val
	NewValue: => @newValue
	GetOldValue: => @oldValue
	OldValue: => @oldValue
	CurTime: => @time
	GetCurTime: => @time
	GetReceiveTime: => @time
	GetReceiveStamp: => @time
	RealTime: => @rtime
	GetRealTime: => @rtime
	SysTime: => @stime
	GetSysTime: => @stime
	GetObject: => @obj
	GetNWObject: => @obj
	GetNetworkedObject: => @obj
	GetLength: => @rlen
	GetRealLength: => @len
	ChangedByNetwork: => @networkChange

	Revert: => @obj[@key] = @oldValue if not @cantApply
	Apply: => @obj[@key] = @newValue if not @cantApply

class DLib.NetworkedData extends DLib.ModifierBase
	@Setup = =>
		@NW_Vars = {} if @NW_Vars == nil
		@NW_VarsTable = {}
		@NW_Objects = {}
		@NW_Waiting = {}
		@NW_WaitID = -1
		@NW_Setup = true
		@NW_NextVarID = -1 if @NW_NextVarID == nil
		@NW_Create = "DLib.NW.Created.#{@__name}"
		@NW_Modify = "DLib.NW.Modified.#{@__name}"
		@NW_Broadcast = "DLib.NW.ModifiedBroadcast.#{@__name}"
		@NW_Remove = "DLib.NW.Removed.#{@__name}"
		@NW_Rejected = "DLib.NW.Rejected.#{@__name}"
		@NW_ReceiveID = "DLib.NW.ReceiveID.#{@__name}"
		@NW_CooldownTimerCount = "DLib_NW_CooldownTimerCount_#{@__name}"
		@NW_CooldownTimer = "DLib_NW_CooldownTimer_#{@__name}"
		@NW_CooldownMessage = "DLib_NW_CooldownMessage_#{@__name}"
		@NW_NextObjectID = 0
		@NW_NextObjectID_CL = 2 ^ 28

		if SERVER
			net.pool(@NW_Create)
			net.pool(@NW_Modify)
			net.pool(@NW_Remove)
			net.pool(@NW_ReceiveID)
			net.pool(@NW_Rejected)
			net.pool(@NW_Broadcast)

		net.BindMessageGroup(@NW_Create, 'dlibnwobject')
		net.BindMessageGroup(@NW_Modify, 'dlibnwobject')
		net.BindMessageGroup(@NW_Remove, 'dlibnwobject')
		net.BindMessageGroup(@NW_ReceiveID, 'dlibnwobject')
		net.BindMessageGroup(@NW_Rejected, 'dlibnwobject')
		net.BindMessageGroup(@NW_Broadcast, 'dlibnwobject')

		net.Receive @NW_Create, (len = 0, ply = NULL, obj) -> @OnNetworkedCreated(ply, len, obj)
		net.Receive @NW_Modify, (len = 0, ply = NULL, obj) -> @OnNetworkedModify(ply, len, obj)
		net.Receive @NW_Remove, (len = 0, ply = NULL, obj) -> @OnNetworkedDelete(ply, len, obj)
		net.Receive @NW_ReceiveID, (len = 0, ply = NULL) ->
			return if SERVER
			waitID = net.ReadUInt(16)
			netID = net.ReadUInt(16)
			obj = @NW_Waiting[waitID]
			@NW_Waiting[waitID] = nil
			return unless obj
			obj.NETWORKED = true
			@NW_Objects[obj.netID] = nil
			obj.netID = netID
			obj.waitID = nil
			@NW_Objects[netID] = obj
		net.Receive @NW_Rejected, (len = 0, ply = NULL) ->
			return if SERVER
			netID = net.ReadUInt(16)
			obj = @NW_Objects[netID]
			return unless obj
			return if obj.__LastReject and obj.__LastReject > RealTime()
			obj.__LastReject = RealTime() + 3
			obj.NETWORKED = false
			obj\Create()
		net.Receive @NW_Broadcast, (len = 0, ply = NULL) ->
			return if SERVER
			netID = net.ReadUInt(16)
			obj = @NW_Objects[netID]
			return unless obj
			obj\ReadNetworkData(len, ply)
	-- @__inherited = (child) => child.Setup(child)

	@AddNetworkVar = (getName = 'Var', readFunc = (->), writeFunc = (->), defValue, onSet = ((val) => val), networkByDefault = true) =>
		defFunc = defValue
		defFunc = (-> defValue) if type(defValue) ~= 'function'
		strName = "_NW_#{getName}"
		@NW_NextVarID += 1
		id = @NW_NextVarID
		tab = {:strName, :readFunc, :getName, :writeFunc, :defValue, :defFunc, :id, :onSet}
		table.insert(@NW_Vars, tab)
		@NW_VarsTable[id] = tab
		@__base[strName] = defFunc()
		@__base["Get#{getName}"] = => @[strName]
		@__base["Set#{getName}"] = (val = defFunc(), networkNow = networkByDefault) =>
			oldVal = @[strName]
			@[strName] = val
			nevVal = onSet(@, val)
			state = DLib.NetworkChangeState(strName, getName, nevVal, @)
			state.networkChange = false
			@SetLocalChange(state)
			if networkNow and @NETWORKED and (CLIENT and @@NW_ClientsideCreation and @GetOwner() == LocalPlayer() or SERVER)
				net.Start(@@NW_Modify)
				net.WriteUInt(@GetNetworkID(), 16)
				net.WriteUInt(id, 16)
				writeFunc(nevVal)
				if CLIENT
					net.SendToServer()
				else
					net.Broadcast()
	@NetworkVar = (...) => @AddNetworkVar(...)

	@NW_ClientsideCreation = false
	@NW_RemoveOnPlayerLeave = true
	@OnNetworkedCreated = (ply = NULL, len = 0, nwobj) =>
		return if SERVER and not @NW_ClientsideCreation
		if CLIENT
			netID = net.ReadUInt(16)
			creator = NULL
			creator = net.ReadStrongEntity() if net.ReadBool()
			obj = @NW_Objects[netID] or @(netID)
			obj.NW_Player = creator
			obj.NETWORKED = true
			obj.CREATED_BY_SERVER = true
			obj.NETWORKED_PREDICT = true
			obj\ReadNetworkData()
			@OnNetworkedCreatedCallback(obj, ply, len)
		else
			ply[@NW_CooldownTimer] = ply[@NW_CooldownTimer] or 0
			ply[@NW_CooldownTimerCount] = ply[@NW_CooldownTimerCount] or 0

			if ply[@NW_CooldownTimer] < RealTime()
				ply[@NW_CooldownTimerCount] = 1
				ply[@NW_CooldownTimer] = RealTime() + 10
			else
				ply[@NW_CooldownTimerCount] += 1

			if ply[@NW_CooldownTimerCount] >= 3
				ply[@NW_CooldownMessage] = ply[@NW_CooldownMessage] or 0
				if ply[@NW_CooldownMessage] < RealTime()
					DLib.Message 'Player ', ply, " is creating #{@__name} too quickly!"
					ply[@NW_CooldownMessage] = RealTime() + 1
				return

			waitID = net.ReadUInt(16)
			obj = @()
			obj.NW_Player = ply
			obj.NETWORKED_PREDICT = true
			obj\ReadNetworkData()
			obj\Create()
			timer.Simple 0.5, ->
				return if not IsValid(ply)
				net.Start(@NW_ReceiveID)
				net.WriteUInt(waitID, 16)
				net.WriteUInt(obj.netID, 16)
				net.Send(ply)
			@OnNetworkedCreatedCallback(obj, ply, len)
	@OnNetworkedCreatedCallback = (obj, ply = NULL, len = 0) => -- Override

	@OnNetworkedModify = (ply = NULL, len = 0) =>
		return if not @NW_ClientsideCreation and IsValid(ply)
		id = net.ReadUInt(16)
		obj = @NW_Objects[id]
		unless obj
			if SERVER
				net.Start(@NW_Rejected)
				net.WriteUInt(id, 16)
				net.Send(ply)
			return
		return if IsValid(ply) and obj.NW_Player ~= ply
		varID = net.ReadUInt(16)
		varData = @NW_VarsTable[varID]
		return unless varData
		{:strName, :getName, :readFunc, :writeFunc, :onSet} = varData
		newVal = onSet(obj, readFunc())
		return if newVal == obj["Get#{getName}"](obj)
		state = DLib.NetworkChangeState(strName, getName, newVal, obj, len, ply)
		state\Apply()
		obj\NetworkDataChanges(state)
		if SERVER
			net.Start(@NW_Modify)
			net.WriteUInt(id, 16)
			net.WriteUInt(varID, 16)
			writeFunc(newVal)
			net.SendOmit(ply)
		@OnNetworkedModifyCallback(state)
	@OnNetworkedModifyCallback = (state) => -- Override

	@OnNetworkedDelete = (ply = NULL, len = 0) =>
		return if not @NW_ClientsideCreation and IsValid(ply)
		id = net.ReadUInt(16)
		obj = @NW_Objects[id]
		return unless obj
		obj\Remove(true)
		@OnNetworkedDeleteCallback(obj, ply, len)
	@OnNetworkedDeleteCallback = (obj, ply = NULL, len = 0) => -- Override

	@ReadNetworkData = =>
		output = {strName, {getName, readFunc()} for {:getName, :strName, :readFunc} in *@NW_Vars}
		return output

	new: (netID, localObject = false) =>
		super()
		@valid = true
		@NETWORKED = false
		@NETWORKED_PREDICT = false

		@[data.strName] = data.defFunc() for data in *@@NW_Vars when data.defFunc

		if SERVER
			@netID = @@NW_NextObjectID
			@@NW_NextObjectID += 1
		else
			netID = -1 if netID == nil
			@netID = netID

		@@NW_Objects[@netID] = @
		@NW_Player = NULL if SERVER
		@NW_Player = LocalPlayer() if CLIENT
		@isLocal = localObject
		@NW_Player = LocalPlayer() if localObject

	GetOwner: => @NW_Player
	IsValid: => @valid
	IsNetworked: => @NETWORKED
	IsGoingToNetwork: => @NETWORKED_PREDICT
	SetIsGoingToNetwork: (val = @NETWORKED) => @NETWORKED_PREDICT = val
	IsLocal: => @isLocal
	IsLocalObject: => @isLocal
	GetNetworkID: => @netID
	NetworkID: => @netID
	NetID: => @netID
	Remove: (byClient = false) =>
		@@NW_Objects[@netID] = nil
		@valid = false
		if CLIENT and @isLocal and @NETWORKED and @@NW_ClientsideCreation
			net.Start(@@NW_Remove)
			net.WriteUInt(@netID, 16)
			net.SendToServer()
		elseif SERVER and @NETWORKED
			net.Start(@@NW_Remove)
			net.WriteUInt(@netID, 16)
			if not IsValid(@NW_Player) or not byClient
				net.Broadcast()
			else
				net.SendOmit(@NW_Player)

	NetworkDataChanges: (state) => -- Override
	SetLocalChange: (state) => -- Override
	ReadNetworkData: (len = 24, ply = NULL, silent = false, applyEntities = true) =>
		data = @@ReadNetworkData()
		validPly = IsValid(ply)
		states = [DLib.NetworkChangeState(key, keyValid, newVal, @, len, ply) for key, {keyValid, newVal} in pairs data]
		for state in *states
			if not validPly or applyEntities or not isentity(state\GetValue())
				state\Apply()
				@NetworkDataChanges(state) unless silent

	NetworkedIterable: (grabEntities = true) =>
		data = [{getName, @[strName]} for {:strName, :getName} in *@@NW_Vars when grabEntities or not checkForEntity(@[strName])]
		return data

	ApplyDataToObject: (target, applyEntities = false) =>
		for {key, value} in *@NetworkedIterable(applyEntities)
			target["Set#{key}"](target, value) if target["Set#{key}"]
		return target

	WriteNetworkData: => writeFunc(@[strName]) for {:strName, :writeFunc} in *@@NW_Vars
	ReBroadcast: =>
		return false if not @NETWORKED
		return false if CLIENT
		net.Start(@@NW_Broadcast)
		net.WriteUInt(@netID, 16)
		@WriteNetworkData()
		net.Broadcast()
		return true
	SendVar: (Var = '') =>
		return if @[Var] == nil

	__tostring: => "[NetworkedObject:#{@netID}|#{@ent}]"

	Create: =>
		return if @NETWORKED
		return if CLIENT and (not @@NW_ClientsideCreation or @CREATED_BY_SERVER)
		@NETWORKED = true if SERVER
		@NETWORKED_PREDICT = true
		if SERVER
			net.Start(@@NW_Create)
			net.WriteUInt(@netID, 16)
			net.WriteBool(IsValid(@NW_Player))
			net.WriteStrongEntity(@NW_Player) if IsValid(@NW_Player)
			@WriteNetworkData()
			net.CompressOngoing()
			filter = RecipientFilter()
			filter\AddAllPlayers()
			filter\RemovePlayer(@NW_Player) if IsValid(@NW_Player)
			net.Send(filter)
		else
			@@NW_WaitID += 1
			@waitID = @@NW_WaitID
			net.Start(@@NW_Create)
			before = net.BytesWritten()
			net.WriteUInt(@waitID, 16)
			@WriteNetworkData()
			net.CompressOngoing()
			after = net.BytesWritten()
			net.SendToServer()
			@@NW_Waiting[@waitID] = @
			return after - before
	NetworkTo: (targets = {}) =>
		net.Start(@@NW_Create)
		net.WriteUInt(@netID, 16)
		net.WriteBool(IsValid(@NW_Player))
		net.WriteStrongEntity(@NW_Player) if IsValid(@NW_Player)
		@WriteNetworkData()
		net.CompressOngoing()
		net.Send(targets)

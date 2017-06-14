
--
-- Copyright (C) 2017 DBot
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

local VERSION = 201706141145

if _G.StrongEntityLinkVersion and _G.StrongEntityLinkVersion >= VERSION then return end
_G.StrongEntityLinkVersion = VERSION

local ENTITIES_REGISTRY = {}
local WRAPPED_FUNCTIONS = {}

local entMeta = FindMetaTable('Entity')
local isValid = entMeta.IsValid
local getTable = entMeta.GetTable
local ent__eq = entMeta.__eq
local entIndex = entMeta.EntIndex
entMeta.GetEntity = function(self, ...)
    local oldVal = self:GetTable().GetEntity

    if oldVal then
        return oldVal(self, ...)
    end

    return self
end

local UniqueNoValue = 'STRONG_ENTITY_RESERVED_NO_VALUE'

local StrongLinkMetadata = {
    GetEntity = function(self)
        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        return self.__strong_entity_link
    end,

    GetTable = function(self)
        local upvalue = self
        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        local ourTable = self.__strong_entity_table

        return setmetatable({}, {
            __index = function(self, key)
                local value = ourTable[key]

                if value ~= nil then
                    return value
                else
                    if not isValid(upvalue.__strong_entity_link) then
                        upvalue.__strong_entity_link = Entity(upvalue.__strong_entity_link_id)
                    end

                    if isValid(upvalue.__strong_entity_link) then
                        return getTable(upvalue.__strong_entity_link)[key]
                    else
                        return nil
                    end
                end
            end,

            __newindex = function(self, key, value)
                if not isValid(upvalue.__strong_entity_link) then
                    upvalue.__strong_entity_link = Entity(upvalue.__strong_entity_link_id)
                end

                if not isValid(upvalue.__strong_entity_link) then
                    if value ~= nil then
                        ourTable[key] = value
                    else
                        ourTable[key] = UniqueNoValue
                    end
                else
                    getTable(upvalue.__strong_entity_link)[key] = value
                    ourTable[key] = value
                end
            end
        })
    end,

    EntIndex = function(self)
        return self.__strong_entity_link_id
    end
}

local metaData = {
    __index = function(self, key)
        if key == '__strong_entity_link' then return rawget(self, '__strong_entity_link') end
        if key == '__strong_entity_link_id' then return rawget(self, '__strong_entity_link_id') end
        if key == '__strong_entity_funcs' then return rawget(self, '__strong_entity_funcs') end
        if key == '__strong_entity_table' then return rawget(self, '__strong_entity_table') end
        if key == '__strong_entity' then return true end

        local value = rawget(self, key)

        if value ~= nil then
            return value
        end

        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        if StrongLinkMetadata[key] ~= nil then
            return StrongLinkMetadata[key]
        end

        if isValid(self.__strong_entity_link) then
            local val = self.__strong_entity_link[key]

            if type(val) == 'function' then
                if not self.__strong_entity_funcs[val] then
                    self.__strong_entity_funcs[val] = function(...)
                        local upvalueEntity = self.__strong_entity_link
                        local args = {...}
                        local len = #args

                        for i = 1, len do
                            if args[i] == self then
                                args[i] = upvalueEntity
                            end
                        end

                        return val(unpack(args))
                    end
                end

                return self.__strong_entity_funcs[val]
            end

            return val
        else
            local value = self.__strong_entity_table[key]
            if value ~= UniqueNoValue then
                return value
            else
                return nil
            end
        end
    end,

    __newindex = function(self, key, value)
        if not isValid(self.__strong_entity_link) then
            self.__strong_entity_link = Entity(self.__strong_entity_link_id)
        end

        if isValid(self.__strong_entity_link) then
            getTable(self.__strong_entity_link)[key] = value
            self.__strong_entity_table[key] = value
        else
            if value ~= nil then
                self.__strong_entity_table[key] = value
            else
                self.__strong_entity_table[key] = UniqueNoValue
            end
        end
    end,

    __tostring = function(self)
        return tostring(self.__strong_entity_link)
    end,

    __eq = function(self, target)
        local ent = self.__strong_entity_link
        local tType = type(target)
        local validEnt = tType ~= 'number' and tType ~= 'string'
        return ent == target or validEnt and (ent == target.__strong_entity_link or target.EntIndex and target.EntIndex == self.__strong_entity_link_id)
    end
}

local function InitStrongEntity(entIndex)
    if type(entIndex) ~= 'number' then
        if IsValid(entIndex) then
            entIndex = entIndex:EntIndex()

            if entIndex < 0 then
                return NULL
            end
        else
            entIndex = -1
        end
    end
    
    if ENTITIES_REGISTRY[entIndex] then
        return ENTITIES_REGISTRY[entIndex]
    end

    local newObject = {}
    newObject.__strong_entity_table = {}
    newObject.__strong_entity_funcs = {}
    newObject.__strong_entity = true
    newObject.__strong_entity_link = Entity(entIndex)
    newObject.__strong_entity_link_id = entIndex

    setmetatable(newObject, metaData)
    ENTITIES_REGISTRY[entIndex] = newObject
    return newObject
end

_G.StrongEntity = InitStrongEntity

if CLIENT then
    hook.Add('NetworkEntityCreated', 'StrongEntity', function(self)
        local id = self:EntIndex()

        if not ENTITIES_REGISTRY[id] then return end
        local tab = self:GetTable()
        local strongTable = ENTITIES_REGISTRY[id].__strong_entity_table
        for key, value in pairs(strongTable) do
            if value ~= UniqueNoValue then
                tab[key] = value
            else
                tab[key] = nil
                strongTable[key] = nil
            end
        end
    end)

    net.Receive('StrongEntity.Removed', function()
        ENTITIES_REGISTRY[net.ReadUInt(16)] = nil
    end)
else
    util.AddNetworkString('StrongEntity.Removed')

    hook.Add('EntityRemoved', 'StrongEntity', function(self)
        net.Start('StrongEntity.Removed')
        net.WriteUInt(self:EntIndex(), 16)
        net.Broadcast()
    end)
end

function net.WriteStrongEntity(ent)
    if type(ent) == 'number' then
        local isValidEntity = ent >= 0
        net.WriteBool(isValidEntity)

        if isValidEntity then
            net.WriteUInt(ent, 16)
        end
    else
        local isValidEntity = IsValid(ent) and ent:EntIndex() >= 1 or ent == Entity(0)
        net.WriteBool(isValidEntity)

        if isValidEntity then
            net.WriteUInt(ent:EntIndex(), 16)
        end
    end
end

function net.ReadStrongEntity()
    local isValidEntity = net.ReadBool()

    if isValidEntity then
        local val = net.ReadUInt(16)
        return InitStrongEntity(val)
    else
        return InitStrongEntity(-1)
    end
end

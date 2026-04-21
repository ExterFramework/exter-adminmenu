Config = Config or {}

local function hasResource(name)
    return GetResourceState(name) == 'started'
end

local detected = 'standalone'
if hasResource('qbx_core') then
    detected = 'qbox'
elseif hasResource('qb-core') then
    detected = 'qbcore'
elseif hasResource('es_extended') then
    detected = 'esx'
end

Config.Framework = Config.Framework or detected

QBCore = QBCore or {}
QBCore.Functions = QBCore.Functions or {}
QBCore.Shared = QBCore.Shared or {}
QBCore.Commands = QBCore.Commands or {}

local qbObject = nil
if hasResource('qb-core') then
    qbObject = exports['qb-core']:GetCoreObject()
end

local esxObject = nil
if hasResource('es_extended') then
    esxObject = exports['es_extended']:getSharedObject()
end

local callbacks = {}

local function normalizeType(msgType)
    if msgType == 'error' then return 'error' end
    if msgType == 'success' then return 'success' end
    return 'inform'
end

if IsDuplicityVersion() then
    local function getIdentifierFromPlayer(player, idType)
        if not player then return nil end
        if Config.Framework == 'esx' then
            if idType == 'license' then
                return player.identifier
            end
            if idType == 'steam' then
                return player.identifier
            end
            if idType == 'ip' then
                return GetPlayerEndpoint(player.source)
            end
            for _, identifier in ipairs(GetPlayerIdentifiers(player.source)) do
                if identifier:find(idType .. ':', 1, true) == 1 then
                    return identifier
                end
            end
            return nil
        end

        if qbObject and qbObject.Functions then
            return qbObject.Functions.GetIdentifier(player.PlayerData.source, idType)
        end
        for _, identifier in ipairs(GetPlayerIdentifiers(player.source or player)) do
            if identifier:find(idType .. ':', 1, true) == 1 then
                return identifier
            end
        end
        return nil
    end

    function QBCore.Functions.CreateCallback(name, cb)
        callbacks[name] = cb
        RegisterNetEvent('exter-adminmenu:server:trigger-callback:' .. name, function(requestId, ...)
            local src = source
            cb(src, function(...)
                TriggerClientEvent('exter-adminmenu:client:callback-response', src, requestId, ...)
            end, ...)
        end)
    end

    function QBCore.Functions.GetPlayers()
        if Config.Framework == 'esx' and esxObject then
            return esxObject.GetPlayers()
        end
        if qbObject and qbObject.Functions then
            return qbObject.Functions.GetPlayers()
        end
        local players = {}
        for _, id in ipairs(GetPlayers()) do
            players[#players + 1] = tonumber(id)
        end
        return players
    end

    function QBCore.Functions.GetPlayer(src)
        if Config.Framework == 'esx' and esxObject then
            return esxObject.GetPlayerFromId(src)
        end
        if qbObject and qbObject.Functions then
            return qbObject.Functions.GetPlayer(src)
        end
        return nil
    end

    function QBCore.Functions.GetIdentifier(src, idType)
        local player = QBCore.Functions.GetPlayer(src)
        return getIdentifierFromPlayer(player or { source = src }, idType)
    end

    function QBCore.Functions.GetPermission(src)
        if Config.Framework == 'esx' and esxObject then
            local player = esxObject.GetPlayerFromId(src)
            return (player and player.getGroup and player.getGroup()) or 'user'
        end
        if qbObject and qbObject.Functions and qbObject.Functions.GetPermission then
            return qbObject.Functions.GetPermission(src)
        end
        return IsPlayerAceAllowed(src, 'command') and 'admin' or 'user'
    end

    function QBCore.Commands.Add(name, _, _, _, cb, permission)
        RegisterCommand(name, function(src, args)
            if src ~= 0 and permission and not IsPlayerAceAllowed(src, ('group.%s'):format(permission)) then
                return
            end
            cb(src, args)
        end, true)
    end

    function QBCore.Functions.Notify(src, message, msgType)
        TriggerClientEvent('ox_lib:notify', src, { description = message, type = normalizeType(msgType) })
        TriggerClientEvent('QBCore:Notify', src, message, msgType)
        TriggerClientEvent('esx:showNotification', src, message)
    end
else
    local callbackId = 0
    local pending = {}

    RegisterNetEvent('exter-adminmenu:client:callback-response', function(requestId, ...)
        if pending[requestId] then
            pending[requestId](...)
            pending[requestId] = nil
        end
    end)

    function QBCore.Functions.TriggerCallback(name, cb, ...)
        callbackId = callbackId + 1
        pending[callbackId] = cb
        TriggerServerEvent('exter-adminmenu:server:trigger-callback:' .. name, callbackId, ...)
    end

    function QBCore.Functions.Notify(message, msgType)
        if hasResource('ox_lib') then
            lib.notify({ description = message, type = normalizeType(msgType) })
        end
        if Config.Framework == 'esx' then
            TriggerEvent('esx:showNotification', message)
        elseif hasResource('qb-core') then
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName(message)
            EndTextCommandThefeedPostTicker(false, false)
        else
            print(('[AdminMenu] %s'):format(message))
        end
    end

    RegisterNetEvent('QBCore:Notify', function(message, msgType)
        QBCore.Functions.Notify(message, msgType)
    end)

    function QBCore.Functions.GetPlayerData()
        if Config.Framework == 'esx' and esxObject then
            local data = esxObject.GetPlayerData()
            return {
                name = (data.firstName and data.lastName) and (data.firstName .. ' ' .. data.lastName) or GetPlayerName(PlayerId()),
                citizenid = data.identifier,
            }
        end
        if qbObject and qbObject.Functions then
            return qbObject.Functions.GetPlayerData()
        end
        return { name = GetPlayerName(PlayerId()) }
    end

    function QBCore.Functions.LoadModel(model)
        local hash = type(model) == 'number' and model or joaat(model)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(10) end
    end

    function QBCore.Functions.GetClosestVehicle(coords)
        local veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
        if veh and veh ~= 0 then
            return veh, #(GetEntityCoords(veh) - coords)
        end
        return 0, 999.0
    end

    QBCore.Shared.Items = (qbObject and qbObject.Shared and qbObject.Shared.Items) or {}
    QBCore.Shared.Jobs = (qbObject and qbObject.Shared and qbObject.Shared.Jobs) or {}
    QBCore.Shared.Gangs = (qbObject and qbObject.Shared and qbObject.Shared.Gangs) or {}
    QBCore.Shared.Vehicles = (qbObject and qbObject.Shared and qbObject.Shared.Vehicles) or {}
    QBCore.Config = (qbObject and qbObject.Config) or { Money = { MoneyTypes = { cash = 0, bank = 0 } } }
end

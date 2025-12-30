local utils = require 'utils.server'
local cachedPeds = {}
local activeTasks = {}

local function acceptJob(source)
    if activeTasks[source] then
        utils.notify({
            source = source,
            description = 'Complete your current job.',
            type = 'error',
        })
        return
    end

    local success, response = exports.ox_inventory:AddItem(source, Config.flyerItem, Config.flyerAmount)
    if not success then
        utils.notify({
            source = source,
            description = response,
            type = 'error',
        })
        return
    end

    activeTasks[source] = {
        isActive = true,
        earnings = 0,
        handedOut = 0,
        flyers = Config.flyerAmount,
    }

    utils.notify({
        source = source,
        description = 'Thanks for the help, good luck out there.',
        type = 'success'
    })

    return activeTasks[source]
end

local function givePedFlyer(source, netId)
    if not activeTasks[source] then return end

    local player = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(player)

    local ped = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(ped) then return end

    if not utils.isNearCoords(ped, playerCoords, 10.0) then return end

    if cachedPeds[netId] then return end

    if activeTasks[source].handedOut == Config.flyerAmount then
        utils.notify({
            source = source,
            description = 'You already gave out the required flyers',
            type = 'error'
        })
        return
    end

    local success, response = exports.ox_inventory:RemoveItem(source, Config.flyerItem, 1)
    if not success then
        utils.notify({
            source = source,
            description = response,
            type = 'error'
        })
        return
    end

    activeTasks[source].handedOut = activeTasks[source].handedOut + 1

    utils.notify({
        source = source,
        description = 'Handed out '..activeTasks[source].handedOut.. '/'.. Config.flyerAmount .. ' flyers.',
        type = 'success',
        duration = 10000,
    })

    cachedPeds[netId] = true
    activeTasks[source].earnings = activeTasks[source].earnings + Config.flyerPayment
    activeTasks[source].flyers = activeTasks[source].flyers -1

    if activeTasks[source].flyers == 0 then
        utils.notify({
            source = source,
            description = 'All flyers have been handed out.',
            type = 'success',
            duration = 10000,
        })
    end

    return success
end

local function completeTasks(source)
    if not activeTasks[source] then return false end
    local player = GetPlayerPed(source)

    if activeTasks[source].flyers > 0 or activeTasks[source].handedOut < Config.flyerAmount then
        utils.notify({
            source = source,
            description = 'You still have flyers remaining',
            type = 'error',
            duration = 10000,
        })
        return false
    end

    if not utils.isNearCoords(player, Config.ped.coords.xyz, 10.0) then return false end

    if activeTasks[source].earnings > 0 then
        exports.ox_inventory:AddItem(source, 'money', activeTasks[source].earnings)
    end

    return true
end

lib.callback.register('kevin-cityflyers:server:acceptJob', function (source)
    return acceptJob(source)
end)

lib.callback.register('kevin-cityflyers:server:givePedFlyer', function (source, netId)
    return givePedFlyer(source, netId)
end)

lib.callback.register('kevin-cityflyers:server:completeTasks', function (source)
    return completeTasks(source)
end)

RegisterNetEvent('kevin-cityflyers:server:getMoreFlyers', function ()
    local source = source
    local player = GetPlayerPed(source)

    if not activeTasks[source] then return end
    if not utils.isNearCoords(player, Config.ped.coords.xyz, 10.0) then return end

    local currentFlyers = activeTasks[source].flyers
    if currentFlyers > 0 then
        utils.notify({
            source = source,
            description = 'You still have flyers, deliver them then you can get more.',
            type = 'error'
        })
        return
    end

    local success, response = exports.ox_inventory:AddItem(source, Config.flyerItem, Config.flyerAmount)
    if not success then
        utils.notify({
            source = source,
            description = response,
            type = 'error',
        })
        return
    end

    activeTasks[source].flyers = activeTasks[source].flyers + Config.flyerAmount
    activeTasks[source].handedOut = 0
end)
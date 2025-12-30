local utils = {}

utils.notify = function(data)
    lib.notify({
        title = data.title or 'Notification',
        description = data.description or '',
        type = data.type or 'info',
        position = data.position or 'top-right',
        duration = data.duration or 3000,
    })
end

utils.createBlip = function(data)
    local blip = 0
    if data.entity then
        blip = AddBlipForEntity(data.entity)
    elseif data.coords and not data.radius then
        blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    elseif data.radius then
        blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius)
    end

    if not data.radius then
        SetBlipSprite(blip, data.sprite or 1)
        SetBlipScale(blip, data.scale or 1.0)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(data.name or 'Blip')
        EndTextCommandSetBlipName(blip)
    end

    SetBlipAlpha(blip, data.alpha or 255)
    SetBlipColour(blip, data.color or 1)

    SetBlipAsShortRange(blip, data.shortRange or true)
    SetBlipRoute(blip, data.route or false)
    SetBlipRouteColour(blip, data.routeColor or data.color)

    if data.flashes then
        SetBlipFlashes(blip, true)
        SetBlipFlashInterval(blip, 500)
    end
    
    return blip
end

utils.createVehicle = function(data)
    local model = data.model
    lib.requestModel(model, 20000)

    local vehicle = CreateVehicle(model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, data.isNetwork or false, data.isMissionEntity or false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetModelAsNoLongerNeeded(model)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAlpha(vehicle, 0)

    for i = 0, 255, 51 do
        Wait(50)
        SetEntityAlpha(vehicle, i, false)
    end
    
    return vehicle
end

utils.createSphereZone = function(data)
    local zone = lib.zones.sphere({
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        radius = data.radius or 30.0,
        debug = data.debug or false,
        onEnter = function()
            if data.onEnter then
                data.onEnter()
            end
        end,
        onExit = function()
            if data.onExit then
                data.onExit()
            end
        end,
        inside = function()
            if data.inside then
                data.inside()
            end
        end,
    })

    return zone
end

local getTargetOptions = function(options, distance)
    local targetOptions = {}
    for i = 1, #options do
        targetOptions[i] = {
            icon = options[i].icon,
            label = options[i].label,
            onSelect = options[i].onSelect,
            action = options[i].onSelect,
            canInteract = options[i].canInteract,
            distance = distance or 2.5,
        }
    end
    return targetOptions
end

utils.addLocalEntityTarget = function(data)
    if Config.interaction.resource == 'ox' then
        exports.ox_target:addLocalEntity(data.entity, getTargetOptions(data.options, data.distance))
    elseif Config.interaction.resource == 'qb' then
        exports['qb-target']:AddTargetEntity(data.entity, {
            options = getTargetOptions(data.options, data.distance),
            distance = Config.interaction.distance,
        })
    end
end

utils.addGlobalPedTarget = function(data)
    if Config.interaction.resource == 'ox' then
        exports.ox_target:addGlobalPed(getTargetOptions(data.options, data.distance))
    elseif Config.interaction.resource == 'qb' then
        exports['qb-target']:AddGlobalPed({getTargetOptions(data.options, data.distance), distance = 2.5})
    end
end

return utils
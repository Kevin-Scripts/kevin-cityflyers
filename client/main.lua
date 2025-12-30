local utils = require 'utils.client'
local npc = 0
local task = {}
local cachePeds = {}

local function handPedFlyer(entity)
    local animAdict = 'mp_ped_interaction'
    local anim = 'handshake_guy_a'

    lib.requestAnimDict(animAdict)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    local success = lib.callback.await('kevin-cityflyers:server:givePedFlyer', false, netId)
    if not success then return end

    cachePeds[netId] = true

    ClearPedTasks(entity)
    TaskSetBlockingOfNonTemporaryEvents(entity, true)
    TaskTurnPedToFaceEntity(entity, cache.ped, 1500)
    Wait(1000)
    TaskTurnPedToFaceEntity(cache.ped, entity, 1500)
    Wait(1000)

    TaskPlayAnim(entity, animAdict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    TaskPlayAnim(cache.ped, animAdict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)

    Wait(GetAnimDuration(animAdict, anim) * 1000)
    TaskWanderStandard(entity, 10.0, 10)
    SetPedAsNoLongerNeeded(entity)
end

local function createBoss()
    if npc ~= 0 then return end

    local model = Config.ped.model
    local coords = Config.ped.coords
    local scenario = Config.ped.scenario

    lib.requestModel(model, 20000)
    npc = CreatePed(4, model, coords.x, coords.y, coords.z -1, coords.w, false, true)
    TaskStartScenarioInPlace(npc, scenario)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(model)

    utils.addLocalEntityTarget({
        entity = npc,
        options = {
            {
                label = 'Talk',
                icon = 'fa-solid fa-plane',
                onSelect = function()
                    if task.isActive then return end

                    exports.bl_dialog:showDialog({
                        ped = npc,
                        dialog = {
                            {
                                id = 'customer_countered',
                                job = 'City Flyers',
                                name = 'Sherry',
                                text = 'Hey, you look like someone who could use a few easy dollars. Local businesses pay us to get their flyers out around the city. Just walk around, hand them out, and don’t cause trouble.',
                                buttons = {
                                    {
                                        close = true,
                                        label = 'Accept Job',
                                        onSelect = function(switchDialog)
                                            local data = lib.callback.await('kevin-cityflyers:server:acceptJob', false)
                                            if not data then return end

                                            task = data
                                        end
                                    },
                                    {
                                        close = true,
                                        label = 'No Thanks',
                                        onSelect = function(switchDialog)
                                            utils.notify({
                                                title = 'City Flyers',
                                                description = 'Well I\'m always here when you\'re ready',
                                                type = 'error',
                                            })
                                        end
                                    }
                                },
                            },
                        }
                    })
                end,
                distance = 2.0,
            },
            {
                label = 'Get More Flyers',
                icon = 'fas fa-map',
                onSelect = function ()
                    TriggerServerEvent('kevin-cityflyers:server:getMoreFlyers')
                end,
                canInteract = function ()
                    return task.isActive
                end
            },
            {
                label = 'Complete Task',
                icon = 'fas fa-check',
                onSelect = function ()
                    local completed = lib.callback.await('kevin-cityflyers:server:completeTasks', false)
                    if not completed then return end

                    task = {}
                end,
                canInteract = function ()
                    return task.isActive
                end
            }
        },
    })
end

CreateThread(function ()
    utils.createBlip({
        coords = Config.ped.coords.xyz,
        sprite = 58,
        color = 43,
        scale = 0.7,
        name = 'City Flyers'
    })

    utils.createSphereZone({
        coords = Config.ped.coords.xyz,
        radius = 30.0,
        onEnter = function ()
            createBoss()
        end,
        onExit = function ()
            if npc == 0 then return end

            DeleteEntity(npc)
            npc = 0
        end
    })

    utils.addGlobalPedTarget({
        options = {
            {
                label = 'Hand Flyer',
                icon = 'fas fa-map',
                onSelect = function(data)
                    handPedFlyer(data.entity or data)
                end,
                canInteract = function(entity)
                    return task.isActive
                        and exports.ox_inventory:Search('count', Config.flyerItem) > 0
                        and not IsEntityPositionFrozen(entity)
                        and not cachePeds[NetworkGetNetworkIdFromEntity(entity)]
                        and not IsEntityDead(entity)
                end
            }
        },
        distance = 2.5
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

end)

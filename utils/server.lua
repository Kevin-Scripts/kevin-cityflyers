local utils = {}

utils.isNearCoords = function(entity, coords, dist)
    local entityCoords = GetEntityCoords(entity)
    local distance = #(entityCoords - coords)
    return distance < dist
end

utils.notify = function(data)
    TriggerClientEvent('ox_lib:notify', data.source, data)
end

return utils
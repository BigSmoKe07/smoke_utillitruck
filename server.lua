local trucks = {}

RegisterNetEvent('utillitruck:deployLegs', function(netId, objects)
    local src = source
    local veh = NetworkGetEntityFromNetworkId(netId)

    local truck = trucks[veh]
    trucks[veh] = objects and objects or truck

    local currentState = Entity(veh).state.crane or false
    local newState = not currentState

    if not newState then
        Entity(veh).state:set('crane', nil, true)
        return
    end

    local data = {
        newState,
        NetworkGetNetworkIdFromEntity(GetPlayerPed(src))
    }

    Entity(veh).state:set('hasCollision', true, true)
    Entity(veh).state:set('crane', data, true)
end)

AddEventHandler('entityRemoved', function(entity)
    if not trucks[entity] then return end

    local collision = trucks[entity]
    lib.array.forEach(collision, function(netId)
        local object = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(object) then
            DeleteEntity(object)
        end
    end)
end)

lib.versionCheck('BigSmoKe07/smoke_utillitruck')
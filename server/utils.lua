ESX = nil TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

StreamDataToClients = function(to, data)
    TriggerClientEvent('drones:updateDrones', (to or -1), data)
end

RequestDeleteDroneAfterPlayerDisconnect = function(owner, data)
    local xPlayer = ESX.GetPlayerFromId(owner)
    local dronesNewToReturn = 0
    local dronesBrokenToReturn = 0

    for i=1, #data, 1 do
        local drone = data[i]

        if drone.owner == owner then
            if drone.Broken == 0 then
                dronesNewToReturn = dronesNewToReturn+1
            else
                dronesBrokenToReturn = dronesBrokenToReturn+1
            end
        end
    end

    if xPlayer then
        xPlayer.addInventoryItem('drone', dronesNewToReturn)
        xPlayer.addInventoryItem('drone_broken', dronesBrokenToReturn)
    end

    TriggerClientEvent('drones:deleteOldPlayerDrones', -1, owner)
end
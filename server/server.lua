local RegisterDrone = {}

ESX.RegisterUsableItem('drone', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)

	local xPlayerDroneCount = 0
	for i=1, #RegisterDrone, 1 do
		if RegisterDrone[i].owner == xPlayer.source then
			xPlayerDroneCount = xPlayerDroneCount+1
		end
	end

	if xPlayerDroneCount >= Drone.Max_PlayerDrones then
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nie możesz latać więcej niż dwoma dronami!')
		return
	end

	xPlayer.removeInventoryItem('drone', 1)

	TriggerClientEvent('drones:useDrone', xPlayer.source, xPlayer.source)
end)

ESX.RegisterUsableItem('drone_cam', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	TriggerClientEvent('drones:useDroneCam', xPlayer.source)
end)

ESX.RegisterServerCallback('drones:pickupDrone', function(source, cb, isBroken)
	local xPlayer = ESX.GetPlayerFromId(source)

	if isBroken <= 50.0 then
		xPlayer.addInventoryItem('drone_broken', 1)
		cb(true)
	else
		xPlayer.addInventoryItem('drone', 1)
		cb(true)
	end	
end)

RegisterServerEvent('drones:buyNewDrone')
AddEventHandler('drones:buyNewDrone', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.getMoney() >= 500000 then
		xPlayer.removeMoney(500000)
		xPlayer.addInventoryItem('drone', 1)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Zakupiłeś/aś drona!')
	else
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nie posiadasz wystarczającej ilości gotówki!')
	end
end)

RegisterServerEvent('drones:buyNewDronePilot')
AddEventHandler('drones:buyNewDronePilot', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.getMoney() >= 100000 then
		xPlayer.removeMoney(100000)
		xPlayer.addInventoryItem('drone_cam', 1)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Zakupiłeś/aś pilot do drona!')
	else
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nie posiadasz wystarczającej ilości gotówki!')
	end
end)

RegisterServerEvent('drones:fixDrone')
AddEventHandler('drones:fixDrone', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.getMoney() >= 300000 then
		local xItem = xPlayer.getInventoryItem('drone_broken')

		if xItem.count > 0 then
			xPlayer.removeMoney(300000)
			xPlayer.removeInventoryItem('drone_broken', 1)
			xPlayer.addInventoryItem('drone', 1)
			TriggerClientEvent('esx:showNotification', xPlayer.source, 'Naprawiłeś/aś drona!')
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nie posiadasz drona do naprawy!')
		end
	else
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'Nie posiadasz wystarczającej ilości gotówki!')
	end
end)

RegisterServerEvent('drones:startUpFireEffect')
AddEventHandler('drones:startUpFireEffect', function(_NetID)
	local drone = nil

	for i=1, #RegisterDrone, 1 do
		if RegisterDrone[i].netID == _NetID then
			drone = RegisterDrone[i]			
			break
		end
	end

	if drone ~= nil then
		Citizen.CreateThread(function()
			drone.Broken = 1
			drone.CanCarryDrone = false
			StreamDataToClients(-1, RegisterDrone)
			TriggerClientEvent('drones:startFire', -1, _NetID)

			Citizen.Wait(Drone.Broken_Effect_Time)

			drone.CanCarryDrone = true
			StreamDataToClients(-1, RegisterDrone)
		end)
	end
end)

RegisterServerEvent('drones:syncWateredDrone')
AddEventHandler('drones:syncWateredDrone', function(_NetID)
	local drone = nil

	for i=1, #RegisterDrone, 1 do
		if RegisterDrone[i].netID == _NetID then
			drone = RegisterDrone[i]			
			break
		end
	end

	if drone ~= nil then
		Citizen.CreateThread(function()
			drone.Broken = 1
			StreamDataToClients(-1, RegisterDrone)
		end)
	end
end)

RegisterServerEvent('drones:registerDrone')
AddEventHandler('drones:registerDrone', function(drone)
	table.insert(RegisterDrone, drone)
	StreamDataToClients(-1, RegisterDrone)

	print('[XK3LY-DRONES] - Registred drone / OWNER: '..GetPlayerName(drone.owner))
end)

RegisterServerEvent('drones:deleteObjectFromTable')
AddEventHandler('drones:deleteObjectFromTable', function(_NetID)
	local drone = nil

	for i=1, #RegisterDrone, 1 do
		if RegisterDrone[i].netID == _NetID then
			drone = RegisterDrone[i]
			drone.tableID = i
			break
		end
	end

	if (drone ~= nil) then
		table.remove(RegisterDrone, drone.tableID)
		StreamDataToClients(-1, RegisterDrone)
	else
		print('[XK3LY-DRONES] - Couldnt find drone with NETID: '.._NetID)
	end
end)

AddEventHandler('playerDropped', function(reason)
	local _source = source
	RequestDeleteDroneAfterPlayerDisconnect(_source, RegisterDrone)
end)
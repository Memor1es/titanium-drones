local controllerProp = nil
SingalStatus = "<span style='color: #387a38;'>GOOD</span>"

SetupDroneObject = function(spawnCoords, ownerID)
    local self = {}

    self.Broken = 0

    self.object = CreateObject(GetHashKey('xs_prop_arena_drone_02'), spawnCoords.x, spawnCoords.y, spawnCoords.z, true, false, true)
    SetEntityCollision(self.object, true, true)
    SetEntityLights(self.object, false)
    SetEntityCanBeDamaged(self.object, true)
    SetEntityVisible(self.object, true)
    SetEntityHealth(self.object, 100)

    self.camera = CreateCam('DEFAULT_SCRIPTED_FLY_CAMERA', true)
    AttachCamToEntity(self.camera, self.object, 0.0, -0.100, -0.01, true)
    SetCamRot(self.camera, 0.0, 0.0, GetEntityRotation(self.object).z)
    SetCamNearClip(self.camera, 0.01)
    SetCamActive(self.camera, false)

    self.soundID = GetSoundId()
    PlaySoundFromEntity(soundID, "Armed", self.object, "GTAO_Speed_Race_Sounds", 0,0)

    self.hud = RequestScaleformMovie("drone_cam")
    while not HasScaleformMovieLoaded(self.hud) do Citizen.Wait(1) end
    
    self.CanCarryDrone = true

    self.netID = ObjToNet(self.object)
    SetNetworkIdExistsOnAllMachines(self.netID, true)
    NetworkSetNetworkIdDynamic(self.netID, true)
    SetNetworkIdCanMigrate(self.netID, false)

    self.SetAsBroken = function()
        if self.Broken == 0 then
            self.Broken = 1
            self.CanCarryDrone = false

            TriggerServerEvent('drones:startUpFireEffect', self.netID)

            Citizen.CreateThread(function()
                Citizen.Wait(Drone.Broken_Effect_Time)
                self.CanCarryDrone = true
            end)
        end
    end

    self.owner = ownerID

    return self
end

BrokeDrone = function(drone, particles)
    Citizen.CreateThread(function()

        if CurrentDrone ~= nil then
            if drone.object == CurrentDrone.object then
                drone = CurrentDrone
            end
        end

        drone.Broken = 1  
        
        SetEntityHealth(drone.object, 0)

        if particles == true then
            drone.CanCarryDrone = false
            TriggerServerEvent('drones:startUpFireEffect', drone.netID)
            Citizen.Wait(Drone.Broken_Effect_Time)
            drone.CanCarryDrone = true
        elseif particles == false then
            TriggerServerEvent('drones:syncWateredDrone', drone.netID)
        end
    end)
end

IsAnyControlInUsage = function()
    local Controls = { 'W', 'S', 'A', 'D', 'Q', 'E' }
    local found = false

    for i=1, #Controls, 1 do
        if IsControlPressed(0, Keys[Controls[i]]) then
            found = true
            break
        end
    end

    return found
end

UpdateObjectRotation = function(obj, cam)
    local current_rot_z = GetEntityRotation(obj).z
    current_rot_z = (GetCamRot(cam, 2).z + ((360.0-current_rot_z) * 0.005)-180.0)
    SetEntityRotation(obj, 0.0, 0.0, current_rot_z, 1, true)
end

CheckInputRotation = function(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX * -1.0 * (6.0) * (zoomvalue + 0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY * -1.0 * (6.0) * (zoomvalue + 0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

HandleZoom = function(cam)
	if IsControlJustPressed(0, 241) then
		fov = math.max(fov - 2.0, fov_min)
	end
	if IsControlJustPressed(0, 242) then
		fov = math.min(fov + 2.0, fov_max)
	end
	local current_fov = GetCamFov(cam)
	if math.abs(fov - current_fov) < 0.1 then
		fov = current_fov
	end
	SetCamFov(cam, current_fov + (fov - current_fov) * 0.05)
end

GetForwardVelocityVector = function(dir)
	local x = 0.0
	local y = 0.0
	local dir = dir
	if dir >= 0.0 and dir <= 90.0 then
		local factor = (dir/9.2) / 10
		x = -1.0 + factor
		y = 0.0 - factor
	end

	if dir > 90.0 and dir <= 180.0 then
		dirp = dir - 90.0
		local factor = (dirp/9.2) / 10
		x = 0.0 + factor
		y = -1.0 + factor
	end

	if dir > 180.0 and dir <= 270.0 then
		dirp = dir - 180.0
		local factor = (dirp/9.2) / 10
		x = 1.0 - factor
		y = 0.0 + factor
	end

	if dir > 270.0 and dir <= 360.0 then
		dirp = dir - 270.0
		local factor = (dirp/9.2) / 10
		x = 0.0 - factor
		y = 1.0 - factor
	end
	return x, y
end

speedFactor_forward = 0.0
speedFactor_backward = 0.0
speedFactor_up = 0.0
speedFactor_down = 0.0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if (CurrentDrone ~= nil) then
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) then
                if IsControlJustPressed(0, Keys["W"]) then
                    FreezeEntityPosition(CurrentDrone.object, false)
                    speedFactor_forward = 0.0
                end                  
                
                if IsControlPressed(0, Keys["W"]) then
                    if speedFactor_forward < Drone.Max_Speed then
                        speedFactor_forward = speedFactor_forward+0.4
                    end
                end
            end
        else
            Citizen.Wait(200)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if (CurrentDrone ~= nil) then
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) then
                if IsControlJustPressed(0, Keys["S"]) then
                    FreezeEntityPosition(CurrentDrone.object, false)
                    speedFactor_backward = 0.0
                end                  
                
                if IsControlPressed(0, Keys["S"]) then
                    if speedFactor_backward < Drone.Max_Speed then
                        speedFactor_backward = speedFactor_backward+0.4
                    else
                        speedFactor_backward = Drone.Max_Speed
                    end
                end
            end
        else
            Citizen.Wait(200)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if (CurrentDrone ~= nil) then
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) then
                if IsControlJustPressed(0, Keys["Q"]) then
                    FreezeEntityPosition(CurrentDrone.object, false)
                    speedFactor_up = 0.0
                end                  
                
                if IsControlPressed(0, Keys["Q"]) then
                    if speedFactor_up < Drone.Max_SpeedHeight then
                        speedFactor_up = speedFactor_up+0.1
                    else
                        speedFactor_up = Drone.Max_SpeedHeight
                    end
                end
            end
        else
            Citizen.Wait(200)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if (CurrentDrone ~= nil) then
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) then
                if IsControlJustPressed(0, Keys["E"]) then
                    FreezeEntityPosition(CurrentDrone.object, false)
                    speedFactor_down = 0.0
                end                  
                
                if IsControlPressed(0, Keys["E"]) then
                    if speedFactor_down < Drone.Max_SpeedHeight then
                        speedFactor_down = speedFactor_down+0.1
                    else
                        speedFactor_down = Drone.Max_SpeedHeight
                    end
                end
            end
        else
            Citizen.Wait(200)
        end
    end
end)

UseSelfDrone = function(id)
    local playerPedCoords = GetEntityCoords(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())

    local lib, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'

	RequestAnimDict(lib)

	while not HasAnimDictLoaded(lib) do
		RequestAnimDict(lib)
		Citizen.Wait(1)
	end

	TaskPlayAnim(GetPlayerPed(-1), lib, anim, 8.0, 8.0, 1500, 1, 1.0, false, false, false)
    Citizen.Wait(800)
    local x, y, z = table.unpack(playerPedCoords + (forward * 0.5))
    local drone = SetupDroneObject(vector3(x,y,z-1.05), id)
    TriggerServerEvent('drones:registerDrone', drone)
end

FindClosestDrone = function()
    local drone = nil

    for i=1, #CurrentDrones, 1 do
        local droneLoop = CurrentDrones[i]

        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(droneLoop.object), true) < 2.0 then
            if math.floor(GetEntityHeightAboveGround(droneLoop.object)*3.28) < 2 then
                drone = droneLoop
                break
            end
        end
    end

    return drone
end

ToggleDroneCam = function(bool)
    IsDroneControling = (bool or (not IsDroneControling))

    DoScreenFadeOut(500)

    while not IsScreenFadedOut() do
        Citizen.Wait(50)
    end

    if IsDroneControling then
        ESX.UI.Menu.CloseAll()
        DecorSetBool(CurrentDrone.object, Sync.CanCarry, false)
        SetCamActive(CurrentDrone.camera, true)
        SetFocusEntity(CurrentDrone.object)
        RenderScriptCams(true, false, 0, false, false)

        controllerProp = CreateObject(GetHashKey('xs_prop_arena_tablet_drone_01'), 1.0, 1.0, 1.0, 1, 1, 0)
        AttachEntityToEntity(controllerProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 0, 2, 1)
    

        Citizen.CreateThread(function()
            while IsDroneControling do
                Citizen.Wait(1)
                -- ANIM
                if IsEntityPlayingAnim(PlayerPedId(), 'anim@heists@prison_heistunfinished_biztarget_idle', 'target_idle', 3) ~= 1 then
                    ESX.Streaming.RequestAnimDict('anim@heists@prison_heistunfinished_biztarget_idle', function()
                        TaskPlayAnim(PlayerPedId(), 'anim@heists@prison_heistunfinished_biztarget_idle', 'target_idle', 8.0, -8, -1, 17, 0.0, false, false, false)
                    end)
                end
            end
        end)

        Citizen.CreateThread(function()
            while IsDroneControling do
                Citizen.Wait(50)

                --HUD UPDATE
                SendNUIMessage({
                    type = "updateHUD",
                    speed = math.floor(GetEntitySpeed(CurrentDrone.object)*3.6),
                    height = math.floor(GetEntityHeightAboveGround(CurrentDrone.object)*3.28),
                    signal = SingalStatus
                })
            end
        end)
    else
        SendNUIMessage({type = "closeHUD"})
        ESX.UI.Menu.CloseAll()

        SetCamActive(CurrentDrone.camera, false)
        DeleteObject(controllerProp)
        ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(CurrentDrone.object, false)
        SetFocusEntity(PlayerPedId())
        RenderScriptCams(false, false, 0, false, false)
        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)
        DecorSetBool(CurrentDrone.object, Sync.CanCarry, true)
    end

    Citizen.Wait(500)
    DoScreenFadeIn(200)
end

CorrectlyRemoveDrone = function(object)
    if DoesEntityExist(object) then
        DecorRemove(object, Sync.CanCarry)

		NetworkRequestControlOfEntity(object)
		while not NetworkHasControlOfEntity(object) do
			Citizen.Wait(1)
		end
		SetEntityCollision(object, false, false)
		SetEntityAlpha(object, 0.0, true)
		SetEntityAsMissionEntity(object, true, true)
		SetEntityAsNoLongerNeeded(object)
		DeleteObject(object)
	end
end

ShopMenu = function()
    ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'drone_shop', {
		title    = 'Drone Shop',
		align    = 'top-left',
		elements = {
            {label = "Kup drona <span style='color: green;'>500 000$</span>", value = 'buy'},
            {label = "Kup pilot do drona <span style='color: green;'>100 000$</span>", value = 'buy_pilot'},
            {label = "Napraw drona <span style='color: green;'>300 000$</span>", value = 'fix'}
        }
	}, function(data, menu)

		if data.current.value == 'buy' then
            TriggerServerEvent('drones:buyNewDrone')
        elseif data.current.value == 'buy_pilot' then
            TriggerServerEvent('drones:buyNewDronePilot')
		elseif data.current.value == 'fix' then
            TriggerServerEvent('drones:fixDrone')
		end

	end, function(data, menu)
		menu.close()
	end)
end

InitBlips = function()
    local blip = AddBlipForCoord(Shop.Pos)

	SetBlipSprite (blip, Shop.Sprite)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, Shop.Scale)
	SetBlipColour (blip, Shop.Colour)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(Shop.Label)
	EndTextCommandSetBlipName(blip)
end
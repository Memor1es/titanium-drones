ESX = nil

CurrentDrone = nil
CurrentDrones = {}

IsDroneControling = false
IsCamDisabled = false
BlockInput = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end

    RequestModel('xs_prop_arena_drone_02')
    RequestModel('xs_prop_arena_tablet_drone_01')

    InitBlips()
    InitShop()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        if (CurrentDrone ~= nil) then           
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) then
                if IsControlJustReleased(0, Keys["V"]) then 
                    ToggleDroneCam(false)
                end

                if BlockInput == false then
                    CheckInputRotation(CurrentDrone.camera, 1.0)
                    UpdateObjectRotation(CurrentDrone.object, CurrentDrone.camera)

                    SetEntityVelocity(CurrentDrone.object, GetEntityVelocity(CurrentDrone.object).x, GetEntityVelocity(CurrentDrone.object).y, 0.15)

                    if IsControlPressed(0, Keys["Q"]) then -- UP
                        SetEntityVelocity(CurrentDrone.object, GetEntityVelocity(CurrentDrone.object).x, GetEntityVelocity(CurrentDrone.object).y, speedFactor_up)
                    end
                    if IsControlPressed(0, Keys["E"]) then -- DOWN
                        SetEntityVelocity(CurrentDrone.object, GetEntityVelocity(CurrentDrone.object).x, GetEntityVelocity(CurrentDrone.object).y, (-speedFactor_down))
                    end   
                end          
            end
        else
            Citizen.Wait(500)
        end
    end
end)
-- SINGAL CONTROLLER
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300)
        if (CurrentDrone ~= nil) then 
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) then                      
                local jammer = exports.xk3ly_carsecurity:SearchForJammersNearCoords(GetCamCoord(CurrentDrone.camera))
                if (not (jammer == nil)) then	
                    SingalStatus = "<span style='color: #850f0f;'>LOST</span>" 		
					SetTimecycleModifier("Broken_camera_fuzz") 
                    SetTimecycleModifierStrength(2.0)
                    IsCamDisabled = true
                    BlockInput = true
                end
                
                if (CurrentDrone.Broken == 1) then	
                    SingalStatus = "<span style='color: #850f0f;'>LOST</span>" 		
					SetTimecycleModifier("Broken_camera_fuzz") 
                    SetTimecycleModifierStrength(2.0)
                    IsCamDisabled = true
                    BlockInput = true
			    end

                local vDist = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(CurrentDrone.object), true)            
                if vDist < Drone.Max_SingalRange then
                    if IsCamDisabled and (jammer == nil) and CurrentDrone.Broken ~= 1 then
                        SingalStatus = "<span style='color: #387a38;'>GOOD</span>"
                        SetTimecycleModifier("default")
                        SetTimecycleModifierStrength(0.3)
                        IsCamDisabled = false
                        BlockInput = false
                    end
                end
                
                if vDist > Drone.Max_SingalRange then
                    --if not IsCamDisabled then
                        SingalStatus = "<span style='color: #e3dc20;'>BAD</span>"
                        IsCamDisabled = true
                        SetTimecycleModifier("scanline_cam")   
                        SetTimecycleModifierStrength(1.8)                    
                    --end      

                    if vDist > Drone.Max_SingalRange+100.0 then
                        SingalStatus = "<span style='color: #f2961d;'>WORSE</span>"
                        SetTimecycleModifierStrength(2.5)
                    end
                    if vDist > Drone.Max_SingalRange+200.0 then  
                        SingalStatus = "<span style='color: #850f0f;'>LOST</span>"                     
                        SetTimecycleModifierStrength(3.8)
                        IsDroneControling = false
                        Citizen.Wait(1500)
                        
                        SetTimecycleModifier("Broken_camera_fuzz") 
                        SetTimecycleModifierStrength(2.0)

                        FreezeEntityPosition(CurrentDrone.object, false)
                        FreezeEntityPosition(PlayerPedId(), false)
                        SetFocusEntity(PlayerPedId())
                        RenderScriptCams(false, false, 0, false, false)
                        SetTimecycleModifier("default")
                        SetTimecycleModifierStrength(0.3)
                        SendNUIMessage({type = "closeHUD"})
                        ESX.ShowNotification('~b~Sygnał ~r~zerwany~b~!')
                    end
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if (#CurrentDrones ~= 0) then 
            local pId = GetPlayerServerId( NetworkGetPlayerIndexFromPed( GetPlayerPed(-1) ) )

            for i=1, #CurrentDrones, 1 do
                if CurrentDrones[i].owner == pId then
                    local drone = CurrentDrones[i]

                    if GetEntityHealth(drone.object) < 50.0 then
                        if drone.Broken == 0 then
                            BrokeDrone(drone, true)
                        end
                    end

                    if IsEntityInWater(drone.object) then
                        if drone.Broken == 0 then
                            BrokeDrone(drone, false)
                        end
                    end

                    Citizen.Wait(200)
                end
            end
        else
            Citizen.Wait(1000)
        end
    end
end)

-- CONTROLS
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if (CurrentDrone ~= nil) then
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) and BlockInput == false then
                if IsControlPressed(0, Keys["W"]) then
                    local forward = GetEntityForwardVector( CurrentDrone.object )
                    local current_velocity = GetEntityVelocity(CurrentDrone.object)

                    SetEntityVelocity(CurrentDrone.object, forward.x*(-speedFactor_forward), forward.y*(-speedFactor_forward), current_velocity.z+0.2)
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
            if IsDroneControling and DoesEntityExist(CurrentDrone.object) and BlockInput == false then
                if IsControlPressed(0, Keys["S"]) then -- BACKWARD
                    local forward = GetEntityForwardVector( CurrentDrone.object )
                    local current_velocity = GetEntityVelocity(CurrentDrone.object)

                    SetEntityVelocity(CurrentDrone.object, forward.x*(speedFactor_backward), forward.y*(speedFactor_backward), current_velocity.z+0.2)
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
        local droneObject = FindClosestDrone()

        if not (droneObject == nil) and not IsDroneControling then
            local canPickup = droneObject.CanCarryDrone

            if canPickup then
                ESX.ShowHelpNotification('Naciśnij ~INPUT_CONTEXT~ aby, podnieść drona.')

                if IsControlJustReleased(0, Keys["E"]) then
                    local lib, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
                    TaskPlayAnim(GetPlayerPed(-1), lib, anim, 8.0, 8.0, 1500, 1, 1.0, false, false, false)
                    Citizen.Wait(800)

                    ESX.TriggerServerCallback('drones:pickupDrone', function(callback)
                        if callback == true then
                            TriggerServerEvent('drones:deleteObjectFromTable', droneObject.netID)
                            CorrectlyRemoveDrone(droneObject.object)
                            CurrentDrone = nil
                            droneObject = nil
                        else
                            print('[XK3LY-DRONES] - Cant pickup drone!')
                        end
                    end, GetEntityHealth(droneObject.object))
                end
            else
                Citizen.Wait(250)
            end         
        else
            Citizen.Wait(500)
        end
    end
end)

InitShop = function()
    while true do
        Citizen.Wait(10)
        local coords = GetEntityCoords(PlayerPedId())
        local vRay = GetDistanceBetweenCoords(coords, Shop.Pos, true)

        if vRay < 5.0 then
            if vRay < 1.5 then
                ESX.ShowHelpNotification('Naciśnij ~INPUT_CONTEXT~ aby, skorzytać z sklepu.')

                if IsControlJustReleased(0, Keys["E"]) then
                    Citizen.Wait(10)
                    ShopMenu()
                    Citizen.WORSE(200)
                end
            end

            DrawMarker(1, Shop.Pos.x, Shop.Pos.y, Shop.Pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.2, 128, 128, 128, 200, false, true, 2, true, false, false, false)
        else
            Citizen.Wait(500)
        end
    end
end

RegisterNetEvent('drones:useDrone')
AddEventHandler('drones:useDrone', function(id)
    TriggerServerEvent('drones:deleteDroneFromEQ')
    UseSelfDrone(id) 
end)

RegisterNetEvent('drones:useDroneCam')
AddEventHandler('drones:useDroneCam', function()
    local pId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPlayerPed(-1)))
    local elements = {
        head = {'Dron', 'Status', 'Akcje'},
        rows = {}
    }

    local curId = 0

    for i=1, #CurrentDrones, 1 do
        if CurrentDrones[i].owner == pId then
            local status

            if CurrentDrones[i].Broken then
                status = '100%'
            else
                status = '0%'
            end
        
            curId = curId+1

            table.insert(elements.rows, {
                data = CurrentDrones[i],
                cols = {
                    ('Dron #'..curId),
                    status,
                    '{{' .. 'Przejmij kontrolę' .. '|requestsignal}}'
                }
            })
        end
    end

    ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'drones', elements, function(data, menu)
        if data.value == 'requestsignal' then
            menu.close()
            CurrentDrone = data.data          
            ToggleDroneCam(true)
        end
    end, function(data, menu)
        menu.close()
    end)
end)


RegisterNetEvent('drones:startFire')
AddEventHandler('drones:startFire', function(netID)
    local drone = NetworkGetEntityFromNetworkId(netID)

    if DoesEntityExist(drone) then
        if not HasNamedPtfxAssetLoaded("core") then
            RequestNamedPtfxAsset("core") 
            while not HasNamedPtfxAssetLoaded("core") do 
                Wait(1) 
            end 
        end 

        if CurrentDrone ~= nil then
            if drone == CurrentDrone.object then
                CurrentDrone.Broken = 1  
                SetEntityHealth(CurrentDrone.object, 0)
            end
        end

        SetPtfxAssetNextCall("core")   
        local particleFire = StartNetworkedParticleFxLoopedOnEntity("fire_wrecked_plane_cockpit", drone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, false, false, false)
        SetPtfxAssetNextCall("core") 
        local particleSmoke = StartNetworkedParticleFxLoopedOnEntity("ent_anim_cig_smoke", drone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 8.0, false, false, false)

        Citizen.CreateThread(function()
            Citizen.Wait(Drone.Broken_Effect_Time)
            StopParticleFxLooped(particleFire, 0)
            StopParticleFxLooped(particleSmoke, 0)
        end)
    end
end)

RegisterNetEvent('drones:updateDrones')
AddEventHandler('drones:updateDrones', function(drones)
    CurrentDrones = drones

    for i=1, #CurrentDrones, 1 do
        if not DoesEntityExist(CurrentDrones[i].object) then
            CurrentDrones[i].object = NetworkGetEntityFromNetworkId(CurrentDrones[i].netID)
        
            if DoesEntityExist(CurrentDrones[i].object) then
                print('[XK3LY-DRONES] - Reasigned object network handle to '..CurrentDrones[i].netID)
            end
        end
    end
end)

RegisterNetEvent('drones:deleteOldPlayerDrones')
AddEventHandler('drones:deleteOldPlayerDrones', function(owner)
    for i=1, #CurrentDrones, 1 do
        if CurrentDrones[i].owner == owner then
            local droneOwner = CurrentDrones[i]

            if DoesEntityExist(droneOwner.object) then
                TriggerServerEvent('drones:deleteObjectFromTable', droneOwner.netID)
                CorrectlyRemoveDrone(droneOwner.object)
                ReleaseSoundId(droneOwner.soundID)
            end
        end
    end   
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local pId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(GetPlayerPed(-1)))

        for i=1, #CurrentDrones, 1 do
            if CurrentDrones[i].owner == pId then
                if DoesEntityExist(CurrentDrones[i].object) then                   
                    CorrectlyRemoveDrone(CurrentDrones[i].object)
                    ReleaseSoundId(CurrentDrones[i].soundID)
                end
            end
        end
	end
end)
Data = {}
Data.Bombs = {}
Data.Funcs = {}
Data.Minutes = 5
Data.Aprox = 500.0
Data.tipoExplosion = 32
Data.numExplosivos = 5
Data.Exploded = false
Data.Phone = nil
Data.Desactivador = false


-- Core

ESX = nil

Citizen.CreateThread(function()
    while not ESX do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end
end)

-- Client

-- Client Functions

Data.Funcs.AnimDict = function(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        
        Citizen.Wait(1)
    end
end


-- Client Events

RegisterNetEvent('aday:openMenu')
AddEventHandler('aday:openMenu', function()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'open_menu', {
        title = 'Tiempo para explotar (segundos)'
    }, function(data, menu)
        local data = data.value

        if not data then
            menu.close()
        else
            local data2 = tonumber(data)
            TriggerServerEvent('aday:spawnBomb', tonumber(data2))
            menu.close()
        end

    end, function(data, menu)
        menu.close()
    end)
end)

RegisterNetEvent('aday:spawnBomb')
AddEventHandler('aday:spawnBomb', function(coords, timer)
    local ply = PlayerPedId()
    coordenadas = coords

    Data.Funcs.AnimDict('weapons@first_person@aim_rng@generic@projectile@sticky_bomb@')
    TaskPlayAnim(ply, 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor', 8.0, 1.0, 1000, 16, 0.0, false, false, false)
    Wait(1000)

    local coords1 = GetEntityCoords(PlayerPedId())
    local headingvector = GetEntityForwardVector(PlayerPedId())
    local x, y, z = table.unpack(coords1 + headingvector * 1.0)

    coords2 = {
        x = x,
        y = y,
        z = z - 1
    }

    ESX.Game.SpawnObject(1626933972, coords2, function(bag)
        FreezeEntityPosition(bag, true)
        SetEntityCollision(bag, false, true)
        PlaceObjectOnGroundProperly(bag)
        SetEntityAsMissionEntity(bag, false, true)
    end)

    local p = promise.new()

    ESX.TriggerServerCallback('aday:telefono', function(data) 
        Data.Phone = data
        p:resolve()
    end)
    Citizen.Await(p)

    Data.Exploded = false

    TriggerEvent('chat:addMessage', {
        color = { 255, 0, 0},
        multiline = true,
        args = {'BOMBA | ', 'Código Bomba : ' ..Data.Phone.. ''}
    })

    TriggerServerEvent('aday:explosion', timer, Data.Exploded)


end)

RegisterNetEvent('boom')
AddEventHandler('boom', function(coords, coords_x, coords_x2, Type2, explosive)
    AddExplosion(coords.x,coords.y,coords.z,Type2,40.0,true,false,0.2)
    local i = 0
    repeat
        i = i + 1    
        coords_x = coords_x + 1
        coords_x2 = coords_x2 - 1
        AddExplosion(coords_x,coords.y,coords.z,Type2,40.0,true,false,0.2)
        AddExplosion(coords_x2,coords.y,coords.z,Type2,40.0,true,false,0.2)
        Citizen.Wait(200)
    until( i == explosive)
    local bag = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, GetHashKey('prop_cs_heist_bag_02'), false, false, false)
    DeleteObject(bag)
end)

RegisterNetEvent('desactivador')
AddEventHandler('desactivador', function()
    Data.Desactivador = true
end)


function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
                    
        Citizen.Wait(1)
     end
end

RegisterNetEvent('aday:eliminarObj')
AddEventHandler('aday:eliminarObj', function(obj)
    if Data.Desactivador == true then
        local playerPed = PlayerPedId()

        local position = GetEntityCoords(playerPed, false)

        local object = GetClosestObjectOfType(position.x, position.y, position.z, 1.0, GetHashKey(obj), false, false, false)

        local controlTick = GetGameTimer()

        while (GetGameTimer() <= controlTick + 15 and not NetworkHasControlOfEntity(object)) do
                NetworkRequestControlOfEntity(object)
                Citizen.Wait(0)
        end

        local deleteTick = GetGameTimer()
        while (GetGameTimer() <= deleteTick + 15 and DoesEntityExist(object)) do
            Data.Funcs.AnimDict('weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor')
            TaskPlayAnim(playerPed, 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor', 8.0, 1.0, 1000, 16, 0.0, false, false, false)
            Citizen.Wait(1000)


            SetEntityAsMissionEntity(object, true, true)
            DeleteObject(object)
            SetEntityAsNoLongerNeeded(object)
            TriggerServerEvent('aday:bombaDesarmada')
            Data.Desactivador = false
        end
    end
end)

RegisterClientCallback('close', function()
    local localPed = GetPlayerPed(source)

    local position = GetEntityCoords(localPed, false)

    local object = GetClosestObjectOfType(position.x, position.y, position.z, 1.0, GetHashKey('prop_cs_heist_bag_02'), false, false, false)

    local distance = #(GetEntityCoords(localPed) - GetEntityCoords(object))

    if distance < 3 then
        return true
    else
        return false
    end
end)

RegisterNetEvent('notificacion')
AddEventHandler('notificacion', function(valor) 
    ESX.ShowNotification(valor)
end)

function GetVecDist(v1,v2)
    if not v1 or not v2 or not v1.x or not v2.x then return 0; end
    return math.sqrt(  ( (v1.x or 0) - (v2.x or 0) )*(  (v1.x or 0) - (v2.x or 0) )+( (v1.y or 0) - (v2.y or 0) )*( (v1.y or 0) - (v2.y or 0) )+( (v1.z or 0) - (v2.z or 0) )*( (v1.z or 0) - (v2.z or 0) )  )
end

RegisterNetEvent('explosion')
AddEventHandler('explosion', function() 
    local radio = Data.Aprox
    if GetVecDist(GetEntityCoords(GetPlayerPed(-1)),coords2) < radio then
        AddExplosion(coords2.x,coords2.y,coords2.z,Data.tipoExplosion,40.0,true,false,0.2)       
        local i = 0
        local coords_x = coords2.x
        local coords_x2 = coords2.x
        repeat
            i = i + 1    
            coords_x = coords_x + 1
            coords_x2 = coords_x2 - 1
            AddExplosion(coords_x,coords2.y,coords2.z,Data.tipoExplosion,40.0,true,false,0.2)
            AddExplosion(coords_x2,coords2.y,coords2.z,Data.tipoExplosion,40.0,true,false,0.2)
            local bag = GetClosestObjectOfType(coords2.x, coords2.y, coords2.z, 3.0, GetHashKey('prop_cs_heist_bag_02'), false, false, false)
            DeleteObject(bag)
            Citizen.Wait(200)
        until( i == Data.numExplosivos)
    else
        ESX.ShowNotification('Acercate más')
    end
end)

-- Threads

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/detonar',  "Detonar bomba",  {{name = "Codigo de bomba", help = "Codigo de bomba"}})
end)
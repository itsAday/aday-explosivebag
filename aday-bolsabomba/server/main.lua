Data = {}
Data.Minutes = 5
Data.Explosives = 5
Data.Type = 32

habilited = false -- Habilited, palabra inventada por el señor snaildev#5452 el 18 de Junio del 2021 para saber si la bomba está deshabilitada o habilitada dependiendo de su correspondiente estado (Desactivada o activada)
enCurso = false -- Saber si hay una bomba en el servidor en curso.
explotao = nil  -- Verificar si la bomba ha explotado o no en general.
yaExplo = nil -- Usada para verificar si el comando de detonación ha sido utilizado o no
-- Core

ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) 
    ESX = obj 
end)

-- Server

-- Server Events

RegisterServerEvent('aday:spawnBomb') --Proceso de spawneo de bomba
AddEventHandler('aday:spawnBomb', function(timer)
    local src = source

    if enCurso == false then
        if timer > Data.Minutes then
            pedCoords = GetEntityCoords(GetPlayerPed(src))
            --print(pedCoords)
            TriggerClientEvent('aday:spawnBomb', src, GetEntityCoords(GetPlayerPed(src)), timer)
            yaExplo = false
        end
    else
        local noti = "Ya hay una bomba en curso."
        TriggerClientEvent('notificacion', src, noti)
    end
end)


RegisterServerEvent('aday:explosion') -- Proceso de explosion.
AddEventHandler('aday:explosion', function(timer, exploted)
    local src = source

    coords = GetEntityCoords(GetPlayerPed(src))
    enCurso = true
    habilited = true
    explotao = false

    print("El jugador con ID: " ..source.. " ha puesto una bomba.")

    while (timer ~= 0) and explotao == false do
        if habilited and not exploted then
            Wait(1000)
            local valor = "Tiempo para explosión: " ..timer.. "" 
            TriggerClientEvent('notificacion', src, valor)
            timer = timer - 1
        else
            break
        end
    end

    if explotao == true or explotao == nil then
        print("La bomba ha explotao")
    else
        print("Timer terminado")

        if habilited == true then
            coords_x = coords.x
            coords_x2 = coords.x
            --print(coords, coords_x, coords_x2, Type2, explosive)
            TriggerClientEvent('boom', src, coords, coords_x, coords_x2, Data.Type, Data.Explosives)
            enCurso = false
        else
            local valor = "Bomba desactivada"
            TriggerClientEvent('notificacion', src, valor)
            print('Bomba desactivada')
            enCurso = false
        end
    end
end)

-- Server ESX Functions

ESX.RegisterUsableItem('bolsa_bomba', function(source) --Registra la bolsa como item usable
    local src = source
    local ply = ESX.GetPlayerFromId(src)

    if ply then
        ply.removeInventoryItem('bolsa_bomba', 1)
        ply.triggerEvent('aday:openMenu', src)
    end
end)

RegisterCommand('detonar', function(source, args, rawCommand) -- Comando de detonar
    local id = args[1]
    if enCurso == true and yaExplo == false then -- Asegurarse que estos pardillos del server no utilizen bugs para aprovecharse de los posibles fallos del script. Esto impide que el jugador pueda explotar con el comando de detonar cuando la bomba ya ha sido explotada o detonada y que, cuando el comando ya haya sido utilizado, no se pueda volver a utilizar con la misma bomba para detonar 2 veces.
        TriggerEvent('aday:detonar', id)  
        if seg_codigo == Data.Phone then -- Asegurarse que el código de la bomba esta bien introducido antes de activar las prevenciones.
            explotao = true -- Prevenciones
            yaExplo = true
            enCurso = false
            local valor = "BOOM! La has detonado pillin" 
            TriggerClientEvent('notificacion', source, valor)
        else
            local malEscrito = "El Código introducido es invalido"
            TriggerClientEvent('notificacion', source, malEscrito)
        end
    else
        local yaDesactivada = "La bomba ya ha sido desactivada o ya ha explotado. Casi cuela :)"
        TriggerClientEvent('notificacion', source, yaDesactivada)
    end
end, false)

ESX.RegisterUsableItem('desactivador', function(source) -- Reune los dos eventos para desactivar. Este es el proceso de desactivacion completo.
    local src = source
    local ply = ESX.GetPlayerFromId(src)
    if ply then
        if TriggerClientCallback(source, 'close') then
            TriggerClientEvent('desactivador', src)
            TriggerEvent('aday:eliminarBolsa', 'prop_cs_heist_bag_02')
        end
    end
end)

RegisterServerEvent('aday:eliminarBolsa') -- Proceso de desactivacion de la bomba eliminando el objeto. Permite a otros usuarios desactivar la bomba de otros jugadores. 
AddEventHandler('aday:eliminarBolsa', function(obj) 
    if obj ~= 'prop_cs_heist_bag_02' then return end 
    TriggerClientEvent('aday:eliminarObj', -1, obj) 
end)

RegisterServerEvent('aday:bombaDesarmada') -- Proceso de desarmar bomba
AddEventHandler('aday:bombaDesarmada', function()
    local src = source
    local ply = ESX.GetPlayerFromId(src)
    if ply then
        habilited = false
        enCurso = false
        ply.removeInventoryItem('desactivador', 1)
    end
end)

ESX.RegisterServerCallback("aday:telefono", function(source, cb, target, data) -- Crear "numero de telefono" para detonar. Numero automaticamente generado por la bomba y único para cada caso.
    Data.Phone = math.random(111111,999999)
    cb(Data.Phone)
end)

RegisterServerEvent('aday:detonar') -- Proceso de detonación por server-side para que otros jugadores puedan detonar la bomba si tienen el codigo.
AddEventHandler('aday:detonar', function(codigo)
    codigo = tonumber(codigo)
    seg_codigo = codigo
    if codigo == Data.Phone then
        TriggerClientEvent('explosion', -1)
    else
        local valor = "Codigo Erroneo" 
        TriggerClientEvent('notificacion', source, valor)
    end
end)
local QBCore = exports['qb-core']:GetCoreObject()

local function DispatchAlert()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1name = GetStreetNameFromHashKey(street1)
    local street2name = GetStreetNameFromHashKey(street2)

    local alert = {
        message = 'Parking Meter Tampering',
        code = '10-54',
        sprite = 162,
        priority = 3,
        coords = coords,
        street = street1name .. ', ' .. street2name,
        radius = 30,
        color = 1,
        scale = 1.0,
        length = 2
    }

    exports['ps-dispatch']:CustomAlert(alert)
end

local function SmashMeter(data)
    local ped = PlayerPedId()
    local entity = data.entity
    local entityCoords = GetEntityCoords(entity)

    if Config.RequiredPolice > 0 then
        local policeCount = lib.callback.await('rogue-MeterRobbery:server:PoliceCheck', false)
        if policeCount < Config.RequiredPolice then
            return lib.notify({description = 'Not enough police on duty', type = 'error'})
        end
    end

    local hasCooldown = lib.callback.await('rogue-MeterRobbery:server:CoolDown', 1000, true, entityCoords)
    if not hasCooldown then
        RequestAnimDict('melee@large_wpn@streamed_core')
        while not HasAnimDictLoaded('melee@large_wpn@streamed_core') do Wait(1) end

        TaskTurnPedToFaceEntity(ped, entity, -1)

        local start = GetGameTimer()
        while not IsPedFacingPed(ped, entity, 20.0) do
            if GetGameTimer() - start > 1500 then break end
            Wait(10)
        end

        ClearPedTasksImmediately(ped)
        TaskPlayAnim(ped, 'melee@large_wpn@streamed_core', 'ground_attack_on_spot', 8.0, -8.0, 1500, 1, 0, false, false, false)
        
        Wait(500)

        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10, 'coins', 0.5)

        Wait(500)

        local chance = math.random()
        if chance <= Config.AlertChance then
            DispatchAlert()
        end

        lib.callback.await('rogue-MeterRobbery:server:Reward', 10000, entityCoords)
        else
        return lib.notify({description = 'Your to tired, try again later', type = 'error'})
    end
end

local function CreateTargets()
    exports.ox_target:addModel(Config.MeterModels, {
        {
            name = 'parking_meter_robbery_target',
            icon = 'fa-solid fa-hand-fist',
            label = 'Smash',
            onSelect = function(data)
                local entityCoords = GetEntityCoords(data.entity)
                local locked = lib.callback.await('rogue-MeterRobbery:server:CoolDown', false, false, entityCoords, true)
                if locked == 'locked' then
                    return lib.notify({description = 'This meter looks broken', type = 'error'})
                end
                SmashMeter(data)
            end,
            canInteract = function()
                local ped = PlayerPedId()
                local weaponHash = GetSelectedPedWeapon(ped)

                for _, v in pairs(Config.SmashItems) do
                    if weaponHash == GetHashKey(v) then
                        return true
                    end
                end
                return false
            end,
            distance = 1,
        }
    })
end

RegisterNetEvent('rogue-MeterRobbery:client:PedReact', function(coords)
    local peds = GetGamePool('CPed')
    for _, ped in pairs(peds) do
        if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) and not IsPedInAnyVehicle(ped, false) then
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - coords) < 15.0 then
                PlayPedAmbientSpeechNative(ped, 'GENERIC_FRIGHTENED_HIGH', 'SPEECH_PARAMS_FORCE_SHOUTED')
                TaskSmartFleeCoord(ped ,coords.x, coords.y, coords.z, 100.0, -1, false, false)

                Citizen.SetTimeout(15000, function()
                    if DoesEntityExist(ped) then
                        ClearPedTasks(ped)
                    end
                end)
            end
        end
    end
end)

Citizen.CreateThread(function()
    CreateTargets()
end)
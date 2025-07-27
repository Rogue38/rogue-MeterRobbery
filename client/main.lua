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

    exports["ps-dispatch"]:CustomAlert(alert)
end

local function SmashMeter(data)
    local ped = PlayerPedId()
    local entity = data.entity

    if Config.RequiredPolice > 0 then
        local policeCount = lib.callback.await('rogue-MeterRobbery:server:PoliceCheck', false)
        dbug('Police Count:', policeCount)
        if policeCount < Config.RequiredPolice then
            return lib.notify({description = 'Not enough police on duty', type = 'error'})
        end
    end
    local hasCooldown = lib.callback.await('rogue-MeterRobbery:server:CoolDown', false)

    if not hasCooldown then
        RequestAnimDict("melee@large_wpn@streamed_core")
        while not HasAnimDictLoaded("melee@large_wpn@streamed_core") do Wait(1) end

        TaskTurnPedToFaceEntity(ped, entity, -1)

        local start = GetGameTimer()
        while not IsPedFacingPed(ped, entity, 20.0) do
            if GetGameTimer() - start > 1500 then break end
            Wait(10)
        end

        ClearPedTasksImmediately(ped)
        TaskPlayAnim(ped, "melee@large_wpn@streamed_core", "ground_attack_on_spot", 8.0, -8.0, 1500, 1, 0, false, false, false)
        
        Wait(1000)
        local entityCoords = GetEntityCoords(entity)
        lib.callback.await('rogue-MeterRobbery:server:Reward', 10000, entityCoords)
        DispatchAlert()
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

Citizen.CreateThread(function()
    CreateTargets()
end)
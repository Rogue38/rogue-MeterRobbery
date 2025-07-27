local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}
local robbedMeters = {}

local function getPlayer(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    return player
end

local function policeCheck()
    local policeCount = 0
    local Players = QBCore.Functions.GetPlayers()

    for i = 1, #Players do
        local player = getPlayer(Players[i])
        if player and player.PlayerData.job and Config.PoliceJobs[player.PlayerData.job.name] and player.PlayerData.job.onduty then
            policeCount = policeCount + 1
        end
    end
    return policeCount
end

local function CoolDown(src, start, coords, checkCoords)
    local player = getPlayer(src)
    if not player then return false end

    local citizenId = player.PlayerData.citizenid
    local currentTime = os.time()
    local lastData = cooldowns[citizenId] or { time = 0, coords = nil }
    local coolDownTime = Config.Cooldown * 60

    if not start and coords and checkCoords then
        if Config.PersistentMeters then
            for _, v in ipairs(robbedMeters) do
                if #(v - coords) < 1.0 then
                    return 'locked'
                end
            end
        else
            for x, data in pairs(cooldowns) do
                if data.coords and #(data.coords - coords) < 1.0 then
                    if currentTime - data.time >= coolDownTime then
                        cooldowns[x] = nil
                        return false
                    end
                    return 'locked'
                end
            end
        end
    end

    if currentTime - lastData.time >= coolDownTime then
        if start then
            cooldowns[citizenId] = {time = currentTime, coords = coords}
            if Config.PersistentMeters then
                table.insert(robbedMeters, coords)
            end
        end
        return false
    else
        return true
    end
end

lib.callback.register('rogue-MeterRobbery:server:PoliceCheck', function()
    return policeCheck()
end)

lib.callback.register('rogue-MeterRobbery:server:CoolDown', function(src, start, coords, checkCoords)
    return CoolDown(src, start, coords, checkCoords)
end)

lib.callback.register('rogue-MeterRobbery:server:Reward', function(src, entityCoords)
    local player = getPlayer(src)
    if not player then return false end

    local ped = GetPlayerPed(src)
    local pedCoords = GetEntityCoords(ped)
    local dist = #(pedCoords - vector3(entityCoords.x, entityCoords.y, entityCoords.z))

    if dist > 5.0 then
        return false
    end
    TriggerClientEvent('rogue-MeterRobbery:client:PedReact', -1, entityCoords)

    local weapon = exports.ox_inventory:GetCurrentWeapon(src)
    if weapon then
        local durability = weapon.metadata and weapon.metadata.durability or 100
        local newDurability = math.max(durability - Config.DurabilityDrain, 0)
    
        exports.ox_inventory:SetDurability(src, weapon.slot, newDurability)
    end
    local rewardAmount = math.random(Config.MinReward,Config.MaxReward)
    if exports.ox_inventory:CanCarryItem(src, Config.Money, rewardAmount) then
        exports.ox_inventory:AddItem(src, Config.Money, rewardAmount)
    else
        exports.ox_inventory:CustomDrop('Dropped Items', { { Config.Money, rewardAmount } }, pedCoords)
    end
end)
local QBCore = exports['qb-core']:GetCoreObject()
local cooldowns = {}

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
end

lib.callback.register('rogue-MeterRobbery:server:PoliceCheck', function()
    return policeCheck()
end)

lib.callback.register('rogue-MeterRobbery:server:CoolDown', function(src)
    local player = getPlayer(src)
    if not player then return false end

    local citizenId = player.PlayerData.citizenid
    local currentTime = os.time()

    local lastTime = cooldowns[citizenId] or 0
    local coolDownTime = Config.Cooldown * 60

    if currentTime - lastTime >= coolDownTime then
        cooldowns[citizenId] = currentTime
        return false
    else
        return true
    end
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

    local weapon = exports.ox_inventory:GetCurrentWeapon(src)
    if weapon then
        local durability = weapon.metadata and weapon.metadata.durability or 100
        local newDurability = math.max(durability - 3, 0)
    
        exports.ox_inventory:SetDurability(src, weapon.slot, newDurability)
    end
    local rewardAmount = math.random(Config.MinReward,Config.MaxReward)
    if exports.ox_inventory:CanCarryItem(src, Config.Money, rewardAmount) then
        exports.ox_inventory:AddItem(src, Config.Money, rewardAmount)
    else
        exports.ox_inventory:CustomDrop('Dropped Items', { { Config.Money, rewardAmount } }, pedCoords)
    end
end)
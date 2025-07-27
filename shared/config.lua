Config = {}

Config.Debug = false

Config.Money = 'money_folded' --item for reward
Config.MinReward = 1
Config.MaxReward = 3

Config.Cooldown = 5 --in minutes
Config.PersistentMeters = true --stores robbed meters untill server restart

Config.RequiredPolice = 1
Config.AlertChance = 0.75
Config.PoliceJobs = {
    ['police'] = true,
    ['bcso'] = true,
    ['pbso'] = true,
    ['sasm'] = true,
    ['sasp'] = true,
}

Config.MeterModels = {
    `prop_parknmeter_01`,
    `prop_parknmeter_02`,
}

Config.DurabilityDrain = 3
Config.SmashItems = {
    'WEAPON_BAT',
}

function dbug(...)
    if Config.Debug then print('^3[DEBUG]^7', ...) end
end
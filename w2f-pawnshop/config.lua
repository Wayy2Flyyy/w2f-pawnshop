Config = {}

Config.Debug = false
Config.InteractionDistance = 2.5
Config.MinimumProfitMargin = 75

Config.AllowViewingOutOfStock = true
Config.DefaultBuyAccount = 'money'
Config.DefaultSellAccount = 'money'
Config.SellPaymentAccount = Config.DefaultSellAccount

Config.MaxSellPerAction = 50
Config.CartMaxPerCheckout = 25
Config.ItemImagePath = 'nui://ox_inventory/web/images/%s.png'

--- Hide buy items the player cannot purchase (loyalty / category). If false, show as locked.
Config.HideLockedItems = false

--- Max low-stock items mentioned in NPC greeting.
Config.DemandedItemLimit = 2

Config.Loyalty = {
    enabled = true,
    --- Multipliers applied to catalog loyaltyXp on buys/sells.
    XPSellMultiplier = 1.0,
    XPBuyMultiplier = 1.0,
    --- Extra XP per $100 of sell payout (higher value = more XP).
    XPPerHundredSold = 2,
}

Config.LowStock = {
    --- Stock at or below this count is "demanded".
    threshold = 3,
    --- Extra sell price bonus percent when demanded.
    sellBonusPercent = 15,
    --- Multiplier on loyalty XP when selling demanded items.
    xpBonusMultiplier = 1.5,
}

Config.Ped = {
    model = 's_m_y_shopkeep_01',
    coords = vector4(182.93, -1319.09, 29.32, 320.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    blip = false,
}

Config.Dialog = {
    ownerName = 'Vincent',
}

Config.Framework = nil

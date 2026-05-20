Config = {}

--- Print debug messages to client/server console when true.
Config.Debug = false

--- Distance (meters) for ox_target interaction with the pawnshop owner.
Config.InteractionDistance = 2.5

--- Minimum profit margin (pawnshop buy price minus sell payout must exceed this).
Config.MinimumProfitMargin = 75

--- Account used when paying the player for sold items ('cash', 'bank', etc.).
Config.SellPaymentAccount = 'cash'

--- Hard cap per sell action (exploit protection).
Config.MaxSellPerAction = 50

--- ox_inventory image URL pattern (%s = item name).
Config.ItemImagePath = 'nui://ox_inventory/web/images/%s.png'

--- Pawnshop owner NPC settings.
Config.Ped = {
    model = 's_m_y_shopkeep_01',
    coords = vector4(182.93, -1319.09, 29.32, 320.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    blip = false,
}

--- NUI dialog copy.
Config.Dialog = {
    ownerName = 'Vincent',
    greeting = 'Evening. Got something to move, or looking to pick something up?',
    placeholders = {
        buy = 'Browse what\'s on the shelf once stock is wired up.',
        stock = 'Inventory ledger isn\'t hooked up yet. Check back shortly.',
    },
}

--- Framework auto-detect: 'qbox' | 'esx' | nil.
Config.Framework = nil

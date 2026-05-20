Config = {}

Config.Debug = false
Config.InteractionDistance = 2.5

--- Minimum profit margin between pawnshop buy and sell prices.
Config.MinimumProfitMargin = 75

--- Show out-of-stock items in view-only storefront mode.
Config.AllowViewingOutOfStock = true

--- Framework money accounts (ESX often uses "money"; Qbox maps to cash in bridge).
Config.DefaultBuyAccount = 'money'
Config.DefaultSellAccount = 'money'

--- Legacy alias for sell payouts.
Config.SellPaymentAccount = Config.DefaultSellAccount

Config.MaxSellPerAction = 50

--- Max total item quantity per checkout (sum of all cart line quantities).
Config.CartMaxPerCheckout = 25

Config.ItemImagePath = 'nui://ox_inventory/web/images/%s.png'

Config.Ped = {
    model = 's_m_y_shopkeep_01',
    coords = vector4(182.93, -1319.09, 29.32, 320.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    blip = false,
}

Config.Dialog = {
    ownerName = 'Vincent',
    greeting = 'Evening. Got something to move, or looking to pick something up?',
}

Config.Framework = nil

--[[
    w2f-pawnshop — Configuration
    Realistic NPC pawnshop with player-driven stock, loyalty, and black market.

    Dependencies (start before this resource):
    - ox_lib, ox_target, ox_inventory, oxmysql
    - es_extended or qbx_core / qb-core for payouts

    SQL: run sql/install.sql once, or let Database.Init apply on resource start.
]]

Config = {}

--- When true, prints tagged debug lines via Dbg.Print (shared/debug.lua).
Config.Debug = false

--- ox_target interaction distance (meters) for both peds.
Config.InteractionDistance = 2.5

--- Pawnshop must keep at least this gap between what it pays (sell) and charges (buy).
Config.MinimumProfitMargin = 75

--- Show zero-stock catalog rows in buy/view storefronts (out of stock, not hidden).
Config.AllowViewingOutOfStock = true

--- Money accounts (ESX: "money"; Qbox bridge maps to cash).
Config.DefaultBuyAccount = 'money'
Config.DefaultSellAccount = 'money'
Config.SellPaymentAccount = Config.DefaultSellAccount

--- Max units per single sell action.
Config.MaxSellPerAction = 50

--- Max total quantity per checkout (pawnshop or black market cart).
Config.CartMaxPerCheckout = 25

--- ox_inventory image URL; %s = item image name.
Config.ItemImagePath = 'nui://ox_inventory/web/images/%s.png'

--- Hide locked buy rows instead of showing them disabled.
Config.HideLockedItems = false

--- Max low-stock item names appended to owner greeting.
Config.DemandedItemLimit = 2

--- Force ESX / Qbox / auto-detect (nil = auto).
Config.Framework = Config.Framework or 'auto'

Config.Loyalty = {
    enabled = true,
    XPSellMultiplier = 1.0,
    XPBuyMultiplier = 1.0,
    XPPerHundredSold = 2,
}

Config.LowStock = {
    threshold = 3,
    sellBonusPercent = 15,
    xpBonusMultiplier = 1.5,
}

--- Main pawnshop owner NPC.
Config.Ped = {
    model = 'mp_m_shopkeep_01',
    coords = vector4(182.93, -1319.09, 29.32, 320.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    blip = {
        enabled = true,
        sprite = 431,
        scale = 0.8,
        colour = 5,
        label = 'Pawn Shop',
    },
}

Config.Dialog = {
    ownerName = 'Vincent',
}

--- Black market dealer (loyalty level 4+).
Config.BlackMarket = {
    --- Minimum pawnshop loyalty level to see/use black market.
    minAccessLevel = 4,

    --- Hide ox_target on dealer when player is below minAccessLevel.
    hideTargetBelowLevel = false,

    --- List black market items with 0 stock (browse only).
    showOutOfStock = false,

    --- Hide items above player's loyalty tier.
    hideLockedItems = false,

    --- Shown after choosing "Black Market Contact" at the pawnshop.
    contactMessage = 'There is a fixer near the old storage yard south of the city. He only deals with people I vouch for. Do not mention my name loudly.',

    --- Shown when player lacks access at the dealer.
    rejectionMessage = 'You are not known here. Come back when Vincent trusts you.',

    --- Dealer NPC.
    Ped = {
        model = 's_m_m_highsec_01',
        coords = vector4(-130.9096, -1416.8578, 31.3003, 204.3312),
        scenario = 'WORLD_HUMAN_SMOKING',
        blip = false,
    },

    dealerName = 'Silas',
    greeting = 'Keep your voice down. What do you need?',
}

_G.Config = Config

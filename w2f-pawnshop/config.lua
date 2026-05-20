Config = {}

--- Print debug messages to client/server console when true.
Config.Debug = false

--- Distance (meters) for ox_target interaction with the pawnshop owner.
Config.InteractionDistance = 2.5

--- Pawnshop owner NPC settings (Stage 1: single location).
Config.Ped = {
    --- Ped model name or hash string (e.g. 's_m_y_shopkeep_01').
    model = 's_m_y_shopkeep_01',

    --- World position and heading (vector4: x, y, z, w).
    coords = vector4(182.93, -1319.09, 29.32, 320.0),

    --- Scenario played while idle; set to false or '' to disable.
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',

    --- Blip optional (disabled in Stage 1).
    blip = false,
}

--- NUI dialog copy (customize per server).
Config.Dialog = {
    ownerName = 'Vincent',
    greeting = 'Evening. Got something to move, or looking to pick something up?',
    placeholders = {
        sell = 'Bring your items to the counter — we\'ll appraise them soon.',
        buy = 'Browse what\'s on the shelf once stock is wired up.',
        stock = 'Inventory ledger isn\'t hooked up yet. Check back shortly.',
    },
}

--- Framework auto-detect order: 'qbox' | 'esx' | nil (standalone).
--- Leave nil to auto-detect; set manually to force a bridge.
Config.Framework = nil

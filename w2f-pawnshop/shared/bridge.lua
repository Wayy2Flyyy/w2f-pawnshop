---@class Bridge
Bridge = {
    name = 'standalone',
    ready = false,
}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][bridge] %s'):format(table.concat({ ... }, ' ')))
end

--- Detect ESX / Qbox from running resources.
local function detectFramework()
    if Config.Framework == 'esx' or Config.Framework == 'qbox' then
        return Config.Framework
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbox'
    end

    if GetResourceState('qb-core') == 'started' then
        return 'qbox'
    end

    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    return 'standalone'
end

--- Initialize framework bridge (server/client safe).
function Bridge.Init()
    if Bridge.ready then return Bridge.name end

    Bridge.name = detectFramework()
    Bridge.ready = true

    debugPrint('Framework:', Bridge.name)
    return Bridge.name
end

--- Returns true when a supported roleplay framework is active.
function Bridge.IsFramework()
    Bridge.Init()
    return Bridge.name == 'esx' or Bridge.name == 'qbox'
end

--- Placeholder: resolve local player server id (client) or source helpers (server).
--- Expanded in later stages for payouts and inventory checks.
function Bridge.GetPlayerId(source)
    if IsDuplicityVersion() then
        return source
    end
    return cache and cache.playerId or PlayerId()
end

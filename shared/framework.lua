W2F = W2F or {}
W2F.Framework = W2F.Framework or {}

local Framework = W2F.Framework

Framework.name = Framework.name or 'standalone'
Framework.ready = Framework.ready or false

local function detect()
    local configured = Config and Config.Framework or 'auto'
    if configured and configured ~= 'auto' then
        return configured
    end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    if GetResourceState('qb-core') == 'started' then return 'qbcore' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    return 'standalone'
end

function Framework.Detect()
    if Framework.ready then return Framework.name end
    Framework.name = detect()
    Framework.ready = true
    if Framework.name == 'standalone' then
        print('^1[w2f-pawnshop] No supported framework detected (qbx_core/qb-core/es_extended).^0')
    end
    return Framework.name
end

function Framework.GetName() return Framework.Detect() end
function Framework.IsQbox() return Framework.GetName() == 'qbox' end
function Framework.IsQBCore() return Framework.GetName() == 'qbcore' end
function Framework.IsESX() return Framework.GetName() == 'esx' end
function Framework.IsQBFamily() local n=Framework.GetName(); return n=='qbox' or n=='qbcore' end

Bridge = Bridge or {}
function Bridge.Init() return Framework.Detect() end
function Bridge.IsFramework() return Framework.IsQBFamily() or Framework.IsESX() end
function Bridge.GetPlayerId(source)
    if IsDuplicityVersion() then return source end
    return cache and cache.playerId or PlayerId()
end

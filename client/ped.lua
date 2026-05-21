_G.PedUtils = _G.PedUtils or {}
local PedUtils = _G.PedUtils

local blips = {}

local function logSpawn(message, ...)
    print(('[w2f-pawnshop][ped] %s'):format(message:format(...)))
end

function PedUtils.LoadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model

    if not IsModelValid(hash) and not IsModelInCdimage(hash) then
        logSpawn('Invalid ped model: %s (%s)', tostring(model), tostring(hash))
        return nil
    end

    local libRef = _G.lib or (GetResourceState('ox_lib') == 'started' and exports.ox_lib)
    if libRef and libRef.requestModel then
        local ok, loaded = pcall(function()
            return libRef.requestModel(hash, 10000)
        end)
        if ok and loaded then
            return hash
        end
    end

    RequestModel(hash)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do
        Wait(0)
    end

    if not HasModelLoaded(hash) then
        logSpawn('Timed out loading model: %s (%s)', tostring(model), tostring(hash))
        return nil
    end

    return hash
end

function PedUtils.ApplyBehavior(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)

    if SetPedCanBeTargetted then
        SetPedCanBeTargetted(ped, false)
    end
end

function PedUtils.Spawn(cfg, label)
    label = label or 'ped'

    if not cfg or not cfg.coords or not cfg.model then
        logSpawn('%s spawn aborted: missing config', label)
        return nil
    end

    local ok, pedOrErr = pcall(function()
        local modelHash = PedUtils.LoadModel(cfg.model)
        if not modelHash then
            return nil
        end

        local c = cfg.coords
        RequestCollisionAtCoord(c.x, c.y, c.z)

        local entity = CreatePed(4, modelHash, c.x, c.y, c.z, c.w, false, true)
        if not entity or entity == 0 then
            logSpawn('%s CreatePed failed for model %s', label, cfg.model)
            SetModelAsNoLongerNeeded(modelHash)
            return nil
        end

        SetEntityCoordsNoOffset(entity, c.x, c.y, c.z, false, false, false)
        SetEntityHeading(entity, c.w)

        local timeout = GetGameTimer() + 5000
        while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < timeout do
            RequestCollisionAtCoord(c.x, c.y, c.z)
            Wait(0)
        end

        SetEntityCoordsNoOffset(entity, c.x, c.y, c.z, false, false, false)
        SetEntityHeading(entity, c.w)
        PedUtils.ApplyBehavior(entity)

        if cfg.scenario and cfg.scenario ~= '' then
            TaskStartScenarioInPlace(entity, cfg.scenario, 0, true)
        end

        SetModelAsNoLongerNeeded(modelHash)
        return entity
    end)

    if not ok then
        logSpawn('%s spawn error: %s', label, tostring(pedOrErr))
        return nil
    end

    if not pedOrErr then
        logSpawn('%s spawn returned no entity', label)
    end

    return pedOrErr
end

function PedUtils.CreateBlip(key, cfg)
    local blipCfg = cfg and cfg.blip
    if type(blipCfg) ~= 'table' or not blipCfg.enabled then
        return
    end

    if blips[key] and DoesBlipExist(blips[key]) then
        return
    end

    local c = cfg.coords
    local blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(blip, blipCfg.sprite or 431)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipCfg.scale or 0.8)
    SetBlipColour(blip, blipCfg.colour or 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(blipCfg.label or 'Pawn Shop')
    EndTextCommandSetBlipName(blip)

    blips[key] = blip
end

function PedUtils.RemoveBlip(key)
    if blips[key] and DoesBlipExist(blips[key]) then
        RemoveBlip(blips[key])
    end
    blips[key] = nil
end

function PedUtils.RemoveAllBlips()
    for key in pairs(blips) do
        PedUtils.RemoveBlip(key)
    end
end

_G.PawnPed = _G.PawnPed or {
    entity = nil,
    spawned = false,
}
local PawnPed = _G.PawnPed

function PawnPed.Spawn()
    if PawnPed.spawned and PawnPed.entity and DoesEntityExist(PawnPed.entity) then
        return PawnPed.entity
    end

    local cfg = (_G.Config or Config).Ped
    local ped = PedUtils.Spawn(cfg, 'pawnshop owner')
    if not ped then
        return nil
    end

    PawnPed.entity = ped
    PawnPed.spawned = true
    PedUtils.CreateBlip('pawnshop', cfg)
    Dbg.Print('ped', 'Spawned pawnshop owner', ped)

    return ped
end

function PawnPed.Delete()
    if PawnPed.entity and DoesEntityExist(PawnPed.entity) then
        DeleteEntity(PawnPed.entity)
    end

    PedUtils.RemoveBlip('pawnshop')
    PawnPed.entity = nil
    PawnPed.spawned = false
end

BlackMarketPed = {
    entity = nil,
    spawned = false,
}

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then
        Dbg.Print('bm-ped', 'Invalid model', model)
        return nil
    end
    lib.requestModel(hash, 10000)
    return hash
end

local function applyPedBehavior(ped)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedCanRagdoll(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCanBeTargeted(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
end

function BlackMarketPed.Spawn()
    if BlackMarketPed.spawned and BlackMarketPed.entity and DoesEntityExist(BlackMarketPed.entity) then
        return BlackMarketPed.entity
    end

    local cfg = Config.BlackMarket.Ped
    local modelHash = loadModel(cfg.model)
    if not modelHash then return nil end

    local c = cfg.coords
    local ped = CreatePed(0, modelHash, c.x, c.y, c.z - 1.0, c.w, false, true)

    if not ped or ped == 0 then
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(ped, c.w)
    applyPedBehavior(ped)

    local scenario = cfg.scenario
    if scenario and scenario ~= '' then
        TaskStartScenarioInPlace(ped, scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(modelHash)
    BlackMarketPed.entity = ped
    BlackMarketPed.spawned = true
    Dbg.Print('bm-ped', 'Spawned', ped)
    return ped
end

function BlackMarketPed.Delete()
    if BlackMarketPed.entity and DoesEntityExist(BlackMarketPed.entity) then
        DeleteEntity(BlackMarketPed.entity)
    end
    BlackMarketPed.entity = nil
    BlackMarketPed.spawned = false
end

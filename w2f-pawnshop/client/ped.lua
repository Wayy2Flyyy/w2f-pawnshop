PawnPed = {
    entity = nil,
    spawned = false,
}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][ped] %s'):format(table.concat({ ... }, ' ')))
end

local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then
        debugPrint('Invalid ped model:', model)
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
    SetPedCombatAbility(ped, 0)
    SetPedCombatMovement(ped, 0)
    SetPedCombatRange(ped, 0)
    SetPedSeeingRange(ped, 0.0)
    SetPedHearingRange(ped, 0.0)
    SetPedAlertness(ped, 0)
    SetPedKeepTask(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanPlayAmbientBaseAnims(ped, true)
    SetPedCanBeTargeted(ped, false)
    SetPedCanBeDraggedOut(ped, false)
    SetPedCanBeKnockedOffVehicle(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
end

local function startScenario(ped)
    local scenario = Config.Ped.scenario
    if not scenario or scenario == '' then return end
    TaskStartScenarioInPlace(ped, scenario, 0, true)
end

--- Spawn and configure the pawnshop owner ped.
function PawnPed.Spawn()
    if PawnPed.spawned and PawnPed.entity and DoesEntityExist(PawnPed.entity) then
        return PawnPed.entity
    end

    local cfg = Config.Ped
    local modelHash = loadModel(cfg.model)
    if not modelHash then return nil end

    local c = cfg.coords
    local ped = CreatePed(0, modelHash, c.x, c.y, c.z - 1.0, c.w, false, true)

    if not ped or ped == 0 then
        debugPrint('CreatePed failed')
        SetModelAsNoLongerNeeded(modelHash)
        return nil
    end

    SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(ped, c.w)
    applyPedBehavior(ped)
    startScenario(ped)

    SetModelAsNoLongerNeeded(modelHash)

    PawnPed.entity = ped
    PawnPed.spawned = true
    debugPrint('Spawned ped', ped)

    return ped
end

--- Remove ped on resource stop.
function PawnPed.Delete()
    if PawnPed.entity and DoesEntityExist(PawnPed.entity) then
        DeleteEntity(PawnPed.entity)
    end
    PawnPed.entity = nil
    PawnPed.spawned = false
end

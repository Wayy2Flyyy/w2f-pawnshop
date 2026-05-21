_G.BlackMarketPed = _G.BlackMarketPed or {
    entity = nil,
    spawned = false,
}
local BlackMarketPed = _G.BlackMarketPed

function BlackMarketPed.Spawn()
    if BlackMarketPed.spawned and BlackMarketPed.entity and DoesEntityExist(BlackMarketPed.entity) then
        return BlackMarketPed.entity
    end

    local cfg = (_G.Config or Config).BlackMarket.Ped
    local ped = _G.PedUtils and _G.PedUtils.Spawn(cfg, 'black market dealer')
    if not ped then
        return nil
    end

    BlackMarketPed.entity = ped
    BlackMarketPed.spawned = true
    Dbg.Print('bm-ped', 'Spawned black market dealer', ped)

    return ped
end

function BlackMarketPed.Delete()
    if BlackMarketPed.entity and DoesEntityExist(BlackMarketPed.entity) then
        DeleteEntity(BlackMarketPed.entity)
    end

    BlackMarketPed.entity = nil
    BlackMarketPed.spawned = false
end

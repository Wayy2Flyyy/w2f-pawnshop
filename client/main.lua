local function bootstrap()
    Bridge.Init()
    PawnState.SyncBlackMarketAccess()

    local ped
    for attempt = 1, 5 do
        ped = _G.PawnPed and _G.PawnPed.Spawn()
        if ped then
            break
        end
        Wait(1000)
    end

    if ped then
        PawnTarget.Register(ped)
    else
        print('[w2f-pawnshop] Pawnshop ped failed to spawn after retries — check F8 for [w2f-pawnshop][ped] lines')
    end

    local bmPed
    for attempt = 1, 5 do
        bmPed = _G.BlackMarketPed and _G.BlackMarketPed.Spawn()
        if bmPed then
            break
        end
        Wait(1000)
    end

    if bmPed then
        BlackMarketTarget.Register(bmPed)
    else
        print('[w2f-pawnshop] Black market ped failed to spawn after retries — check F8 for [w2f-pawnshop][ped] lines')
    end

    Dbg.Print('client', 'Ready')
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end

    while GetResourceState('ox_lib') ~= 'started' do
        Wait(200)
    end

    while GetResourceState('ox_target') ~= 'started' do
        Wait(200)
    end

    Wait(1000)
    bootstrap()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if _G.PawnPed and _G.PawnPed.entity then
        PawnTarget.Remove(_G.PawnPed.entity)
    end
    if _G.BlackMarketPed and _G.BlackMarketPed.entity then
        BlackMarketTarget.Remove(_G.BlackMarketPed.entity)
    end

    PawnNui.CloseAll()

    if _G.PawnPed then
        _G.PawnPed.Delete()
    end
    if _G.BlackMarketPed then
        _G.BlackMarketPed.Delete()
    end
    if _G.PedUtils then
        _G.PedUtils.RemoveAllBlips()
    end
end)

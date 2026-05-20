local function bootstrap()
    Bridge.Init()

    local ped = PawnPed.Spawn()
    if ped then
        PawnTarget.Register(ped)
    else
        Dbg.Print('client', 'Pawnshop ped failed — check Config.Ped')
    end

    local bmPed = BlackMarketPed.Spawn()
    if bmPed then
        BlackMarketTarget.Register(bmPed)
    else
        Dbg.Print('client', 'Black market ped failed — check Config.BlackMarket.Ped')
    end

    Dbg.Print('client', 'Ready')
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(500)
    end
    bootstrap()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if PawnPed.entity then
        PawnTarget.Remove(PawnPed.entity)
    end
    if BlackMarketPed.entity then
        BlackMarketTarget.Remove(BlackMarketPed.entity)
    end

    PawnNui.CloseAll()
    PawnPed.Delete()
    BlackMarketPed.Delete()
end)

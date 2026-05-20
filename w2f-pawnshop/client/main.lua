local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][client] %s'):format(table.concat({ ... }, ' ')))
end

local function bootstrap()
    Bridge.Init()

    local ped = PawnPed.Spawn()
    if not ped then
        debugPrint('Failed to spawn pawnshop ped — check Config.Ped')
        return
    end

    PawnTarget.Register(ped)
    debugPrint('Pawnshop client ready')
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
    PawnNui.CloseDialog()
    PawnPed.Delete()
end)

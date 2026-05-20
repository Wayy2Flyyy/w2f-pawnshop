local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][server] %s'):format(table.concat({ ... }, ' ')))
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Bridge.Init()
    Database.Init()
    debugPrint('Pawnshop server ready (Stage 1 — no transactions)')
end)

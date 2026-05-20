local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][server] %s'):format(table.concat({ ... }, ' ')))
end

lib.callback.register('w2f-pawnshop:getSellMenu', function(source)
    if not Database.IsReady() then
        return { ok = false, error = 'database_not_ready', items = {} }
    end

    return {
        ok = true,
        items = Transactions.BuildSellMenu(source),
    }
end)

lib.callback.register('w2f-pawnshop:sellItem', function(source, itemName, amount)
    if not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    if type(itemName) ~= 'string' or itemName == '' then
        return { ok = false, error = 'invalid_item' }
    end

    if not Items.IsSellable(itemName) then
        return { ok = false, error = 'invalid_item' }
    end

    return Transactions.ProcessSell(source, itemName, amount)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Bridge.Init()
    Database.Init()
    debugPrint('Pawnshop server ready (Stage 2 — sell system)')
end)

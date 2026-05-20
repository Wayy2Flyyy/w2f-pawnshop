local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][server] %s'):format(table.concat({ ... }, ' ')))
end

lib.callback.register('w2f-pawnshop:getDialog', function(source)
    if not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    local greeting, loyalty, demanded, blackMarket = DialogServer.BuildForPlayer(source)

    return {
        ok = true,
        ownerName = Config.Dialog.ownerName,
        greeting = greeting,
        loyalty = loyalty,
        demanded = demanded,
        blackMarketUnlock = blackMarket,
    }
end)

lib.callback.register('w2f-pawnshop:getSellMenu', function(source)
    if not Database.IsReady() then
        return { ok = false, error = 'database_not_ready', items = {} }
    end

    return {
        ok = true,
        items = Transactions.BuildSellMenu(source),
        loyalty = LoyaltyServer.GetProfile(source),
        demanded = Demand.GetDemandedList(),
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

lib.callback.register('w2f-pawnshop:getStorefront', function(source, mode)
    if not Database.IsReady() then
        return { ok = false, error = 'database_not_ready', items = {} }
    end

    mode = mode == 'view' and 'view' or 'buy'

    return {
        ok = true,
        mode = mode,
        viewOnly = mode == 'view',
        items = Transactions.BuildStorefront(source, mode),
        playerMoney = Bridge.GetMoney(source, Config.DefaultBuyAccount),
        loyalty = LoyaltyServer.GetProfile(source),
        demanded = Demand.GetDemandedList(),
    }
end)

lib.callback.register('w2f-pawnshop:checkout', function(source, cart)
    if not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    if type(cart) ~= 'table' then
        return { ok = false, error = 'invalid_cart' }
    end

    return Transactions.ProcessCheckout(source, cart)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Bridge.Init()
    Database.Init()
    debugPrint('Pawnshop server ready (Stage 4 — loyalty & demand)')
end)

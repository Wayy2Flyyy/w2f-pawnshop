AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Bridge.Init()
    Database.Init()
    Dbg.Print('server', 'Pawnshop ready (Stage 5)')
end)

lib.callback.register('w2f-pawnshop:getDialog', function(source)
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    local greeting, loyalty, demanded, blackMarket, contact = DialogServer.BuildForPlayer(source)

    return {
        ok = true,
        ownerName = Config.Dialog.ownerName,
        greeting = greeting,
        loyalty = loyalty,
        demanded = demanded,
        blackMarketUnlock = blackMarket,
        blackMarketContact = contact,
    }
end)

lib.callback.register('w2f-pawnshop:canAccessBlackMarket', function(source)
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, access = false }
    end

    return {
        ok = true,
        access = BlackMarketServer.CanAccess(source),
        level = LoyaltyServer.GetLevel(source),
        minLevel = Config.BlackMarket.minAccessLevel,
    }
end)

lib.callback.register('w2f-pawnshop:getBlackMarket', function(source)
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, error = 'database_not_ready', items = {} }
    end

    if not BlackMarketServer.CanAccess(source) then
        return {
            ok = false,
            error = 'loyalty_too_low',
            rejectionMessage = Config.BlackMarket.rejectionMessage,
        }
    end

    return {
        ok = true,
        dealerName = Config.BlackMarket.dealerName,
        greeting = Config.BlackMarket.greeting,
        items = BlackMarketServer.BuildStore(source),
        playerMoney = Bridge.GetMoney(source, Config.DefaultBuyAccount),
        loyalty = LoyaltyServer.GetProfile(source),
        cartMax = Config.CartMaxPerCheckout,
    }
end)

lib.callback.register('w2f-pawnshop:blackMarketCheckout', function(source, cart)
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    if type(cart) ~= 'table' then
        return { ok = false, error = 'invalid_cart' }
    end

    return BlackMarketServer.ProcessCheckout(source, cart)
end)

lib.callback.register('w2f-pawnshop:getSellMenu', function(source)
    if not Security.ValidateSource(source) or not Database.IsReady() then
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
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    if type(itemName) ~= 'string' or itemName == '' or not Items.IsSellable(itemName) then
        return { ok = false, error = 'invalid_item' }
    end

    return Transactions.ProcessSell(source, itemName, amount)
end)

lib.callback.register('w2f-pawnshop:getStorefront', function(source, mode)
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, error = 'database_not_ready', items = {} }
    end

    mode = mode == 'view' and 'view' or 'buy'

    Stock.EnsureAll()

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
    if not Security.ValidateSource(source) or not Database.IsReady() then
        return { ok = false, error = 'database_not_ready' }
    end

    if type(cart) ~= 'table' then
        return { ok = false, error = 'invalid_cart' }
    end

    return Transactions.ProcessCheckout(source, cart)
end)

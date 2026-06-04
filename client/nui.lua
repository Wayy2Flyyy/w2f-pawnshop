PawnNui = {
    open = false,
    view = 'dialog',
    storefrontMode = nil,
    busy = false,
}

local function nuiDebug(message, payload)
    if payload ~= nil then
        local encoded = '<unserializable>'
        if json and json.encode then
            local ok, result = pcall(json.encode, payload)
            if ok then encoded = result end
        end
        print(('[w2f-pawnshop][nui] %s %s'):format(message, encoded))
    else
        print(('[w2f-pawnshop][nui] %s'):format(message))
    end
end

local function sendPawnMessage(payload)
    nuiDebug('SendNUIMessage payload sent:', payload)
    SendNUIMessage(payload)
end

local function setPawnNuiFocus(hasFocus, hasCursor, reason)
    nuiDebug(('SetNuiFocus(%s, %s) reached%s'):format(tostring(hasFocus), tostring(hasCursor), reason and (' for ' .. reason) or ''))
    SetNuiFocus(hasFocus, hasCursor)
end

local function setBusy(state)
    PawnNui.busy = state
    PawnState.busy = state
    sendPawnMessage({ action = 'setBusy', busy = state })
end

local function fetchDialog()
    return lib.callback.await('w2f-pawnshop:getDialog', false)
end

local function buildDialogPayload()
    local data = fetchDialog() or {}
    PawnState.blackMarketAccess = data.blackMarketUnlock == true

    return {
        action = 'openDialog',
        ownerName = data.ownerName or Config.Dialog.ownerName,
        greeting = data.greeting or '',
        loyalty = data.loyalty,
        demanded = data.demanded,
        blackMarketUnlock = data.blackMarketUnlock,
        blackMarketContact = data.blackMarketContact,
    }
end

function PawnNui.OpenDialog()
    nuiDebug('PawnNui.OpenDialog() called')
    if PawnNui.open and PawnNui.view == 'dialog' then
        nuiDebug('PawnNui.OpenDialog() is already marked open; resending payload to force browser visibility')
    end

    PawnNui.open = true
    PawnNui.view = 'dialog'
    PawnNui.storefrontMode = nil
    setPawnNuiFocus(true, true, 'openDialog')
    local payload = buildDialogPayload()
    sendPawnMessage(payload)
end

function PawnNui.CloseDialog()
    if not PawnNui.open then
        setPawnNuiFocus(false, false, 'close')
        return
    end

    PawnNui.open = false
    PawnNui.view = 'dialog'
    PawnNui.storefrontMode = nil
    setBusy(false)
    setPawnNuiFocus(false, false, 'close')
    sendPawnMessage({ action = 'closeDialog' })
end

function PawnNui.CloseAll()
    PawnNui.CloseDialog()
end

function PawnNui.OpenSellMenu()
    if PawnNui.busy then return end
    setBusy(true)

    local result = lib.callback.await('w2f-pawnshop:getSellMenu', false)
    setBusy(false)

    PawnNui.open = true
    PawnNui.view = 'sell'
    PawnNui.storefrontMode = nil
    setPawnNuiFocus(true, true, 'open')

    sendPawnMessage({
        action = 'openSellMenu',
        ok = result and result.ok,
        error = result and result.error,
        items = result and result.items or {},
        loyalty = result and result.loyalty,
        demanded = result and result.demanded or {},
    })
end

function PawnNui.UpdateSellMenu(payload)
    sendPawnMessage({
        action = 'updateSellMenu',
        ok = payload.ok,
        error = payload.error,
        items = payload.items or {},
        loyalty = payload.loyalty,
        sold = payload.ok and {
            item = payload.item,
            amount = payload.amount,
            totalPrice = payload.totalPrice,
            loyaltyXp = payload.loyaltyXp,
        } or nil,
    })
end

function PawnNui.OpenStorefront(mode)
    if PawnNui.busy then return end
    setBusy(true)

    local result = lib.callback.await('w2f-pawnshop:getStorefront', false, mode)
    setBusy(false)

    PawnNui.open = true
    PawnNui.view = 'storefront'
    PawnNui.storefrontMode = mode
    setPawnNuiFocus(true, true, 'open')

    sendPawnMessage({
        action = 'openStorefront',
        ok = result and result.ok,
        error = result and result.error,
        mode = result and result.mode or mode,
        viewOnly = result and result.viewOnly or (mode == 'view'),
        theme = 'pawnshop',
        items = result and result.items or {},
        playerMoney = result and result.playerMoney or 0,
        cartMax = Config.CartMaxPerCheckout,
        loyalty = result and result.loyalty,
        demanded = result and result.demanded or {},
    })
end

function PawnNui.OpenBlackMarket()
    if PawnNui.busy then return end
    setBusy(true)

    local result = lib.callback.await('w2f-pawnshop:getBlackMarket', false)
    setBusy(false)

    if not result or not result.ok then
        if result and result.error == 'loyalty_too_low' then
            PawnNui.open = true
            PawnNui.view = 'rejection'
            setPawnNuiFocus(true, true, 'open')
            sendPawnMessage({
                action = 'openRejection',
                title = Config.BlackMarket.dealerName,
                message = result.rejectionMessage or Config.BlackMarket.rejectionMessage,
            })
            return
        end

        PawnNotify.Error('Cannot open black market right now.')
        return
    end

    PawnNui.open = true
    PawnNui.view = 'blackmarket'
    PawnNui.storefrontMode = 'buy'
    setPawnNuiFocus(true, true, 'open')

    sendPawnMessage({
        action = 'openStorefront',
        ok = true,
        theme = 'blackmarket',
        dealerName = result.dealerName,
        greeting = result.greeting,
        mode = 'buy',
        viewOnly = false,
        items = result.items or {},
        playerMoney = result.playerMoney or 0,
        cartMax = result.cartMax or Config.CartMaxPerCheckout,
        loyalty = result.loyalty,
    })
end

function PawnNui.UpdateStorefront(payload)
    sendPawnMessage({
        action = 'updateStorefront',
        ok = payload.ok,
        error = payload.error,
        items = payload.items or {},
        playerMoney = payload.playerMoney,
        loyalty = payload.loyalty,
        purchased = payload.ok and {
            totalPaid = payload.totalPaid,
            loyaltyXp = payload.loyaltyXp,
        } or nil,
    })
end

function PawnNui.DebugOpen()
    nuiDebug('PawnNui.DebugOpen() called')
    PawnNui.open = true
    PawnNui.view = 'debug'
    PawnNui.storefrontMode = nil
    setPawnNuiFocus(true, true, 'debugOpen')
    sendPawnMessage({
        action = 'debugOpen',
        message = '/testpawnnui debugOpen received. Browser JS and NUI message routing are working if this panel is visible.',
        timestamp = GetGameTimer(),
    })
end

RegisterCommand('testpawn', function()
    print('[w2f-pawnshop] testpawn command used')
    PawnNui.OpenDialog()
end, false)

RegisterCommand('testpawnnui', function()
    print('[w2f-pawnshop] testpawnnui command used')
    PawnNui.DebugOpen()
end, false)

local function backToDialog()
    PawnNui.view = 'dialog'
    PawnNui.storefrontMode = nil
    sendPawnMessage(buildDialogPayload())
end

RegisterNUICallback('dialogSelect', function(data, cb)
    cb('ok')
    if PawnNui.busy then return end

    local choice = data and data.choice
    if not choice then return end

    if choice == 'nevermind' then
        PawnNui.CloseDialog()
        return
    end

    if choice == 'blackmarket' then
        local dialog = fetchDialog() or {}
        if dialog.blackMarketContact then
            sendPawnMessage({
                action = 'showMessage',
                message = dialog.blackMarketContact,
            })
        end
        return
    end

    if choice == 'sell' then
        PawnNui.OpenSellMenu()
        return
    end

    if choice == 'buy' then
        PawnNui.OpenStorefront('buy')
        return
    end

    if choice == 'stock' then
        PawnNui.OpenStorefront('view')
    end
end)

RegisterNUICallback('sellBack', function(_, cb)
    cb('ok')
    backToDialog()
end)

RegisterNUICallback('storefrontBack', function(_, cb)
    cb('ok')
    if PawnNui.view == 'blackmarket' then
        PawnNui.CloseDialog()
        return
    end
    backToDialog()
end)

RegisterNUICallback('rejectionClose', function(_, cb)
    cb('ok')
    PawnNui.CloseDialog()
end)

RegisterNUICallback('sellItem', function(data, cb)
    cb('ok')
    if PawnNui.busy or not data or type(data.item) ~= 'string' then return end

    local amount = data.amount == 'all' and -1 or tonumber(data.amount)
    setBusy(true)

    local result = lib.callback.await('w2f-pawnshop:sellItem', false, data.item, amount)
    setBusy(false)

    if not result then return end

    if result.ok then
        PawnState.blackMarketAccess = (result.loyalty and result.loyalty.level or 1) >= Config.BlackMarket.minAccessLevel
        local xpLine = result.loyaltyXp and (' (+%s XP)'):format(result.loyaltyXp) or ''
        PawnNotify.Success(('Paid $%s for %sx %s%s.'):format(
            result.totalPrice,
            result.amount,
            Items.Get(result.item) and Items.Get(result.item).label or result.item,
            xpLine
        ))
        PawnNui.UpdateSellMenu(result)
    else
        sendPawnMessage({ action = 'sellError', error = result.error or 'unknown' })
    end
end)

RegisterNUICallback('checkout', function(data, cb)
    cb('ok')
    if PawnNui.busy or PawnNui.storefrontMode == 'view' then return end

    local cart = data and data.cart
    if type(cart) ~= 'table' then return end

    setBusy(true)

    local result
    if data.shop == 'blackmarket' or PawnNui.view == 'blackmarket' then
        result = lib.callback.await('w2f-pawnshop:blackMarketCheckout', false, cart)
    else
        result = lib.callback.await('w2f-pawnshop:checkout', false, cart)
    end

    setBusy(false)

    if not result then return end

    if result.ok then
        local xpLine = result.loyaltyXp and (' (+%s XP)'):format(result.loyaltyXp) or ''
        PawnNotify.Success(('Purchase complete — $%s%s.'):format(result.totalPaid, xpLine))
        PawnNui.UpdateStorefront(result)
    else
        sendPawnMessage({
            action = 'storefrontError',
            error = result.error or 'unknown',
            item = result.item,
        })
    end
end)

RegisterNUICallback('closeDialog', function(_, cb)
    cb('ok')
    PawnNui.CloseDialog()
end)

RegisterNUICallback('escape', function(_, cb)
    cb('ok')

    if PawnNui.view == 'rejection' then
        PawnNui.CloseDialog()
        return
    end

    if PawnNui.view == 'sell' or PawnNui.view == 'storefront' or PawnNui.view == 'blackmarket' then
        if PawnNui.view == 'blackmarket' then
            PawnNui.CloseDialog()
            return
        end
        backToDialog()
        return
    end

    PawnNui.CloseDialog()
end)

PawnNui = {
    open = false,
    view = 'dialog',
    storefrontMode = nil,
}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][nui] %s'):format(table.concat({ ... }, ' ')))
end

local function buildDialogPayload()
    local dialog = Config.Dialog
    return {
        action = 'openDialog',
        ownerName = dialog.ownerName,
        greeting = dialog.greeting,
    }
end

function PawnNui.OpenDialog()
    if PawnNui.open and PawnNui.view == 'dialog' then return end

    PawnNui.open = true
    PawnNui.view = 'dialog'
    PawnNui.storefrontMode = nil
    SetNuiFocus(true, true)
    SendNUIMessage(buildDialogPayload())
    debugPrint('Dialog opened')
end

function PawnNui.CloseDialog()
    if not PawnNui.open then
        SetNuiFocus(false, false)
        return
    end

    PawnNui.open = false
    PawnNui.view = 'dialog'
    PawnNui.storefrontMode = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeDialog' })
    debugPrint('Dialog closed')
end

function PawnNui.OpenSellMenu()
    local result = lib.callback.await('w2f-pawnshop:getSellMenu', false)

    PawnNui.open = true
    PawnNui.view = 'sell'
    PawnNui.storefrontMode = nil
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openSellMenu',
        ok = result and result.ok,
        error = result and result.error,
        items = result and result.items or {},
    })

    debugPrint('Sell menu opened')
end

function PawnNui.UpdateSellMenu(payload)
    SendNUIMessage({
        action = 'updateSellMenu',
        ok = payload.ok,
        error = payload.error,
        items = payload.items or {},
        sold = payload.ok and {
            item = payload.item,
            amount = payload.amount,
            totalPrice = payload.totalPrice,
        } or nil,
    })
end

---@param mode string 'buy' | 'view'
function PawnNui.OpenStorefront(mode)
    local result = lib.callback.await('w2f-pawnshop:getStorefront', false, mode)

    PawnNui.open = true
    PawnNui.view = 'storefront'
    PawnNui.storefrontMode = mode
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openStorefront',
        ok = result and result.ok,
        error = result and result.error,
        mode = result and result.mode or mode,
        viewOnly = result and result.viewOnly or (mode == 'view'),
        items = result and result.items or {},
        playerMoney = result and result.playerMoney or 0,
        cartMax = Config.CartMaxPerCheckout,
    })

    debugPrint('Storefront opened', mode)
end

function PawnNui.UpdateStorefront(payload)
    SendNUIMessage({
        action = 'updateStorefront',
        ok = payload.ok,
        error = payload.error,
        items = payload.items or {},
        playerMoney = payload.playerMoney,
        purchased = payload.ok and {
            totalPaid = payload.totalPaid,
        } or nil,
    })
end

local function backToDialog()
    PawnNui.view = 'dialog'
    PawnNui.storefrontMode = nil
    SendNUIMessage(buildDialogPayload())
end

RegisterNUICallback('dialogSelect', function(data, cb)
    cb('ok')

    local choice = data and data.choice
    if not choice then return end

    if choice == 'nevermind' then
        PawnNui.CloseDialog()
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
    backToDialog()
end)

RegisterNUICallback('sellItem', function(data, cb)
    cb('ok')

    if not data or type(data.item) ~= 'string' then return end

    local amount = data.amount
    if amount == 'all' then
        amount = -1
    else
        amount = tonumber(amount)
    end

    local result = lib.callback.await('w2f-pawnshop:sellItem', false, data.item, amount)
    if not result then return end

    if result.ok then
        lib.notify({
            title = Config.Dialog.ownerName,
            description = ('Paid $%s for %sx %s.'):format(
                result.totalPrice,
                result.amount,
                Items.Get(result.item) and Items.Get(result.item).label or result.item
            ),
            type = 'success',
        })
        PawnNui.UpdateSellMenu(result)
    else
        SendNUIMessage({
            action = 'sellError',
            error = result.error or 'unknown',
        })
    end
end)

RegisterNUICallback('checkout', function(data, cb)
    cb('ok')

    if PawnNui.storefrontMode == 'view' then return end

    local cart = data and data.cart
    if type(cart) ~= 'table' then return end

    local result = lib.callback.await('w2f-pawnshop:checkout', false, cart)
    if not result then return end

    if result.ok then
        lib.notify({
            title = Config.Dialog.ownerName,
            description = ('Purchase complete — $%s.'):format(result.totalPaid),
            type = 'success',
        })
        PawnNui.UpdateStorefront(result)
    else
        SendNUIMessage({
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

    if PawnNui.view == 'sell' or PawnNui.view == 'storefront' then
        backToDialog()
        return
    end

    PawnNui.CloseDialog()
end)

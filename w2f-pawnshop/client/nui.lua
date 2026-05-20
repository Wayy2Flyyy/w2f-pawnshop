PawnNui = {
    open = false,
    view = 'dialog',
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
        placeholders = dialog.placeholders,
    }
end

function PawnNui.OpenDialog()
    if PawnNui.open and PawnNui.view == 'dialog' then return end

    PawnNui.open = true
    PawnNui.view = 'dialog'
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
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeDialog' })
    debugPrint('Dialog closed')
end

function PawnNui.ShowPlaceholder(message)
    SendNUIMessage({
        action = 'showMessage',
        message = message,
    })
end

--- Request server sell rows and open the sell sub-menu.
function PawnNui.OpenSellMenu()
    local result = lib.callback.await('w2f-pawnshop:getSellMenu', false)

    PawnNui.open = true
    PawnNui.view = 'sell'
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openSellMenu',
        ok = result and result.ok,
        error = result and result.error,
        items = result and result.items or {},
    })

    debugPrint('Sell menu opened', result and #result.items or 0, 'items')
end

--- Refresh sell list after a sale.
---@param payload table
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

    local placeholders = Config.Dialog.placeholders
    if choice == 'buy' then
        PawnNui.ShowPlaceholder(placeholders.buy)
    elseif choice == 'stock' then
        PawnNui.ShowPlaceholder(placeholders.stock)
    end
end)

RegisterNUICallback('sellBack', function(_, cb)
    cb('ok')
    PawnNui.view = 'dialog'
    SendNUIMessage(buildDialogPayload())
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
            description = ('Paid %s for %sx %s.'):format(
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

RegisterNUICallback('closeDialog', function(_, cb)
    cb('ok')
    PawnNui.CloseDialog()
end)

RegisterNUICallback('escape', function(data, cb)
    cb('ok')

    if PawnNui.view == 'sell' then
        PawnNui.view = 'dialog'
        SendNUIMessage(buildDialogPayload())
        return
    end

    PawnNui.CloseDialog()
end)

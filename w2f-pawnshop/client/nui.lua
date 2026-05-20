PawnNui = {
    open = false,
}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][nui] %s'):format(table.concat({ ... }, ' ')))
end

--- Send dialog payload to the NUI layer.
local function buildDialogPayload()
    local dialog = Config.Dialog
    return {
        action = 'openDialog',
        ownerName = dialog.ownerName,
        greeting = dialog.greeting,
        placeholders = dialog.placeholders,
    }
end

--- Open the conversation dialog with focus.
function PawnNui.OpenDialog()
    if PawnNui.open then return end

    PawnNui.open = true
    SetNuiFocus(true, true)
    SendNUIMessage(buildDialogPayload())
    debugPrint('Dialog opened')
end

--- Close dialog and release focus.
function PawnNui.CloseDialog()
    if not PawnNui.open then
        SetNuiFocus(false, false)
        return
    end

    PawnNui.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeDialog' })
    debugPrint('Dialog closed')
end

--- Show a short placeholder line in the dialog (Sell / Buy / View).
---@param message string
function PawnNui.ShowPlaceholder(message)
    SendNUIMessage({
        action = 'showMessage',
        message = message,
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

    local placeholders = Config.Dialog.placeholders
    if choice == 'sell' then
        PawnNui.ShowPlaceholder(placeholders.sell)
    elseif choice == 'buy' then
        PawnNui.ShowPlaceholder(placeholders.buy)
    elseif choice == 'stock' then
        PawnNui.ShowPlaceholder(placeholders.stock)
    end
end)

RegisterNUICallback('closeDialog', function(_, cb)
    cb('ok')
    PawnNui.CloseDialog()
end)

--- ESC and other close paths from NUI.
RegisterNUICallback('escape', function(_, cb)
    cb('ok')
    PawnNui.CloseDialog()
end)

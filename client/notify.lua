RegisterNetEvent('w2f-pawnshop:client:notify', function(payload)
    if not payload then return end
    lib.notify(payload)
end)

PawnNotify = {}

---@param payload table
function PawnNotify.Show(payload)
    lib.notify(payload)
end

function PawnNotify.Error(message)
    lib.notify({
        title = Config.Dialog.ownerName,
        description = message,
        type = 'error',
    })
end

function PawnNotify.Success(message)
    lib.notify({
        title = Config.Dialog.ownerName,
        description = message,
        type = 'success',
    })
end

function PawnNotify.Info(message)
    lib.notify({
        title = Config.Dialog.ownerName,
        description = message,
        type = 'inform',
    })
end

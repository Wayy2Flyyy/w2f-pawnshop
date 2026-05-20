Notify = {}

---@param source number
---@param payload table
function Notify.Player(source, payload)
    if not Security.ValidateSource(source) then return end
    TriggerClientEvent('w2f-pawnshop:client:notify', source, payload)
end

---@param source number
---@param message string
---@param notifyType string|nil
function Notify.Error(source, message)
    Notify.Player(source, {
        title = Config.Dialog.ownerName,
        description = message,
        type = notifyType or 'error',
    })
end

---@param source number
---@param message string
function Notify.Success(source, message)
    Notify.Player(source, {
        title = Config.Dialog.ownerName,
        description = message,
        type = 'success',
    })
end

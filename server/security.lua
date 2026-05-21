Security = {
    locks = {},
    maxQuantity = 10000,
}

---@param source number
---@return boolean
function Security.ValidateSource(source)
    source = tonumber(source)
    if not source or source <= 0 then return false end
    if not GetPlayerName(source) then return false end
    return true
end

---@param amount any
---@param maxAmount number|nil
---@return number|nil
function Security.SanitizeQuantity(amount, maxAmount)
    local n = tonumber(amount)
    if not n or n ~= math.floor(n) then return nil end
    n = math.floor(n)
    if n <= 0 then return nil end

    maxAmount = maxAmount or Security.maxQuantity
    if n > maxAmount then
        n = maxAmount
    end

    return n
end

---@param source number
---@return boolean
function Security.TryLock(source)
    if not Security.ValidateSource(source) then return false end
    if Security.locks[source] then return false end
    Security.locks[source] = true
    return true
end

---@param source number
function Security.Unlock(source)
    if source then
        Security.locks[source] = nil
    end
end

AddEventHandler('playerDropped', function()
    Security.Unlock(source)
end)

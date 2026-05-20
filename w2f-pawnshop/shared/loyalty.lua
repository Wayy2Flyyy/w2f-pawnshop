--- Loyalty tier definitions (Stage 4+).
--- Stage 3: default level 1, XP hooks only.

Loyalty = {
    enabled = false,
    tiers = {},
    --- Default player level when loyalty system is not active.
    defaultLevel = 1,
}

---@param _source number|nil
---@return number
function Loyalty.GetPlayerLevel(_source)
    if not Loyalty.enabled then
        return Loyalty.defaultLevel
    end
    return Loyalty.defaultLevel
end

--- Placeholder XP grant (Stage 4 will persist).
---@param _source number
---@param _amount number
function Loyalty.AddXp(_source, _amount)
    if not _amount or _amount <= 0 then return end
    -- Stage 4: persist XP and recalculate tier.
end

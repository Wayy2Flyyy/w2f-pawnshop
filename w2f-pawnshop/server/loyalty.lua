LoyaltyServer = {}

---@param source number
---@return number
function LoyaltyServer.GetLevel(source)
    return Loyalty.GetPlayerLevel(source)
end

---@param source number
---@param amount number
function LoyaltyServer.GrantXp(source, amount)
    Loyalty.AddXp(source, amount)
end

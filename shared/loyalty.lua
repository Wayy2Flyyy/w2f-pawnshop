--- Five-stage pawnshop loyalty (shared tier definitions).

Loyalty = {
    enabled = true,
    defaultLevel = 1,
    maxLevel = 5,

    tiers = {
        [1] = {
            label = 'Unknown Customer',
            requiredXp = 0,
            sellBonusPercent = 0,
            buyDiscountPercent = 0,
            greeting = "First time in? I buy valuables, but don't waste my time.",
            unlockedCategories = { 'jewelry', 'collectibles', 'relics' },
            blackMarketUnlock = false,
        },
        [2] = {
            label = 'Regular',
            requiredXp = 100,
            sellBonusPercent = 3,
            buyDiscountPercent = 2,
            greeting = 'Back again? I might have a few better prices for you today.',
            unlockedCategories = { 'jewelry', 'collectibles', 'relics', 'luxury' },
            blackMarketUnlock = false,
        },
        [3] = {
            label = 'Trusted Seller',
            requiredXp = 300,
            sellBonusPercent = 6,
            buyDiscountPercent = 4,
            greeting = "You're becoming useful around here. Show me what you've got.",
            unlockedCategories = { 'jewelry', 'collectibles', 'relics', 'luxury', 'art' },
            blackMarketUnlock = false,
        },
        [4] = {
            label = 'Connected',
            requiredXp = 750,
            sellBonusPercent = 10,
            buyDiscountPercent = 6,
            greeting = "You've earned some trust. I know people who deal in harder-to-find goods.",
            unlockedCategories = { 'jewelry', 'collectibles', 'relics', 'luxury', 'art' },
            blackMarketUnlock = true,
        },
        [5] = {
            label = 'Inner Circle',
            requiredXp = 1500,
            sellBonusPercent = 15,
            buyDiscountPercent = 10,
            greeting = 'Good to see you. Best prices, best stock, no questions asked.',
            unlockedCategories = { 'jewelry', 'collectibles', 'relics', 'luxury', 'art' },
            blackMarketUnlock = true,
        },
    },
}

---@param xp number
---@return number level
function Loyalty.GetLevelFromXp(xp)
    xp = math.max(0, math.floor(xp or 0))
    local level = 1

    for lvl = Loyalty.maxLevel, 1, -1 do
        local tier = Loyalty.tiers[lvl]
        if tier and xp >= tier.requiredXp then
            level = lvl
            break
        end
    end

    return level
end

---@param level number
---@return table|nil
function Loyalty.GetTierByLevel(level)
    return Loyalty.tiers[level] or Loyalty.tiers[1]
end

--- Client fallback when server profile is unavailable.
---@param _source number|nil
---@return number
function Loyalty.GetPlayerLevel(_source)
    return Loyalty.defaultLevel
end

---@param level number
---@return table|nil nextTier
---@return number xpToNext
function Loyalty.GetNextTierProgress(level, xp)
    local nextTier = Loyalty.tiers[level + 1]
    if not nextTier then
        return nil, 0
    end

    return nextTier, math.max(0, nextTier.requiredXp - xp)
end

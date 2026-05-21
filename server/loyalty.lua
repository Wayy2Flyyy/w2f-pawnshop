LoyaltyServer = {}

local cache = {}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][loyalty] %s'):format(table.concat({ ... }, ' ')))
end

---@param identifier string
---@return table
function LoyaltyServer.GetRecord(identifier)
    if cache[identifier] then
        return cache[identifier]
    end

    local row = MySQL.single.await(
        'SELECT identifier, xp, level, total_sold, total_bought FROM w2f_pawnshop_loyalty WHERE identifier = ?',
        { identifier }
    )

    if row then
        cache[identifier] = row
        return row
    end

    MySQL.insert.await(
        'INSERT INTO w2f_pawnshop_loyalty (identifier, xp, level, total_sold, total_bought) VALUES (?, 0, 1, 0, 0)',
        { identifier }
    )

    row = {
        identifier = identifier,
        xp = 0,
        level = 1,
        total_sold = 0,
        total_bought = 0,
    }

    cache[identifier] = row
    return row
end

---@param identifier string
---@param record table
local function saveRecord(identifier, record)
    record.level = Loyalty.GetLevelFromXp(record.xp)

    MySQL.update.await(
        [[UPDATE w2f_pawnshop_loyalty
          SET xp = ?, level = ?, total_sold = ?, total_bought = ?
          WHERE identifier = ?]],
        { record.xp, record.level, record.total_sold, record.total_bought, identifier }
    )

    cache[identifier] = record
end

---@param source number
---@return table|nil
function LoyaltyServer.GetProfile(source)
    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return nil end

    local record = LoyaltyServer.GetRecord(identifier)
    local level = Loyalty.GetLevelFromXp(record.xp)
    local tier = Loyalty.GetTierByLevel(level)
    local nextTier, xpToNext = Loyalty.GetNextTierProgress(level, record.xp)

    local progressPercent = 100
    if nextTier then
        local span = nextTier.requiredXp - tier.requiredXp
        local current = record.xp - tier.requiredXp
        progressPercent = span > 0 and math.floor((current / span) * 100) or 0
    end

    return {
        level = level,
        label = tier.label,
        xp = record.xp,
        nextLevel = nextTier and (level + 1) or nil,
        nextLevelLabel = nextTier and nextTier.label or nil,
        nextLevelXp = nextTier and nextTier.requiredXp or nil,
        xpToNext = xpToNext,
        progressPercent = progressPercent,
        sellBonusPercent = tier.sellBonusPercent,
        buyDiscountPercent = tier.buyDiscountPercent,
        totalSold = record.total_sold,
        totalBought = record.total_bought,
        blackMarketUnlock = tier.blackMarketUnlock == true,
        tier = tier,
    }
end

---@param source number
---@return number
function LoyaltyServer.GetLevel(source)
    local profile = LoyaltyServer.GetProfile(source)
    return profile and profile.level or Loyalty.defaultLevel
end

---@param source number
---@param category string
---@return boolean
function LoyaltyServer.HasCategory(source, category)
    local profile = LoyaltyServer.GetProfile(source)
    if not profile or not profile.tier then return false end

    for i = 1, #profile.tier.unlockedCategories do
        if profile.tier.unlockedCategories[i] == category then
            return true
        end
    end

    return false
end

---@param source number
---@param amount number
---@param reason string|nil 'sell'|'buy'
---@param itemCount number|nil units sold/bought
function LoyaltyServer.GrantXp(source, amount, reason, itemCount)
    if not Config.Loyalty.enabled then return end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end

    local identifier = Bridge.GetIdentifier(source)
    if not identifier then return end

    local record = LoyaltyServer.GetRecord(identifier)
    local oldLevel = record.level
    record.xp = record.xp + amount

    if reason == 'sell' then
        record.total_sold = record.total_sold + (itemCount or 1)
    elseif reason == 'buy' then
        record.total_bought = record.total_bought + (itemCount or 1)
    end

    saveRecord(identifier, record)

    local newLevel = record.level
    if newLevel > oldLevel then
        local tier = Loyalty.GetTierByLevel(newLevel)
        TriggerClientEvent('ox_lib:notify', source, {
            title = Config.Dialog.ownerName,
            description = ('Reputation increased — %s (Level %s).'):format(tier.label, newLevel),
            type = 'success',
        })
        debugPrint('Level up', source, newLevel)
    end
end

Pricing = {}

---@param source number
---@param itemName string
---@return number|nil finalPrice
---@return table breakdown
function Pricing.GetSellPrice(source, itemName)
    local cfg = Items.Get(itemName)
    if not cfg then return nil, {} end

    local profile = LoyaltyServer.GetProfile(source)
    local stock = Stock.GetQuantity(itemName)
    local loyaltyPct = profile and profile.sellBonusPercent or 0
    local demandPct = Demand.IsDemanded(itemName, stock) and Demand.GetSellBonusPercent() or 0

    local loyaltyAmt = math.floor(cfg.baseSellPrice * (loyaltyPct / 100))
    local demandAmt = math.floor(cfg.baseSellPrice * (demandPct / 100))
    local raw = cfg.baseSellPrice + loyaltyAmt + demandAmt

    local maxAllowed = cfg.buyPrice - Config.MinimumProfitMargin
    local finalPrice = math.min(raw, maxAllowed)
    finalPrice = math.max(1, math.floor(finalPrice))

    return finalPrice, {
        baseSellPrice = cfg.baseSellPrice,
        loyaltyBonusPercent = loyaltyPct,
        demandBonusPercent = demandPct,
        loyaltyBonus = loyaltyAmt,
        demandBonus = demandAmt,
        demanded = demandPct > 0,
        maxAllowed = maxAllowed,
    }
end

---@param source number
---@param itemName string
---@return number|nil
---@return table
function Pricing.GetBuyPrice(source, itemName)
    local cfg = Items.Get(itemName)
    if not cfg then return nil, {} end

    local profile = LoyaltyServer.GetProfile(source)
    local discountPct = profile and profile.buyDiscountPercent or 0
    local discountAmt = math.floor(cfg.buyPrice * (discountPct / 100))
    local finalPrice = math.max(1, cfg.buyPrice - discountAmt)

    return finalPrice, {
        baseBuyPrice = cfg.buyPrice,
        buyDiscountPercent = discountPct,
        buyDiscount = discountAmt,
    }
end

---@param source number
---@param itemName string
---@param amount number
---@param unitPrice number
---@param demanded boolean
---@return number
function Pricing.CalculateSellXp(source, itemName, amount, unitPrice, demanded)
    local cfg = Items.Get(itemName)
    if not cfg then return 0 end

    amount = math.max(1, math.floor(amount or 1))
    local base = (cfg.loyaltyXp or 1) * amount
    local valueBonus = math.floor((unitPrice * amount) / 100) * (Config.Loyalty.XPPerHundredSold or 0)
    local xp = math.floor((base + valueBonus) * (Config.Loyalty.XPSellMultiplier or 1))

    if demanded then
        xp = math.floor(xp * (Config.LowStock.xpBonusMultiplier or 1))
    end

    return math.max(1, xp)
end

---@param itemName string
---@param amount number
---@return number
function Pricing.CalculateBuyXp(itemName, amount)
    local cfg = Items.Get(itemName)
    if not cfg then return 0 end

    amount = math.max(1, math.floor(amount or 1))
    local xp = math.floor((cfg.loyaltyXp or 1) * amount * (Config.Loyalty.XPBuyMultiplier or 1))
    return math.max(1, xp)
end

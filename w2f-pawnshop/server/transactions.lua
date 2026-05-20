Transactions = {}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][transactions] %s'):format(table.concat({ ... }, ' ')))
end

local function getOwnedCount(source, itemName)
    return exports.ox_inventory:GetItemCount(source, itemName) or 0
end

local function sanitizeAmount(amount)
    return Security.SanitizeQuantity(amount, Config.MaxSellPerAction)
end

--- Server-side purchase eligibility (loyalty level + category + item rule).
---@param source number
---@param itemName string
---@return boolean canBuy
---@return boolean locked
---@return string|nil lockReason
function Transactions.CanPlayerBuy(source, itemName)
    local cfg = Items.Get(itemName)
    if not cfg then return false, true, 'invalid' end

    local level = LoyaltyServer.GetLevel(source)
    local required = cfg.minLoyaltyToBuy or 0

    if level < required then
        return false, true, 'level'
    end

    if not LoyaltyServer.HasCategory(source, cfg.category) then
        return false, true, 'category'
    end

    return true, false, nil
end

function Transactions.BuildSellMenu(source)
    local rows = {}

    for itemName in pairs(Items.GetCatalog()) do
        local owned = getOwnedCount(source, itemName)
        if owned > 0 then
            local cfg = Items.Get(itemName)
            local finalPrice, breakdown = Pricing.GetSellPrice(source, itemName)

            rows[#rows + 1] = {
                name = itemName,
                label = cfg.label,
                image = Items.GetImage(itemName),
                owned = owned,
                baseSellPrice = cfg.baseSellPrice,
                bonus = breakdown.loyaltyBonus + breakdown.demandBonus,
                loyaltyBonus = breakdown.loyaltyBonus,
                demandBonus = breakdown.demandBonus,
                loyaltyBonusPercent = breakdown.loyaltyBonusPercent,
                demandBonusPercent = breakdown.demandBonusPercent,
                demanded = breakdown.demanded,
                finalSellPrice = finalPrice,
                category = cfg.category,
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.demanded ~= b.demanded then
            return a.demanded
        end
        return a.label < b.label
    end)

    return rows
end

function Transactions.LogSell(source, identifier, itemName, amount, unitPrice, totalPrice)
    MySQL.insert.await(
        [[INSERT INTO w2f_pawnshop_transactions
            (identifier, item, amount, unit_price, total_price, type)
          VALUES (?, ?, ?, ?, ?, 'sell')]],
        { identifier, itemName, amount, unitPrice, totalPrice }
    )
    debugPrint('Logged sell', source, itemName, amount, totalPrice)
end

function Transactions.ProcessSell(source, itemName, amount)
    if not Security.ValidateSource(source) then
        return { ok = false, error = 'invalid_source' }
    end

    if type(itemName) ~= 'string' or not Items.IsSellable(itemName) then
        return { ok = false, error = 'invalid_item' }
    end

    if not Security.TryLock(source) then
        return { ok = false, error = 'busy' }
    end

    local ok, result = pcall(function()
    local cfg = Items.Get(itemName)
    if not cfg then
        return { ok = false, error = 'invalid_item' }
    end

    local owned = getOwnedCount(source, itemName)
    if owned <= 0 then
        return { ok = false, error = 'not_owned' }
    end

    if amount == -1 then
        amount = owned
    end

    amount = sanitizeAmount(amount)
    if not amount then
        return { ok = false, error = 'invalid_amount' }
    end

    if amount > owned then
        amount = owned
    end

    local unitPrice, breakdown = Pricing.GetSellPrice(source, itemName)
    if not unitPrice then
        return { ok = false, error = 'invalid_price' }
    end

    if unitPrice > Items.GetMaxUnitSellPrice(cfg) then
        return { ok = false, error = 'price_violation' }
    end

    local totalPrice = unitPrice * amount
    if totalPrice <= 0 then
        return { ok = false, error = 'invalid_total' }
    end

    if not Bridge.IsFramework() then
        return { ok = false, error = 'no_framework' }
    end

    local identifier = Bridge.GetIdentifier(source)
    if not identifier then
        return { ok = false, error = 'no_identifier' }
    end

    local removed = exports.ox_inventory:RemoveItem(source, itemName, amount)
    if not removed then
        return { ok = false, error = 'remove_failed' }
    end

    if not Bridge.AddMoney(source, Config.DefaultSellAccount, totalPrice) then
        exports.ox_inventory:AddItem(source, itemName, amount)
        return { ok = false, error = 'payment_failed' }
    end

    Stock.Add(itemName, amount)
    Transactions.LogSell(source, identifier, itemName, amount, unitPrice, totalPrice)

    local xp = Pricing.CalculateSellXp(source, itemName, amount, unitPrice, breakdown.demanded)
    LoyaltyServer.GrantXp(source, xp, 'sell', amount)

    local items = Transactions.BuildSellMenu(source)

    return {
        ok = true,
        item = itemName,
        amount = amount,
        unitPrice = unitPrice,
        totalPrice = totalPrice,
        loyaltyXp = xp,
        items = items,
        loyalty = LoyaltyServer.GetProfile(source),
    }
    end)

    Security.Unlock(source)
    if not ok then
        return { ok = false, error = 'server_error' }
    end
    return result
end

function Transactions.BuildStorefront(source, mode)
    local stockMap = Stock.GetAll()
    local rows = {}
    local viewOnly = mode == 'view'

    for itemName, cfg in pairs(Items.GetCatalog()) do
        local stock = stockMap[itemName] or Stock.GetQuantity(itemName)
        local include = viewOnly

        if not viewOnly then
            include = stock > 0
        elseif not Config.AllowViewingOutOfStock and stock <= 0 then
            include = false
        end

        if include then
            local canBuy, loyaltyLocked, lockReason = Transactions.CanPlayerBuy(source, itemName)
            local buyPrice = Pricing.GetBuyPrice(source, itemName)
            local demanded = Demand.IsDemanded(itemName, stock)

            if Config.HideLockedItems and loyaltyLocked and not viewOnly then
                include = false
            end

            if include then
                rows[#rows + 1] = {
                    name = itemName,
                    label = cfg.label,
                    image = Items.GetImage(itemName),
                    category = cfg.category,
                    categoryLabel = Items.GetCategoryLabel(cfg.category),
                    stock = stock,
                    buyPrice = buyPrice,
                    baseBuyPrice = cfg.buyPrice,
                    minLoyaltyToBuy = cfg.minLoyaltyToBuy or 0,
                    canBuy = canBuy and stock > 0,
                    loyaltyLocked = loyaltyLocked,
                    lockReason = lockReason,
                    demanded = demanded,
                }
            end
        end
    end

    table.sort(rows, function(a, b)
        if a.category == b.category then
            return a.label < b.label
        end
        return a.category < b.category
    end)

    return rows
end

function Transactions.LogBuy(source, identifier, itemName, amount, unitPrice, totalPrice)
    MySQL.insert.await(
        [[INSERT INTO w2f_pawnshop_transactions
            (identifier, item, amount, unit_price, total_price, type)
          VALUES (?, ?, ?, ?, ?, 'buy')]],
        { identifier, itemName, amount, unitPrice, totalPrice }
    )
    debugPrint('Logged buy', source, itemName, amount, totalPrice)
end

local function normalizeCart(cart)
    if type(cart) ~= 'table' then
        return nil, 'invalid_cart'
    end

    local merged = {}
    local totalQty = 0

    for i = 1, #cart do
        local entry = cart[i]
        if type(entry) ~= 'table' then
            return nil, 'invalid_cart'
        end

        local itemName = entry.item or entry.name
        if type(itemName) ~= 'string' or itemName == '' or not Items.Get(itemName) then
            return nil, 'invalid_item'
        end

        local qty = Security.SanitizeQuantity(entry.quantity or entry.amount, Config.CartMaxPerCheckout)
        if not qty then
            return nil, 'invalid_amount'
        end

        merged[itemName] = (merged[itemName] or 0) + qty
    end

    local lines = {}
    for itemName, qty in pairs(merged) do
        totalQty = totalQty + qty
        if totalQty > Config.CartMaxPerCheckout then
            return nil, 'cart_limit'
        end

        lines[#lines + 1] = {
            item = itemName,
            quantity = qty,
        }
    end

    if #lines == 0 then
        return nil, 'empty_cart'
    end

    return lines, nil
end

function Transactions.ProcessCheckout(source, cart)
    if not Security.ValidateSource(source) then
        return { ok = false, error = 'invalid_source' }
    end

    if not Security.TryLock(source) then
        return { ok = false, error = 'busy' }
    end

    local ok, result = pcall(function()
    if not Bridge.IsFramework() then
        return { ok = false, error = 'no_framework' }
    end

    local identifier = Bridge.GetIdentifier(source)
    if not identifier then
        return { ok = false, error = 'no_identifier' }
    end

    local lines, cartError = normalizeCart(cart)
    if not lines then
        return { ok = false, error = cartError }
    end

    local stockMap = Stock.GetAll()
    local validated = {}
    local totalCost = 0
    local totalXp = 0

    for i = 1, #lines do
        local line = lines[i]
        local cfg = Items.Get(line.item)
        local canBuy, loyaltyLocked = Transactions.CanPlayerBuy(source, line.item)

        if loyaltyLocked or not canBuy then
            return { ok = false, error = 'loyalty_locked' }
        end

        local stock = stockMap[line.item]
        if stock == nil then
            stock = Stock.GetQuantity(line.item)
        end

        if line.quantity > stock then
            return { ok = false, error = 'insufficient_stock', item = line.item }
        end

        local unitPrice = Pricing.GetBuyPrice(source, line.item)
        if not unitPrice then
            return { ok = false, error = 'invalid_price' }
        end

        validated[#validated + 1] = {
            item = line.item,
            quantity = line.quantity,
            unitPrice = unitPrice,
            lineTotal = unitPrice * line.quantity,
        }

        totalCost = totalCost + (unitPrice * line.quantity)
        totalXp = totalXp + Pricing.CalculateBuyXp(line.item, line.quantity)
    end

    if totalCost <= 0 then
        return { ok = false, error = 'invalid_total' }
    end

    local balance = Bridge.GetMoney(source, Config.DefaultBuyAccount)
    if balance < totalCost then
        return { ok = false, error = 'insufficient_funds' }
    end

    if not Bridge.RemoveMoney(source, Config.DefaultBuyAccount, totalCost) then
        return { ok = false, error = 'payment_failed' }
    end

    local delivered = {}
    local stockReduced = {}

    for i = 1, #validated do
        local v = validated[i]
        local added = exports.ox_inventory:AddItem(source, v.item, v.quantity)

        if not added then
            for j = 1, #delivered do
                local d = delivered[j]
                exports.ox_inventory:RemoveItem(source, d.item, d.quantity)
            end
            for j = 1, #stockReduced do
                local s = stockReduced[j]
                Stock.Add(s.item, s.quantity)
            end
            Bridge.AddMoney(source, Config.DefaultBuyAccount, totalCost)
            return { ok = false, error = 'inventory_full' }
        end

        delivered[#delivered + 1] = v

        if not Stock.Remove(v.item, v.quantity) then
            for j = 1, #delivered do
                exports.ox_inventory:RemoveItem(source, delivered[j].item, delivered[j].quantity)
            end
            for j = 1, #stockReduced do
                local s = stockReduced[j]
                Stock.Add(s.item, s.quantity)
            end
            Bridge.AddMoney(source, Config.DefaultBuyAccount, totalCost)
            return { ok = false, error = 'insufficient_stock', item = v.item }
        end

        stockReduced[#stockReduced + 1] = { item = v.item, quantity = v.quantity }
        Transactions.LogBuy(source, identifier, v.item, v.quantity, v.unitPrice, v.lineTotal)
    end

    local boughtQty = 0
    for i = 1, #validated do
        boughtQty = boughtQty + validated[i].quantity
    end
    LoyaltyServer.GrantXp(source, totalXp, 'buy', boughtQty)

    return {
        ok = true,
        totalPaid = totalCost,
        loyaltyXp = totalXp,
        items = Transactions.BuildStorefront(source, 'buy'),
        playerMoney = Bridge.GetMoney(source, Config.DefaultBuyAccount),
        loyalty = LoyaltyServer.GetProfile(source),
    }
    end)

    Security.Unlock(source)
    if not ok then
        return { ok = false, error = 'server_error' }
    end
    return result
end

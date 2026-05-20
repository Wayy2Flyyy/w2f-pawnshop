Transactions = {}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][transactions] %s'):format(table.concat({ ... }, ' ')))
end

---@param source number
---@return number
local function getOwnedCount(source, itemName)
    return exports.ox_inventory:GetItemCount(source, itemName) or 0
end

---@param itemName string
---@param amount number
---@return number|nil
local function sanitizeAmount(amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return nil end
    if amount > Config.MaxSellPerAction then
        return Config.MaxSellPerAction
    end
    return amount
end

--- Build sell-menu rows for items the player owns and are in the catalog.
---@param source number
---@return table
function Transactions.BuildSellMenu(source)
    local rows = {}

    for itemName in pairs(Items.GetCatalog()) do
        local owned = getOwnedCount(source, itemName)
        if owned > 0 then
            local cfg = Items.Get(itemName)
            local finalPrice, bonusPercent = Items.CalculateFinalSellPrice(itemName, source)
            local bonusAmount = math.floor(cfg.baseSellPrice * (bonusPercent / 100))

            rows[#rows + 1] = {
                name = itemName,
                label = cfg.label,
                image = Items.GetImage(itemName),
                owned = owned,
                baseSellPrice = cfg.baseSellPrice,
                bonus = bonusAmount,
                bonusPercent = bonusPercent,
                finalSellPrice = finalPrice,
                category = cfg.category,
            }
        end
    end

    table.sort(rows, function(a, b)
        return a.label < b.label
    end)

    return rows
end

---@param source number
---@param identifier string
---@param itemName string
---@param amount number
---@param unitPrice number
---@param totalPrice number
function Transactions.LogSell(source, identifier, itemName, amount, unitPrice, totalPrice)
    MySQL.insert.await(
        [[INSERT INTO w2f_pawnshop_transactions
            (identifier, item, amount, unit_price, total_price, type)
          VALUES (?, ?, ?, ?, ?, 'sell')]],
        { identifier, itemName, amount, unitPrice, totalPrice }
    )
    debugPrint('Logged sell', source, itemName, amount, totalPrice)
end

--- Process a validated sell and return refreshed menu payload.
---@param source number
---@param itemName string
---@param amount number
---@return table
function Transactions.ProcessSell(source, itemName, amount)
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

    local unitPrice, bonusPercent = Items.CalculateFinalSellPrice(itemName, source)
    if not unitPrice then
        return { ok = false, error = 'invalid_price' }
    end

    local maxUnit = Items.GetMaxUnitSellPrice(cfg)
    if unitPrice >= cfg.buyPrice - Config.MinimumProfitMargin then
        return { ok = false, error = 'price_violation' }
    end

    if unitPrice > maxUnit then
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

    if not Bridge.AddMoney(source, Config.SellPaymentAccount, totalPrice) then
        exports.ox_inventory:AddItem(source, itemName, amount)
        return { ok = false, error = 'payment_failed' }
    end

    Stock.Add(itemName, amount)
    Transactions.LogSell(source, identifier, itemName, amount, unitPrice, totalPrice)

    return {
        ok = true,
        item = itemName,
        amount = amount,
        unitPrice = unitPrice,
        totalPrice = totalPrice,
        bonusPercent = bonusPercent,
        items = Transactions.BuildSellMenu(source),
    }
end

BlackMarketServer = {}

local function debugPrint(...)
    Dbg.Print('blackmarket', ...)
end

---@param source number
---@return boolean
function BlackMarketServer.CanAccess(source)
    if not Security.ValidateSource(source) then return false end
    local level = LoyaltyServer.GetLevel(source)
    local minLevel = Config.BlackMarket.minAccessLevel or BlackMarket.minAccessLevel
    return level >= minLevel
end

---@param source number
---@param itemName string
---@return boolean canBuy
---@return boolean locked
function BlackMarketServer.CanBuyItem(source, itemName)
    local cfg = BlackMarket.Get(itemName)
    if not cfg then return false, true end

    local level = LoyaltyServer.GetLevel(source)
    if level < (cfg.requiredLoyalty or Config.BlackMarket.minAccessLevel) then
        return false, true
    end

    return true, false
end

---@param itemName string
---@return number
function BlackMarketServer.GetUnitPrice(itemName)
    local cfg = BlackMarket.Get(itemName)
    if not cfg then return 0 end
    return math.max(1, math.floor(cfg.buyPrice))
end

---@param source number
---@return table
function BlackMarketServer.BuildStore(source)
    local stockMap = BlackMarketStock.GetAll()
    local rows = {}
    for itemName, cfg in pairs(BlackMarket.GetCatalog()) do
        local stock = stockMap[itemName] or 0
        local canBuy, locked = BlackMarketServer.CanBuyItem(source, itemName)

        if Config.BlackMarket.hideLockedItems and locked then
            goto continue
        end

        if stock > 0 or Config.BlackMarket.showOutOfStock then
            rows[#rows + 1] = {
                name = itemName,
                label = cfg.label,
                image = BlackMarket.GetImage(itemName),
                description = cfg.description,
                category = cfg.category,
                categoryLabel = BlackMarket.categories[cfg.category] or cfg.category,
                stock = stock,
                buyPrice = BlackMarketServer.GetUnitPrice(itemName),
                requiredLoyalty = cfg.requiredLoyalty,
                canBuy = canBuy and stock > 0,
                loyaltyLocked = locked,
                exclusive = cfg.requiredLoyalty >= 5,
            }
        end

        ::continue::
    end

    table.sort(rows, function(a, b)
        if a.exclusive ~= b.exclusive then
            return not a.exclusive
        end
        return a.label < b.label
    end)

    return rows
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
        if not BlackMarket.IsCatalogItem(itemName) then
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

        lines[#lines + 1] = { item = itemName, quantity = qty }
    end

    if #lines == 0 then
        return nil, 'empty_cart'
    end

    return lines, nil
end

function BlackMarketServer.ProcessCheckout(source, cart)
    if not Security.ValidateSource(source) then
        return { ok = false, error = 'invalid_source' }
    end

    if not BlackMarketServer.CanAccess(source) then
        return { ok = false, error = 'loyalty_too_low' }
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

        local stockMap = BlackMarketStock.GetAll()
        local validated = {}
        local totalCost = 0

        for i = 1, #lines do
            local line = lines[i]
            local canBuy, locked = BlackMarketServer.CanBuyItem(source, line.item)

            if locked or not canBuy then
                return { ok = false, error = 'loyalty_locked', item = line.item }
            end

            local stock = stockMap[line.item] or 0
            if line.quantity > stock then
                return { ok = false, error = 'insufficient_stock', item = line.item }
            end

            local unitPrice = BlackMarketServer.GetUnitPrice(line.item)
            if unitPrice <= 0 then
                return { ok = false, error = 'invalid_price' }
            end

            validated[#validated + 1] = {
                item = line.item,
                quantity = line.quantity,
                unitPrice = unitPrice,
                lineTotal = unitPrice * line.quantity,
            }

            totalCost = totalCost + (unitPrice * line.quantity)
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
                    exports.ox_inventory:RemoveItem(source, delivered[j].item, delivered[j].quantity)
                end
                for j = 1, #stockReduced do
                    BlackMarketStock.Add(stockReduced[j].item, stockReduced[j].quantity)
                end
                Bridge.AddMoney(source, Config.DefaultBuyAccount, totalCost)
                return { ok = false, error = 'inventory_full' }
            end

            delivered[#delivered + 1] = v

            if not BlackMarketStock.Remove(v.item, v.quantity) then
                for j = 1, #delivered do
                    exports.ox_inventory:RemoveItem(source, delivered[j].item, delivered[j].quantity)
                end
                for j = 1, #stockReduced do
                    BlackMarketStock.Add(stockReduced[j].item, stockReduced[j].quantity)
                end
                Bridge.AddMoney(source, Config.DefaultBuyAccount, totalCost)
                return { ok = false, error = 'insufficient_stock', item = v.item }
            end

            stockReduced[#stockReduced + 1] = v

            MySQL.insert.await(
                [[INSERT INTO w2f_pawnshop_transactions
                    (identifier, item, amount, unit_price, total_price, type)
                  VALUES (?, ?, ?, ?, ?, 'blackmarket_buy')]],
                { identifier, v.item, v.quantity, v.unitPrice, v.lineTotal }
            )
        end

        debugPrint('Checkout ok', source, totalCost)

        return {
            ok = true,
            totalPaid = totalCost,
            items = BlackMarketServer.BuildStore(source),
            playerMoney = Bridge.GetMoney(source, Config.DefaultBuyAccount),
            loyalty = LoyaltyServer.GetProfile(source),
        }
    end)

    Security.Unlock(source)

    if not ok then
        debugPrint('Checkout error', result)
        return { ok = false, error = 'server_error' }
    end

    return result
end

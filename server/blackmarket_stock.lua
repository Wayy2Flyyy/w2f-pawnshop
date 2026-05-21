BlackMarketStock = {}

local function debugPrint(...)
    Dbg.Print('bm-stock', ...)
end

function BlackMarketStock.EnsureAll()
    if not Database.IsReady() then return end

    for itemName, cfg in pairs(BlackMarket.GetCatalog()) do
        local existing = MySQL.scalar.await(
            'SELECT quantity FROM w2f_pawnshop_blackmarket_stock WHERE item = ?',
            { itemName }
        )

        if existing == nil then
            MySQL.insert.await(
                'INSERT INTO w2f_pawnshop_blackmarket_stock (item, quantity) VALUES (?, ?)',
                { itemName, cfg.baseStock or 0 }
            )
            debugPrint('Seeded', itemName, cfg.baseStock)
        end
    end
end

---@param itemName string
---@return number
function BlackMarketStock.GetQuantity(itemName)
    if not BlackMarket.IsCatalogItem(itemName) then return 0 end

    local qty = MySQL.scalar.await(
        'SELECT quantity FROM w2f_pawnshop_blackmarket_stock WHERE item = ?',
        { itemName }
    )

    return tonumber(qty) or 0
end

---@return table<string, number>
function BlackMarketStock.GetAll()
    local rows = MySQL.query.await('SELECT item, quantity FROM w2f_pawnshop_blackmarket_stock', {})
    local map = {}

    if rows then
        for i = 1, #rows do
            map[rows[i].item] = tonumber(rows[i].quantity) or 0
        end
    end

    return map
end

---@param itemName string
---@param amount number
---@return boolean
function BlackMarketStock.Remove(itemName, amount)
    amount = Security.SanitizeQuantity(amount, Config.MaxSellPerAction)
    if not amount or not BlackMarket.IsCatalogItem(itemName) then return false end

    local affected = MySQL.update.await(
        'UPDATE w2f_pawnshop_blackmarket_stock SET quantity = quantity - ? WHERE item = ? AND quantity >= ?',
        { amount, itemName, amount }
    )

    return (affected or 0) > 0
end

---@param itemName string
---@param amount number
function BlackMarketStock.Add(itemName, amount)
    amount = Security.SanitizeQuantity(amount, Security.maxQuantity)
    if not amount or not BlackMarket.IsCatalogItem(itemName) then return end

    MySQL.update.await(
        'UPDATE w2f_pawnshop_blackmarket_stock SET quantity = quantity + ? WHERE item = ?',
        { amount, itemName }
    )
end

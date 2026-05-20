Stock = {}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][stock] %s'):format(table.concat({ ... }, ' ')))
end

--- Insert missing catalog items with baseStock from config.
function Stock.EnsureAll()
    if not Database.IsReady() then return end

    for itemName, cfg in pairs(Items.GetCatalog()) do
        local existing = MySQL.scalar.await(
            'SELECT quantity FROM w2f_pawnshop_stock WHERE item = ?',
            { itemName }
        )

        if existing == nil then
            MySQL.insert.await(
                'INSERT INTO w2f_pawnshop_stock (item, quantity) VALUES (?, ?)',
                { itemName, cfg.baseStock or 0 }
            )
            debugPrint('Seeded stock', itemName, cfg.baseStock)
        end
    end
end

---@param itemName string
---@return number
function Stock.GetQuantity(itemName)
    if not Items.IsSellable(itemName) then return 0 end

    local qty = MySQL.scalar.await(
        'SELECT quantity FROM w2f_pawnshop_stock WHERE item = ?',
        { itemName }
    )

    return tonumber(qty) or 0
end

---@param itemName string
---@param amount number
---@return boolean
function Stock.Add(itemName, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or not Items.IsSellable(itemName) then return false end

    MySQL.update.await(
        'UPDATE w2f_pawnshop_stock SET quantity = quantity + ? WHERE item = ?',
        { amount, itemName }
    )

    debugPrint('Stock +', amount, itemName)
    return true
end

---@return table<string, number>
function Stock.GetAll()
    local rows = MySQL.query.await('SELECT item, quantity FROM w2f_pawnshop_stock', {})
    local map = {}

    if rows then
        for i = 1, #rows do
            map[rows[i].item] = tonumber(rows[i].quantity) or 0
        end
    end

    return map
end

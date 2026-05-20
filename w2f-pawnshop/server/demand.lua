Demand = {}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][demand] %s'):format(table.concat({ ... }, ' ')))
end

---@param stock number
---@return boolean
function Demand.IsLowStock(stock)
    return (tonumber(stock) or 0) <= Config.LowStock.threshold
end

---@param itemName string
---@param stock number|nil
---@return boolean
function Demand.IsDemanded(itemName, stock)
    if not Items.Get(itemName) then return false end
    if stock == nil then
        stock = Stock.GetQuantity(itemName)
    end
    return Demand.IsLowStock(stock)
end

---@param stockMap table<string, number>|nil
---@return table[] demandedRows { name, label, stock }
function Demand.GetDemandedList(stockMap)
    stockMap = stockMap or Stock.GetAll()
    local rows = {}

    for itemName, cfg in pairs(Items.GetCatalog()) do
        local stock = stockMap[itemName]
        if stock == nil then
            stock = Stock.GetQuantity(itemName)
        end

        if Demand.IsLowStock(stock) then
            rows[#rows + 1] = {
                name = itemName,
                label = cfg.label,
                stock = stock,
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.stock == b.stock then
            return a.label < b.label
        end
        return a.stock < b.stock
    end)

    return rows
end

---@param demanded table[]
---@return string|nil
function Demand.BuildDialogMessage(demanded)
    if not demanded or #demanded == 0 then
        return nil
    end

    local limit = math.min(#demanded, Config.DemandedItemLimit)
    local names = {}

    for i = 1, limit do
        names[#names + 1] = demanded[i].label:lower()
    end

    if #names == 1 then
        return ("I'm running low on %s. Bring me some and I'll pay better than usual."):format(names[1])
    end

    return ("I'm running low on %s and %s. Bring them in — I'll pay better than usual."):format(names[1], names[2])
end

---@return number
function Demand.GetSellBonusPercent()
    return Config.LowStock.sellBonusPercent or 0
end

debugPrint('Demand module loaded')

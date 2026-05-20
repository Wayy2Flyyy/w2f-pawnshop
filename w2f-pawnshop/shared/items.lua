--- Pawnshop item catalog (ox_inventory item names must match keys).

Items = {
    categories = {
        jewelry = 'Jewelry',
        collectibles = 'Collectibles',
        luxury = 'Luxury',
        art = 'Art',
    },

    catalog = {
        gold_watch = {
            label = 'Gold Watch',
            image = 'gold_watch',
            baseSellPrice = 420,
            buyPrice = 650,
            baseStock = 3,
            loyaltyXp = 12,
            minLoyaltyToBuy = 0,
            category = 'jewelry',
        },
        silver_ring = {
            label = 'Silver Ring',
            image = 'silver_ring',
            baseSellPrice = 95,
            buyPrice = 180,
            baseStock = 8,
            loyaltyXp = 5,
            minLoyaltyToBuy = 0,
            category = 'jewelry',
        },
        diamond_ring = {
            label = 'Diamond Ring',
            image = 'diamond_ring',
            baseSellPrice = 880,
            buyPrice = 1350,
            baseStock = 2,
            loyaltyXp = 25,
            minLoyaltyToBuy = 1,
            category = 'jewelry',
        },
        gold_necklace = {
            label = 'Gold Necklace',
            image = 'gold_necklace',
            baseSellPrice = 540,
            buyPrice = 820,
            baseStock = 4,
            loyaltyXp = 15,
            minLoyaltyToBuy = 0,
            category = 'jewelry',
        },
        old_coin = {
            label = 'Old Coin',
            image = 'old_coin',
            baseSellPrice = 65,
            buyPrice = 140,
            baseStock = 12,
            loyaltyXp = 4,
            minLoyaltyToBuy = 0,
            category = 'collectibles',
        },
        luxury_bracelet = {
            label = 'Luxury Bracelet',
            image = 'luxury_bracelet',
            baseSellPrice = 310,
            buyPrice = 490,
            baseStock = 5,
            loyaltyXp = 10,
            minLoyaltyToBuy = 0,
            category = 'luxury',
        },
        vintage_camera = {
            label = 'Vintage Camera',
            image = 'vintage_camera',
            baseSellPrice = 175,
            buyPrice = 290,
            baseStock = 6,
            loyaltyXp = 7,
            minLoyaltyToBuy = 0,
            category = 'collectibles',
        },
        antique_statue = {
            label = 'Antique Statue',
            image = 'antique_statue',
            baseSellPrice = 720,
            buyPrice = 1100,
            baseStock = 2,
            loyaltyXp = 20,
            minLoyaltyToBuy = 2,
            category = 'art',
        },
        rare_painting = {
            label = 'Rare Painting',
            image = 'rare_painting',
            baseSellPrice = 950,
            buyPrice = 1450,
            baseStock = 1,
            loyaltyXp = 30,
            minLoyaltyToBuy = 3,
            category = 'art',
        },
        designer_bag = {
            label = 'Designer Bag',
            image = 'designer_bag',
            baseSellPrice = 260,
            buyPrice = 410,
            baseStock = 5,
            loyaltyXp = 9,
            minLoyaltyToBuy = 0,
            category = 'luxury',
        },
    },
}

---@param itemName string
---@return table|nil
function Items.Get(itemName)
    if not itemName then return nil end
    return Items.catalog[itemName]
end

---@param itemName string
---@return boolean
function Items.IsSellable(itemName)
    return Items.Get(itemName) ~= nil
end

---@return table<string, table>
function Items.GetCatalog()
    return Items.catalog
end

--- Resolve display image path for NUI.
---@param itemName string
---@return string
function Items.GetImage(itemName)
    local item = Items.Get(itemName)
    local imageName = item and item.image or itemName
    return Config.ItemImagePath:format(imageName)
end

--- Loyalty sell bonus percent (Stage 4+). Returns 0 in Stage 2.
---@param _source number
---@return number bonusPercent
function Items.GetSellBonusPercent(_source)
    if not Loyalty.enabled then
        return 0
    end
    return 0
end

--- Max allowed unit sell price: strictly below buyPrice - margin.
---@param item table
---@return number
function Items.GetMaxUnitSellPrice(item)
    local ceiling = item.buyPrice - Config.MinimumProfitMargin
    return math.max(1, ceiling - 1)
end

--- Server-authoritative unit sell price with margin clamp.
---@param itemName string
---@param source number|nil
---@return number|nil finalPrice
---@return number bonusPercent
function Items.CalculateFinalSellPrice(itemName, source)
    local item = Items.Get(itemName)
    if not item then return nil, 0 end

    local bonusPercent = source and Items.GetSellBonusPercent(source) or 0
    local bonusAmount = math.floor(item.baseSellPrice * (bonusPercent / 100))
    local raw = item.baseSellPrice + bonusAmount
    local maxPrice = Items.GetMaxUnitSellPrice(item)
    local finalPrice = math.min(raw, maxPrice)

    return math.max(1, finalPrice), bonusPercent
end

--- Server-authoritative buy price (discounts in Stage 4+).
---@param itemName string
---@param _source number|nil
---@return number|nil
function Items.CalculateBuyPrice(itemName, _source)
    local item = Items.Get(itemName)
    if not item then return nil end
    return math.max(1, math.floor(item.buyPrice))
end

---@param itemName string
---@param source number|nil
---@return boolean canBuy
---@return boolean lockedByLoyalty
function Items.CanPlayerBuy(itemName, source)
    local item = Items.Get(itemName)
    if not item then return false, false end

    local required = item.minLoyaltyToBuy or 0
    local level = source and Loyalty.GetPlayerLevel(source) or Loyalty.defaultLevel

    if level < required then
        return false, true
    end

    return true, false
end

---@param category string
---@return string
function Items.GetCategoryLabel(category)
    return Items.categories[category] or category or 'General'
end

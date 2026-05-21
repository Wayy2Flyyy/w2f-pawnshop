--- Black market item catalog (ox_inventory names must match keys).

BlackMarket = {
    categories = {
        illicit = 'Illicit',
        tools = 'Tools',
        tech = 'Tech',
        components = 'Components',
    },

    --- Minimum pawnshop loyalty level to access the dealer (Config may override).
    minAccessLevel = 4,

    catalog = {
        dirty_money = {
            label = 'Dirty Money Stack',
            image = 'dirty_money',
            buyPrice = 1200,
            baseStock = 5,
            requiredLoyalty = 4,
            category = 'illicit',
            restockAllowed = true,
            description = 'Unmarked bills — no questions.',
        },
        fake_id = {
            label = 'Forged ID Kit',
            image = 'fake_id',
            buyPrice = 2800,
            baseStock = 3,
            requiredLoyalty = 4,
            category = 'illicit',
            restockAllowed = false,
            description = 'Passes a quick glance, not a lab.',
        },
        stolen_card = {
            label = 'Stolen Payment Card',
            image = 'stolen_card',
            buyPrice = 950,
            baseStock = 6,
            requiredLoyalty = 4,
            category = 'illicit',
            restockAllowed = true,
            description = 'Still active… for now.',
        },
        hacking_usb = {
            label = 'Hacking USB',
            image = 'hacking_usb',
            buyPrice = 3400,
            baseStock = 4,
            requiredLoyalty = 4,
            category = 'tech',
            restockAllowed = false,
            description = 'Preloaded payloads. Use discreetly.',
        },
        lockpick_advanced = {
            label = 'Advanced Lockpick Set',
            image = 'lockpick_advanced',
            buyPrice = 1750,
            baseStock = 5,
            requiredLoyalty = 4,
            category = 'tools',
            restockAllowed = true,
            description = 'Precision tungsten picks.',
        },
        weapon_parts = {
            label = 'Weapon Parts Crate',
            image = 'weapon_parts',
            buyPrice = 4200,
            baseStock = 2,
            requiredLoyalty = 4,
            category = 'components',
            restockAllowed = false,
            description = 'Mixed components. No serials.',
        },
        burner_phone = {
            label = 'Burner Phone',
            image = 'burner_phone',
            buyPrice = 650,
            baseStock = 8,
            requiredLoyalty = 5,
            category = 'tech',
            restockAllowed = true,
            description = 'Clean IMEI, prepaid mindset.',
        },
        encrypted_laptop = {
            label = 'Encrypted Laptop',
            image = 'encrypted_laptop',
            buyPrice = 5800,
            baseStock = 2,
            requiredLoyalty = 5,
            category = 'tech',
            restockAllowed = false,
            description = 'Air-gapped until you need it.',
        },
        marked_bills = {
            label = 'Marked Bills',
            image = 'marked_bills',
            buyPrice = 2100,
            baseStock = 4,
            requiredLoyalty = 5,
            category = 'illicit',
            restockAllowed = true,
            description = 'Traceable — useful for the right job.',
        },
        blackmarket_chip = {
            label = 'Black Market Chip',
            image = 'blackmarket_chip',
            buyPrice = 7500,
            baseStock = 1,
            requiredLoyalty = 5,
            category = 'components',
            restockAllowed = false,
            description = 'Inner circle hardware. One per customer.',
        },
    },
}

---@param itemName string
---@return table|nil
function BlackMarket.Get(itemName)
    if not itemName then return nil end
    return BlackMarket.catalog[itemName]
end

---@param itemName string
---@return boolean
function BlackMarket.IsCatalogItem(itemName)
    return BlackMarket.Get(itemName) ~= nil
end

---@return table<string, table>
function BlackMarket.GetCatalog()
    return BlackMarket.catalog
end

---@param itemName string
---@return string
function BlackMarket.GetImage(itemName)
    local item = BlackMarket.Get(itemName)
    local imageName = item and item.image or itemName
    return Config.ItemImagePath:format(imageName)
end

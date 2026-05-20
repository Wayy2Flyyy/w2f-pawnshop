--- Item catalog and pricing rules (Stage 2+).
--- Stage 1: structure only — no sell/buy logic.

Items = {
    --- Categories for future stock filtering.
    categories = {},

    --- Whitelist/blacklist item names (ox_inventory).
    sellable = {},
    buyable = {},
}

---@param itemName string
---@return boolean
function Items.IsSellable(itemName)
    if not itemName or #Items.sellable == 0 then
        return false
    end
    return Items.sellable[itemName] == true
end

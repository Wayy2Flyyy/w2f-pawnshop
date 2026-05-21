PawnState = {
    blackMarketAccess = false,
    busy = false,
}

--- Sync black market access from server (loyalty level 4+).
function PawnState.SyncBlackMarketAccess()
    local result = lib.callback.await('w2f-pawnshop:canAccessBlackMarket', false)
    if result and result.ok then
        PawnState.blackMarketAccess = result.access == true
    end
    return PawnState.blackMarketAccess
end

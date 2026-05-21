BlackMarketTarget = {
    registered = false,
}

function BlackMarketTarget.Register(ped)
    if BlackMarketTarget.registered or not ped or not DoesEntityExist(ped) then
        return
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'w2f_blackmarket_talk',
            icon = 'fas fa-user-secret',
            label = 'Speak to Black Market Dealer',
            distance = Config.InteractionDistance,
            canInteract = function()
                if Config.BlackMarket.hideTargetBelowLevel then
                    return PawnState.blackMarketAccess
                end
                return true
            end,
            onSelect = function()
                PawnState.SyncBlackMarketAccess()
                PawnNui.OpenBlackMarket()
            end,
        },
    })

    BlackMarketTarget.registered = true
end

function BlackMarketTarget.Remove(ped)
    if not BlackMarketTarget.registered or not ped or not DoesEntityExist(ped) then
        return
    end

    exports.ox_target:removeLocalEntity(ped, { 'w2f_blackmarket_talk' })
    BlackMarketTarget.registered = false
end

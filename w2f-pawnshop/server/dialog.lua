DialogServer = {}

function DialogServer.BuildForPlayer(source)
    local profile = LoyaltyServer.GetProfile(source)
    local tier = profile.tier
    local greeting = tier.greeting or Config.Dialog.ownerName

    local demanded = Demand.GetDemandedList()
    local demandMsg = Demand.BuildDialogMessage(demanded)

    if demandMsg then
        greeting = greeting .. ' ' .. demandMsg
    end

    local blackMarketUnlock = tier.blackMarketUnlock == true
    local blackMarketContact = nil

    if blackMarketUnlock then
        blackMarketContact = Config.BlackMarket.contactMessage
    end

    return greeting, profile, demanded, blackMarketUnlock, blackMarketContact
end

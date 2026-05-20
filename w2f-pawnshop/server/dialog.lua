DialogServer = {}

---@param source number
---@return string greeting
---@return table loyaltyProfile
---@return table demanded
---@return boolean blackMarketUnlock
function DialogServer.BuildForPlayer(source)
    local profile = LoyaltyServer.GetProfile(source)
    local tier = profile.tier
    local greeting = tier.greeting or Config.Dialog.ownerName

    local demanded = Demand.GetDemandedList()
    local demandMsg = Demand.BuildDialogMessage(demanded)

    if demandMsg then
        greeting = greeting .. ' ' .. demandMsg
    end

    return greeting, profile, demanded, tier.blackMarketUnlock == true
end

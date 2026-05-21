--- Server-only framework bridge (money / player resolution).

local ESX, QBCore

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][bridge] %s'):format(table.concat({ ... }, ' ')))
end

local function normalizeAccount(account)
    account = account or Config.DefaultBuyAccount

    if Bridge.name == 'qbox' and (account == 'money' or account == 'cash') then
        return 'cash'
    end

    if Bridge.name == 'esx' and account == 'cash' then
        return 'money'
    end

    return account
end

local function loadFramework()
    Bridge.Init()

    if Bridge.name == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        return
    end

    if Bridge.name == 'qbox' then
        if GetResourceState('qbx_core') == 'started' then
            QBCore = exports.qbx_core
        else
            QBCore = exports['qb-core']:GetCoreObject()
        end
    end
end

function Bridge.GetPlayer(source)
    if not source or source <= 0 then return nil end
    loadFramework()

    if Bridge.name == 'esx' and ESX then
        return ESX.GetPlayerFromId(source)
    end

    if Bridge.name == 'qbox' then
        if QBCore and QBCore.GetPlayer then
            return QBCore:GetPlayer(source)
        end
        if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
            return QBCore.Functions.GetPlayer(source)
        end
    end

    return nil
end

function Bridge.GetIdentifier(source)
    local player = Bridge.GetPlayer(source)
    if not player then return nil end

    if Bridge.name == 'esx' then
        return player.identifier
    end

    if Bridge.name == 'qbox' then
        return player.PlayerData and player.PlayerData.citizenid
    end

    return nil
end

---@param source number
---@param account string|nil
---@return number
function Bridge.GetMoney(source, account)
    local player = Bridge.GetPlayer(source)
    if not player then return 0 end

    account = normalizeAccount(account or Config.DefaultBuyAccount)

    if Bridge.name == 'esx' then
        if account == 'money' then
            return player.getMoney() or 0
        end
        local acc = player.getAccount(account)
        return acc and acc.money or 0
    end

    if Bridge.name == 'qbox' then
        return player.Functions.GetMoney(account) or 0
    end

    return 0
end

function Bridge.AddMoney(source, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(source)
    if not player then
        debugPrint('AddMoney failed — no player', source)
        return false
    end

    account = normalizeAccount(account or Config.DefaultSellAccount)

    if Bridge.name == 'esx' then
        if account == 'money' then
            player.addMoney(amount)
        else
            player.addAccountMoney(account, amount)
        end
        return true
    end

    if Bridge.name == 'qbox' then
        return player.Functions.AddMoney(account, amount, 'w2f-pawnshop-sell')
    end

    debugPrint('AddMoney skipped — no framework')
    return false
end

function Bridge.RemoveMoney(source, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(source)
    if not player then return false end

    account = normalizeAccount(account or Config.DefaultBuyAccount)

    if Bridge.name == 'esx' then
        if account == 'money' then
            if player.getMoney() < amount then return false end
            player.removeMoney(amount)
        else
            local acc = player.getAccount(account)
            if not acc or acc.money < amount then return false end
            player.removeAccountMoney(account, amount)
        end
        return true
    end

    if Bridge.name == 'qbox' then
        return player.Functions.RemoveMoney(account, amount, 'w2f-pawnshop-buy')
    end

    return false
end

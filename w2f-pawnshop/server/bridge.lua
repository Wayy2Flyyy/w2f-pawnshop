--- Server-only framework bridge (money / player resolution).

local ESX, QBCore

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][bridge] %s'):format(table.concat({ ... }, ' ')))
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

---@param source number
---@return table|nil
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

---@param source number
---@return string|nil
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
---@param account string
---@param amount number
---@return boolean
function Bridge.AddMoney(source, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(source)
    if not player then
        debugPrint('AddMoney failed — no player', source)
        return false
    end

    account = account or Config.SellPaymentAccount

    if Bridge.name == 'esx' then
        if account == 'cash' or account == 'money' then
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

---@param source number
---@param account string
---@param amount number
---@return boolean
function Bridge.RemoveMoney(source, account, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(source)
    if not player then return false end

    account = account or Config.SellPaymentAccount

    if Bridge.name == 'esx' then
        if account == 'cash' or account == 'money' then
            if player.getMoney() < amount then return false end
            player.removeMoney(amount)
        else
            if player.getAccount(account).money < amount then return false end
            player.removeAccountMoney(account, amount)
        end
        return true
    end

    if Bridge.name == 'qbox' then
        return player.Functions.RemoveMoney(account, amount, 'w2f-pawnshop')
    end

    return false
end

local ESX, QBX, QBCore
local Framework = W2F.Framework

local function normalizeAccount(account)
    account = account or Config.DefaultBuyAccount or 'money'
    local fw = Framework.GetName()

    if fw == 'qbox' or fw == 'qbcore' then
        if account == 'money' then return 'cash' end
        return account
    end

    if fw == 'esx' then
        if account == 'cash' then return 'money' end
        return account
    end

    return account
end

local function getQBPlayer(source)
    if Framework.IsQbox() then
        QBX = QBX or exports.qbx_core
        if QBX and QBX.GetPlayer then return QBX:GetPlayer(source) end
    else
        QBCore = QBCore or exports['qb-core']:GetCoreObject()
        if QBCore and QBCore.Functions and QBCore.Functions.GetPlayer then
            return QBCore.Functions.GetPlayer(source)
        end
    end
end

function Framework.GetPlayer(source)
    if not source or source <= 0 then return nil end
    if Framework.IsESX() then
        ESX = ESX or exports['es_extended']:getSharedObject()
        return ESX and ESX.GetPlayerFromId(source) or nil
    elseif Framework.IsQBFamily() then
        return getQBPlayer(source)
    end
    return nil
end

function Framework.GetCitizenId(source)
    local p = Framework.GetPlayer(source)
    if not p then return nil end
    if Framework.IsQBFamily() then return p.PlayerData and p.PlayerData.citizenid end
    return nil
end

function Framework.GetIdentifier(source)
    local p = Framework.GetPlayer(source)
    if not p then return nil end
    if Framework.IsESX() then return p.identifier end
    return Framework.GetCitizenId(source) or GetPlayerIdentifierByType(source, 'license') or GetPlayerIdentifier(source, 0)
end

function Framework.GetMoney(source, account)
    local p = Framework.GetPlayer(source)
    if not p then return 0 end
    account = normalizeAccount(account)
    if Framework.IsESX() then
        if account == 'money' then return p.getMoney() or 0 end
        local acc = p.getAccount(account)
        return acc and acc.money or 0
    end
    return p.Functions.GetMoney(account) or 0
end

function Framework.AddMoney(source, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0); if amount <= 0 then return false end
    local p = Framework.GetPlayer(source); if not p then return false end
    account = normalizeAccount(account)
    if Framework.IsESX() then
        if account == 'money' then p.addMoney(amount) else p.addAccountMoney(account, amount) end
        return true
    end
    return p.Functions.AddMoney(account, amount, reason or 'w2f-pawnshop')
end

function Framework.RemoveMoney(source, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0); if amount <= 0 then return false end
    local p = Framework.GetPlayer(source); if not p then return false end
    account = normalizeAccount(account)
    if Framework.IsESX() then
        if account == 'money' then if p.getMoney() < amount then return false end; p.removeMoney(amount)
        else local acc=p.getAccount(account); if not acc or acc.money < amount then return false end; p.removeAccountMoney(account, amount) end
        return true
    end
    return p.Functions.RemoveMoney(account, amount, reason or 'w2f-pawnshop')
end

Bridge = Bridge or {}
Bridge.GetPlayer = Framework.GetPlayer
Bridge.GetIdentifier = Framework.GetIdentifier
Bridge.GetMoney = Framework.GetMoney
Bridge.AddMoney = Framework.AddMoney
Bridge.RemoveMoney = Framework.RemoveMoney

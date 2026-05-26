local Framework = W2F.Framework

function Framework.GetPlayerData()
    return LocalPlayer and LocalPlayer.state or {}
end

function Framework.Notify(message, nType)
    if lib and lib.notify then
        lib.notify({ description = message, type = nType or 'inform' })
    end
end

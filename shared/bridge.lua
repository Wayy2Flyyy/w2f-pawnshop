-- Backward compatibility wrapper. New framework bridge lives in shared/framework.lua.
Bridge = Bridge or {}

function Bridge.Init()
    return W2F.Framework.Detect()
end

function Bridge.IsFramework()
    return W2F.Framework.IsQBFamily() or W2F.Framework.IsESX()
end

function Bridge.GetPlayerId(source)
    if IsDuplicityVersion() then return source end
    return cache and cache.playerId or PlayerId()
end

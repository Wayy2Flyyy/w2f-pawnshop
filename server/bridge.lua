-- Backward compatibility wrapper. New framework bridge lives in server/framework.lua.
Bridge = Bridge or {}
Bridge.GetPlayer = W2F.Framework.GetPlayer
Bridge.GetIdentifier = W2F.Framework.GetIdentifier
Bridge.GetMoney = W2F.Framework.GetMoney
Bridge.AddMoney = W2F.Framework.AddMoney
Bridge.RemoveMoney = W2F.Framework.RemoveMoney

--- Debug logging helper (client + server).

Dbg = {}

---@param tag string
---@vararg any
function Dbg.Print(tag, ...)
    if not Config or not Config.Debug then return end
    local parts = { ... }
    for i = 1, #parts do
        parts[i] = tostring(parts[i])
    end
    print(('[w2f-pawnshop][%s] %s'):format(tag or 'core', table.concat(parts, ' ')))
end

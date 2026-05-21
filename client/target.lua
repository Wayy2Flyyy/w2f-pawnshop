PawnTarget = {
    registered = false,
}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][target] %s'):format(table.concat({ ... }, ' ')))
end

--- Register ox_target on the pawnshop owner ped.
function PawnTarget.Register(ped)
    if PawnTarget.registered or not ped or not DoesEntityExist(ped) then
        return
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'w2f_pawnshop_talk',
            icon = 'fas fa-handshake',
            label = 'Talk to Pawnshop Owner',
            distance = Config.InteractionDistance,
            onSelect = function()
                PawnNui.OpenDialog()
            end,
        },
    })

    PawnTarget.registered = true
    debugPrint('ox_target registered on ped', ped)
end

--- Remove target when resource stops.
function PawnTarget.Remove(ped)
    if not PawnTarget.registered or not ped or not DoesEntityExist(ped) then
        return
    end

    exports.ox_target:removeLocalEntity(ped, { 'w2f_pawnshop_talk' })
    PawnTarget.registered = false
end

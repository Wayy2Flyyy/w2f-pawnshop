Database = {
    ready = false,
}

--- Load SQL schema when enabled (Stage 2+).
function Database.Init()
    if Database.ready then return end
    Database.ready = true
    -- install.sql will be executed manually or via migration in a later stage.
end

Database = {
    ready = false,
}

local function debugPrint(...)
    if not Config.Debug then return end
    print(('[w2f-pawnshop][database] %s'):format(table.concat({ ... }, ' ')))
end

local function runSqlFile()
    local resource = GetCurrentResourceName()
    local sql = LoadResourceFile(resource, 'sql/install.sql')
    if not sql or sql == '' then
        debugPrint('install.sql missing')
        return false
    end

    for statement in sql:gmatch('[^;]+') do
        local trimmed = statement:gsub('^%s+', ''):gsub('%s+$', '')
        if trimmed ~= '' and not trimmed:match('^%-%-') then
            MySQL.query.await(trimmed)
        end
    end

    return true
end

function Database.Init()
    if Database.ready then return end

    CreateThread(function()
        while GetResourceState('oxmysql') ~= 'started' do
            Wait(200)
        end

        local ok, err = pcall(runSqlFile)
        if not ok then
            print(('[w2f-pawnshop] Database init failed: %s'):format(err))
            return
        end

        Database.ready = true
        Stock.EnsureAll()
        debugPrint('Schema ready')
    end)
end

function Database.IsReady()
    return Database.ready
end

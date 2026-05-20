fx_version 'cerulean'
game 'gta5'

name 'w2f-pawnshop'
author 'W2F'
description 'Realistic NPC-owned dynamic pawnshop'
version '0.4.0'

lua54 'yes'

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/bridge.lua',
    'shared/items.lua',
    'shared/loyalty.lua',
}

client_scripts {
    'client/main.lua',
    'client/ped.lua',
    'client/target.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/database.lua',
    'server/stock.lua',
    'server/loyalty.lua',
    'server/demand.lua',
    'server/dialog.lua',
    'server/pricing.lua',
    'server/transactions.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/storefront.js',
}

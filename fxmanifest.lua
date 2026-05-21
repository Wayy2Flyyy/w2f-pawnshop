fx_version 'cerulean'
game 'gta5'

name 'w2f-pawnshop'
author 'W2F'
description 'Realistic NPC-owned dynamic pawnshop with loyalty and black market'
version '0.5.0'

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
    'shared/debug.lua',
    'shared/bridge.lua',
    'shared/items.lua',
    'shared/loyalty.lua',
    'shared/blackmarket.lua',
}

client_scripts {
    'client/notify.lua',
    'client/state.lua',
    'client/ped.lua',
    'client/target.lua',
    'client/blackmarket_ped.lua',
    'client/blackmarket_target.lua',
    'client/nui.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/security.lua',
    'server/notify.lua',
    'server/bridge.lua',
    'server/database.lua',
    'server/stock.lua',
    'server/blackmarket_stock.lua',
    'server/loyalty.lua',
    'server/demand.lua',
    'server/dialog.lua',
    'server/pricing.lua',
    'server/blackmarket.lua',
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

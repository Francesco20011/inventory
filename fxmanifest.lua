fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'minimal_inventory'
description 'Simple F2 inventory built from scratch'

shared_script '@ox_lib/init.lua'
dependencies {
    'ox_lib',
}

-- Serve the NUI from the compiled build directory.
ui_page 'web/build/index.html'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'web/build/index.html',
    'web/build/style.css',
    'web/build/script.js',
    'web/build/assets/nuran.css'
}
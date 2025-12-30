
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
this_is_a_map 'yes'
author 'KevinGirardx'
lua54 'yes'
game 'gta5'

files {
    'utils/client.lua',
    'utils/server.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
}

client_scripts {
	'client/*.lua',
}

ox_libs {
	'math',
}

server_scripts {
	'server/*.lua',
}
fx_version 'cerulean'
game 'gta5'

author 'Sobing4413'
description 'Admin Menu'

ui_page "nui/index.html"

shared_scripts {
    'shared/sh_framework.lua',
    'shared/sh_config.lua',
    'locale.lua',
    'locales/en.lua', -- Change this to your desired language.
}

client_scripts {
    'client/**/cl_*.lua',
    'shared/sh_commands.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**/sv_*.lua',
}

files {
    "nui/index.html",
    "nui/js/**.js",
    "nui/css/**.css",
    "nui/webfonts/*.css",
    "nui/webfonts/*.otf",
    "nui/webfonts/*.ttf",
    "nui/webfonts/*.woff2",
}

exports {
    'CreateLog',
    'ToggleDev',
}

server_exports {
    'CreateLog'
} 

dependencies {
    'oxmysql'
}

lua54 'yes'
fx_version "bodacious"
games {"gta5"}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    "config.lua",
    "server/utils.lua",
    "server/server.lua"
}
client_scripts {
    "config.lua",
    "client/utils.lua",
    "client/client.lua"
}

ui_page('html/ui.html')

files {
  'html/ui.html',
  'html/js/script.js',
  'html/css/style.css',
  'html/img/digital.ttf'
}
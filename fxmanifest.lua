fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

name 'smoke_utillitruck'
description 'SpawnCode: utillitruck'
repository 'https://github.com/BigSmoKe07/smoke_drawbridge'
version '1.0.0'
author 'BigSmoKe07'

files {
    "data/*.meta",
}

shared_scripts {
    '@ox_lib/init.lua',
}

data_file "VEHICLE_METADATA_FILE" "data/vehicles.meta"
data_file "CARCOLS_FILE" "data/carcols.meta"
data_file "VEHICLE_VARIATION_FILE" "data/carvariations.meta"

client_script "client.lua"
server_script "server.lua"
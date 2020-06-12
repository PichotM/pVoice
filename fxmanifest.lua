resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

client_scripts {
	'@pichot_core/sh_core.lua',
	'@pichot_core/cl_core.lua',
	'@pichot_core/cl_players.lua',
	'sh_config.lua',
	'cl_voice.lua',
	'cl_radio.lua',
	'cl_audio.lua'
}

server_scripts {
	'@pichot_core/sh_core.lua',
	"@pichot_core/sv_core.lua",
	'sh_config.lua',
	'sv_voice.lua'
}

game { 'gta5' }

fx_version 'adamant'
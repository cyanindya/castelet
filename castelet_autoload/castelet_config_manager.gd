# The node that holds configuration data of the game during runtime.
# Throw the save/load/data management in the castelet_config_data instead.

# Configuration is comprised of several subcategories:
# - Display configs (window, resolution)
# - Text and dialogue display
# - Audio
# - Input control

extends Node
class_name CasteletConfigManager

enum ConfigList {
	# Display Settings
	WINDOW_MODE,
	WINDOW_RESOLUTION,

	# Dialogue Settings
	TEXT_SPEED,
	AUTOMODE_TIMEOUT,
	FORCE_STOP_FFWD_ON_CHOICE,
	CONTINUE_FFWD_ON_CHOICE,
	
	# Audio Settings
	MASTER_VOLUME,
	BGM_VOLUME,
	SFX_VOLUME,
	VOICE_VOLUME,
	MASTER_MUTE,
	BGM_MUTE,
	SFX_MUTE,
	VOICE_MUTE
}
enum WindowMode {WINDOWED, FULLSCREEN, BORDERLESS}
enum WindowResolutions {
	RES_1280_720,
	RES_1366_768,
	RES_1600_900,
	RES_1920_1080,
}

# Display config
@export var _window_mode = WindowMode.FULLSCREEN
@export var _window_resolution = WindowResolutions.RES_1280_720

# Text and dialogue config
@export var _base_text_speed : float = 30
@export var _base_automode_timeout : float = 3
@export var default_dialogue_box : StyleBoxTexture
@export var default_speaker_box : StyleBoxTexture

# A configuration that forces the player to stay on choice screen until
# a choice is made. Otherwise, "default" choice or previously-given choice
# is automatically selected.
@export var _forcibly_stop_ffwd_on_choices := true

# After choice is made, configure whether the skipping mode will resume
# or will be stopped.
@export var _continue_ffwd_after_choices := false


# Audio config
@export var _base_master_volume : float = 50
@export var _base_bgm_volume : float = 50
@export var _base_sfx_volume : float = 50
@export var _base_voice_volume : float = 50
var _master_mute := false
var _bgm_mute := false
var _sfx_mute := false
var _voice_mute := false


const _config_name_map = {
	ConfigList.WINDOW_MODE : {
		"field_name" : "_window_mode",
		"type" : WindowMode,
	},
	ConfigList.TEXT_SPEED : {
		"field_name" : "_base_text_speed",
		"type" : TYPE_FLOAT,
	},
	ConfigList.AUTOMODE_TIMEOUT : {
		"field_name" : "_base_automode_timeout",
		"type" : TYPE_FLOAT,
	},
	ConfigList.FORCE_STOP_FFWD_ON_CHOICE : {
		"field_name" : "_forcibly_stop_ffwd_on_choices",
		"type" : TYPE_BOOL,
	},
	ConfigList.CONTINUE_FFWD_ON_CHOICE : {
		"field_name" : "_continue_ffwd_after_choices",
		"type" : TYPE_BOOL,
	},
	ConfigList.MASTER_VOLUME : {
		"field_name" : "_base_master_volume",
		"type" : TYPE_FLOAT,
	},
	ConfigList.MASTER_MUTE : {
		"field_name" : "_master_mute",
		"type" : TYPE_BOOL,
	},
	ConfigList.BGM_VOLUME : {
		"field_name" : "_base_bgm_volume",
		"type" : TYPE_FLOAT,
	},
	ConfigList.BGM_MUTE : {
		"field_name" : "_bgm_mute",
		"type" : TYPE_BOOL,
	},
	ConfigList.SFX_VOLUME : {
		"field_name" : "_base_sfx_volume",
		"type" : TYPE_FLOAT,
	},
	ConfigList.SFX_MUTE : {
		"field_name" : "_sfx_mute",
		"type" : TYPE_BOOL,
	},
	ConfigList.VOICE_VOLUME : {
		"field_name" : "_base_voice_volume",
		"type" : TYPE_FLOAT,
	},
	ConfigList.VOICE_MUTE : {
		"field_name" : "_voice_mute",
		"type" : TYPE_BOOL,
	},
}

const _window_resolution_map = {
	WindowResolutions.RES_1280_720 : {
		"resolution" : [1280, 720],
	},
	WindowResolutions.RES_1366_768 : {
		"resolution" : [1366, 768],
	},
	WindowResolutions.RES_1600_900 : {
		"resolution" : [1600, 900],
	},
	WindowResolutions.RES_1920_1080 : {
		"resolution" : [1920, 1080],
	},
}

signal config_updated(config_name, value)
signal config_finalized()


func _ready() -> void:
	# print_debug(_config_name_map.keys())
	pass


func set_config(conf : int, value : Variant) -> void:
	set(_config_name_map[conf]["field_name"], value)

	# It is possible that the set_config is run in a separate
	# thread (e.g. the config loading thread), so we use deferred
	# signal to ensure it will only be emitted after whatever the
	# business in the calling thread is completed.
	config_updated.emit.call_deferred(conf, value)


func get_config(conf : int):
	if not _config_name_map.has(conf):
		return null
	
	var result = get(_config_name_map[conf]["field_name"])
	
	if result != null:
		return result
	
	return null
	

func finalize_config():
	config_finalized.emit()

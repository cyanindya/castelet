# The node that holds configuration data of the game during runtime.
# Throw the save/load/data management in the castelet_config_data instead.

# Configuration is comprised of several subcategories:
# - Window display
# - Text and dialogue display
# - Audio
# - Input control

extends Node

enum {
	WINDOW_MODE,
	TEXT_SPEED,
	AUTOMODE_TIMEOUT,
	FORCE_STOP_FFWD_ON_CHOICE,
	CONTINUE_FFWD_ON_CHOICE,
}
enum WindowMode {WINDOWED, FULLSCREEN, BORDERLESS}


# Text and dialogue config
@export var _window_mode = WindowMode.FULLSCREEN
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

const _config_name_map = {
	WINDOW_MODE : {
		"field_name" : "_window_mode",
		"type" : WindowMode,
	},
	TEXT_SPEED : {
		"field_name" : "_base_text_speed",
		"type" : TYPE_FLOAT,
	},
	AUTOMODE_TIMEOUT : {
		"field_name" : "_base_automode_timeout",
		"type" : TYPE_FLOAT,
	},
	FORCE_STOP_FFWD_ON_CHOICE : {
		"field_name" : "_forcibly_stop_ffwd_on_choices",
		"type" : TYPE_BOOL,
	},
	CONTINUE_FFWD_ON_CHOICE : {
		"field_name" : "_continue_ffwd_after_choices",
		"type" : TYPE_BOOL,
	},
}

signal config_updated(config_name, value)


func set_config(conf, value : Variant):
	set(_config_name_map[conf]["field_name"], value)
	config_updated.emit(conf, value)


func get_config(conf):
	var result = get(_config_name_map[conf]["field_name"])
	
	if result != null:
		return result
	
	return null
	
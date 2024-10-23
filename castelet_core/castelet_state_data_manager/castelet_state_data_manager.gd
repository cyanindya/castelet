extends Node


const ConfigFileManager = preload("castelet_config_data.gd")
const PersistentFileManager = preload("castelet_persistent_data.gd")

var conf_manager : ConfigFileManager
var persistent_manager : PersistentFileManager

signal request_save_config
signal request_load_config

func _ready() -> void:
	conf_manager = ConfigFileManager.new()
	persistent_manager = PersistentFileManager.new()

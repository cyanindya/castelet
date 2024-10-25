extends Node


const ConfigFileManager = preload("castelet_config_data.gd")
const PersistentFileManager = preload("castelet_persistent_data.gd")

var conf_manager : ConfigFileManager
var persistent_manager : PersistentFileManager


func _ready() -> void:
	conf_manager = ConfigFileManager.new()
	persistent_manager = PersistentFileManager.new()

	CasteletConfig.config_finalized.connect(_on_config_finalized)
	conf_manager.load_config_file()


func _on_config_finalized():
	conf_manager.save_config_file()

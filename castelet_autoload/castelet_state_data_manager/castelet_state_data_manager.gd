extends Node


const ConfigFileManager = preload("castelet_config_data.gd")
const PersistentFileManager = preload("castelet_persistent_data.gd")

var conf_manager : ConfigFileManager
var persistent_manager : PersistentFileManager


func _ready() -> void:
	conf_manager = ConfigFileManager.new()
	persistent_manager = PersistentFileManager.new()

	CasteletConfig.config_finalized.connect(_on_config_finalized)
	conf_manager.load_config_start.connect(_on_load_config_start)
	conf_manager.load_config_finish.connect(_on_load_config_finish)
	conf_manager.initialize_threads()
	conf_manager.load_config_file()


func _exit_tree() -> void:
	# Make sure to dispose all threads related to state data management
	# upon quitting
	conf_manager.dispose_threads()


func _on_config_finalized():
	conf_manager.save_config_file()


func _on_load_config_start():
	print_debug("Loading config...")


func _on_load_config_finish():
	print_debug("Config loaded")

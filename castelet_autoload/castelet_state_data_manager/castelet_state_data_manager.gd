extends Node


const ConfigFileManager = preload("castelet_config_file_handler.gd")
const PersistentFileManager = preload("castelet_persistent_file_handler.gd")

var conf_manager : ConfigFileManager
var persistent_manager : PersistentFileManager


func _ready() -> void:
	conf_manager = ConfigFileManager.new()
	persistent_manager = PersistentFileManager.new()

	CasteletConfig.config_finalized.connect(_on_config_finalized)
	conf_manager.save_start.connect(_on_save_config_start)
	conf_manager.save_finish.connect(_on_save_config_finish)
	conf_manager.load_start.connect(_on_load_config_start)
	conf_manager.load_finish.connect(_on_load_config_finish)
	conf_manager.init_threads()
	conf_manager.load_file()

	CasteletGameManager.request_load_persistent.connect(_on_request_load_persistent)
	CasteletGameManager.request_save_persistent.connect(_on_request_save_persistent)
	persistent_manager.save_start.connect(_on_save_persistent_start)
	persistent_manager.save_finish.connect(_on_save_persistent_finish)
	persistent_manager.load_start.connect(_on_load_persistent_start)
	persistent_manager.load_finish.connect(_on_load_persistent_finish)
	persistent_manager.init_threads()
	persistent_manager.load_file()


func _exit_tree() -> void:
	# Make sure to dispose all threads related to state data management
	# upon quitting
	conf_manager.join_threads()
	persistent_manager.join_threads()


func _on_config_finalized():
	conf_manager.save_file()


func _on_save_config_start():
	print_debug("Saving config...")


func _on_save_config_finish():
	print_debug("Config saved.")


func _on_load_config_start():
	print_debug("Loading config...")


func _on_load_config_finish():
	print_debug("Config loaded.")


func _on_request_load_persistent():
	persistent_manager.load_file()


func _on_request_save_persistent():
	persistent_manager.save_file()


func _on_save_persistent_start():
	print_debug("Saving persistent file...")
	pass


func _on_save_persistent_finish():
	print_debug("Saving persistent file completed.")
	CasteletGameManager.save_persistent_completed.emit()


func _on_load_persistent_start():
	print_debug("Loading persistent file...")


func _on_load_persistent_finish():
	print_debug("Loading persistent file completed.")
	CasteletGameManager.load_persistent_completed.emit()

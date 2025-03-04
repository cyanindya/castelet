extends Node
class_name CasteletStateManager

const ConfigFileManager = preload("castelet_config_file_handler.gd")
const PersistentFileManager = preload("castelet_persistent_file_handler.gd")
# const GameSaveLoadManager = preload("castelet_game_save_load_handler.gd")

var _conf_file_manager : ConfigFileManager
var _persistent_manager : PersistentFileManager
# var _saveload_manager : GameSaveLoadManager


@onready var _game_manager : CasteletGameManager = get_node("/root/CasteletGameManager")
@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")

signal config_save_start
signal config_save_finish
signal config_load_start
signal config_load_finish
signal persistent_save_start
signal persistent_save_finish
signal persistent_load_start
signal persistent_load_finish
signal game_save_start
signal game_save_finish
signal game_load_start
signal game_load_finish


func _ready() -> void:
	_conf_file_manager = ConfigFileManager.new()
	_persistent_manager = PersistentFileManager.new()

	_config_manager.config_finalized.connect(_on_config_finalized)
	_conf_file_manager.set_config_manager(_config_manager)
	_conf_file_manager.save_start.connect(_on_save_config_start)
	_conf_file_manager.save_finish.connect(_on_save_config_finish)
	_conf_file_manager.load_start.connect(_on_load_config_start)
	_conf_file_manager.load_finish.connect(_on_load_config_finish)
	_conf_file_manager.init_threads()
	_conf_file_manager.load_file()

	_persistent_manager.set_game_manager(_game_manager)
	_persistent_manager.save_start.connect(_on_save_persistent_start)
	_persistent_manager.save_finish.connect(_on_save_persistent_finish)
	_persistent_manager.load_start.connect(_on_load_persistent_start)
	_persistent_manager.load_finish.connect(_on_load_persistent_finish)
	_persistent_manager.init_threads()
	_persistent_manager.load_file()


func _exit_tree() -> void:
	# Make sure to dispose all threads related to state data management
	# upon quitting
	_conf_file_manager.join_threads()
	_persistent_manager.join_threads()


func _on_config_finalized():
	_conf_file_manager.save_file()
	await config_save_finish


func _on_save_config_start():
	print_debug("Saving config...")
	config_save_start.emit()


func _on_save_config_finish():
	print_debug("Config saved.")
	config_save_finish.emit()


func _on_load_config_start():
	print_debug("Loading config...")
	config_load_start.emit()


func _on_load_config_finish():
	print_debug("Config loaded.")
	config_load_finish.emit()


func load_persistent():
	_persistent_manager.load_file()
	await persistent_load_finish


func save_persistent():
	_persistent_manager.save_file()
	await persistent_save_finish


func _on_save_persistent_start():
	print_debug("Saving persistent file...")
	persistent_save_start.emit()


func _on_save_persistent_finish():
	print_debug("Saving persistent file completed.")
	persistent_save_finish.emit()


func _on_load_persistent_start():
	print_debug("Loading persistent file...")
	persistent_load_start.emit()


func _on_load_persistent_finish():
	print_debug("Loading persistent file completed.")
	persistent_load_finish.emit()


# func load_game_data():
# 	_saveload_manager.load_file()
# 	await game_load_finish


# func save_game_data():
# 	_saveload_manager.save_file()
# 	await game_save_finish


# func _on_save_game_start():
# 	print_debug("Saving game file...")
# 	game_save_start.emit()


# func _on_save_game_finish():
# 	print_debug("Saving game completed.")
# 	game_save_finish.emit()


# func _on_load_game_start():
# 	print_debug("Loading game file...")
# 	game_load_start.emit()


# func _on_load_game_finish():
# 	print_debug("Loading game completed.")
# 	game_load_finish.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_persistent()
		await _persistent_manager.save_finish

		# Give time for persistent data to finish saving
		var timer = Timer.new()
		timer.wait_time = 1
		timer.autostart = true
		await timer.timeout

		get_tree().quit()

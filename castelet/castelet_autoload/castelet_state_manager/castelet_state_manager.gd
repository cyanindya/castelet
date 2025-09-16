extends Node
class_name CasteletStateManager

const ConfigFileManager = preload("castelet_config_file_handler.gd")
const PersistentFileManager = preload("castelet_persistent_file_handler.gd")
const GameSaveLoadManager = preload("castelet_game_save_load_handler.gd")

var _conf_file_manager : ConfigFileManager
var _persistent_manager : PersistentFileManager
var _saveload_manager : GameSaveLoadManager
var game_data_dir = "user://saves/"
var game_data_ext = ".sav"


@onready var _game_manager : CasteletGameManager = get_node("/root/CasteletGameManager")
@onready var _theater_manager : CasteletTheaterStateManager = get_node("/root/CasteletTheaterStateManager")
@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")


signal config_save_start
signal config_save_finish(status : int)
signal config_load_start
signal config_load_finish(status : int)

signal persistent_save_start
signal persistent_save_finish(status : int)
signal persistent_load_start
signal persistent_load_finish(status : int)

signal game_save_start
signal game_save_finish(status : int)
signal game_load_start
signal game_load_finish(status : int)
signal peek_game_data_start
signal peek_game_data_finish(status : int, result : Dictionary)


func _ready() -> void:

	if not DirAccess.dir_exists_absolute(game_data_dir):
		DirAccess.make_dir_absolute(game_data_dir)

	_conf_file_manager = ConfigFileManager.new()
	_persistent_manager = PersistentFileManager.new()
	_saveload_manager = GameSaveLoadManager.new()

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

	_saveload_manager.set_game_manager(_game_manager)
	_saveload_manager.set_theater_manager(_theater_manager)
	_saveload_manager.save_start.connect(_on_save_game_start)
	_saveload_manager.save_finish.connect(_on_save_game_finish)
	_saveload_manager.load_start.connect(_on_load_game_start)
	_saveload_manager.load_finish.connect(_on_load_game_finish)
	_saveload_manager.init_threads()
	_saveload_manager.load_file()


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


func _on_save_config_finish(status : int):
	print_debug("Config saved.")
	config_save_finish.emit(status)


func _on_load_config_start():
	print_debug("Loading config...")
	config_load_start.emit()


func _on_load_config_finish(status : int):
	print_debug("Config loaded.")
	config_load_finish.emit(status)


func load_persistent():
	_persistent_manager.load_file()
	await persistent_load_finish


func save_persistent():
	_persistent_manager.save_file()
	await persistent_save_finish


func _on_save_persistent_start():
	print_debug("Saving persistent file...")
	persistent_save_start.emit()


func _on_save_persistent_finish(status : int):
	print_debug("Saving persistent file completed.")
	persistent_save_finish.emit(status)


func _on_load_persistent_start():
	print_debug("Loading persistent file...")
	persistent_load_start.emit()


func _on_load_persistent_finish(status : int):
	print_debug("Loading persistent file completed.")
	persistent_load_finish.emit(status)


func save_game_data(filename : String):
	_saveload_manager.set_save_file_name(game_data_dir + filename + game_data_ext)
	_saveload_manager.save_file()
	await game_save_finish


func load_game_data(filename : String):
	_saveload_manager.set_save_file_name(game_data_dir + filename + game_data_ext)
	_saveload_manager.set_peek(false)
	_saveload_manager.load_file()
	await game_load_finish


func peek_game_data(filename : String):
	_saveload_manager.set_save_file_name(game_data_dir + filename + game_data_ext)
	_saveload_manager.set_peek(true)
	_saveload_manager.load_file()
	await peek_game_data_finish


func _on_save_game_start():
	print_debug("Saving game file...")
	game_save_start.emit()


func _on_save_game_finish(status : int):
	print_debug("Saving game completed.")
	game_save_finish.emit(status)


func _on_load_game_start():
	print_debug("Loading game file...")
	game_load_start.emit()


func _on_load_game_finish(status : int):
	print_debug("Loading game completed.")
	if _saveload_manager.is_peeking():
		peek_game_data_finish.emit(status, _saveload_manager.get_peek_result())
	else:
		game_load_finish.emit(status)
	_saveload_manager.set_peek(false)


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

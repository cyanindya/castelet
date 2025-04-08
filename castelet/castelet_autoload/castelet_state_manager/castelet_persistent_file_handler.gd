extends CasteletBaseSaveLoadHandler


var _game_manager : CasteletGameManager


func _init() -> void:
	save_file_name = "user://persistent.sav"


func set_game_manager(obj : CasteletGameManager):
	_game_manager = obj


func _save_thread_subprocess():
	var file = FileAccess.open(save_file_name, FileAccess.WRITE)

	for persistent_data in _game_manager.get_all_variables(true):
		var value = _game_manager.get_variable(persistent_data, true)
		file.store_var(persistent_data)
		file.store_var("=")
		file.store_var(value)
		file.store_var("\n")
		# file.store_pascal_string(persistent_data)
		# file.store_pascal_string("=")
		# file.store_var(value)
		# file.store_pascal_string("\n")

	file.close()


func _load_thread_subprocess():
	var file = FileAccess.open(save_file_name, FileAccess.READ)
	_mutex.unlock()

	if file == null:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration instead."
		)
		return

	_mutex.lock()
	while file.get_position() < file.get_length():
		var key = file.get_var()
		file.get_var()
		var val = file.get_var()
		file.get_var()
		_game_manager.set_variable(key, val, true)
	
	file.close()

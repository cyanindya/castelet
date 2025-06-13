extends CasteletBaseSaveLoadHandler

var game_data_dir = "user://saves/"
var _game_manager : CasteletGameManager
var _theater_manager : CasteletTheaterStateManager


func set_game_manager(obj : CasteletGameManager):
	_game_manager = obj


func set_theater_manager(obj : CasteletTheaterStateManager):
	_theater_manager = obj


func set_save_file_name(filename: String):
	_save_file_name = filename


# Saving sub-process for the game.
# The following data are saved when the game data is saved:
	# Save data name
	# Last update date of the save data
	# Screenshot/thumbnail of the game
	# Game session variables
	# Current script data (which script is active, context level, etc)
	# Currently active props 
# This can be extended later depending on the game's context.
func _save_thread_subprocess():
	var file = FileAccess.open(_save_file_name, FileAccess.WRITE)

	# Save name
	file.store_var("name")
	file.store_var("=")
	file.store_var(_save_file_name.split(".")[0])
	file.store_var("\n")

	# Save date
	var save_time = Time.get_date_string_from_system()
	file.store_var("last_updated")
	file.store_var("=")
	file.store_var(save_time)
	file.store_var("\n")

	# Thumbnail
	# file.store_var("img")
	# file.store_var("=")
	# file.store_var()
	# file.store_var("\n")

	# Game session variables
	for game_var in _game_manager.get_all_variables():
		# print_debug(persistent_data)
		var value = _game_manager.get_variable(game_var)
		file.store_var("var_" + game_var)
		file.store_var("=")
		file.store_var(value)
		file.store_var("\n")

	# Script status
	var script_data = _game_manager.get_script_data()
	for scr in _game_manager.get_script_data():
		var value = script_data[scr]
		file.store_var("script_" + scr)
		file.store_var("=")
		file.store_var(value)
		file.store_var("\n")

	# TheaterNode status


	file.close()


func _load_thread_subprocess():
	var _script_data_to_be_loaded = {}
	var file = FileAccess.open(_save_file_name, FileAccess.READ)
	_mutex.unlock()

	if file == null:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration instead."
		)
		return

	_mutex.lock()

	# ...

	while file.get_position() < file.get_length():
		var key = file.get_var()
		file.get_var()
		var val = file.get_var()
		file.get_var()

		if (key.begins_with("var_")):
			_game_manager.set_variable(key.trim_prefix("var_"), val)

		if (key.begins_with("script_")):
			_script_data_to_be_loaded[key.trim_prefix("script_")] = val
			

	file.close()

	_game_manager.set_script_data(_script_data_to_be_loaded)

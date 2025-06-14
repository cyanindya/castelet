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
	_store_single_item("name", _save_file_name.split(".")[0], file)

	# Save date
	var save_time = Time.get_date_string_from_system()
	_store_single_item("last_updated", save_time, file)

	# Thumbnail
	# _store_single_item("img", img, file)

	# Game session variables
	_store_dict(_game_manager.get_all_variables(), "var", file)

	# Script status
	_store_dict(_game_manager.get_script_data(), "script", file)
	
	# TheaterNode status
	# TODO: how to save the stage props
	_store_dict(_theater_manager.get_theater_data(), "stage", file)
	
	file.close()


func _store_single_item(name : String, item, file_ref : FileAccess):
	if not file_ref.is_open():
		push_error("Cannot save the data with name \"" + name + "\"",
			" because the save file is not open."
		)
		return
	
	file_ref.store_var(name)
	file_ref.store_var("=")
	file_ref.store_var(item)
	file_ref.store_var("\n")


func _store_dict(dict : Dictionary, dict_prefix : String, file_ref : FileAccess):
	if not file_ref.is_open():
		push_error("Cannot save the dictionary data with prefix \"" + dict_prefix + "\"",
			" because the save file is not open."
		)
		return
	
	for item in dict:
		var value = dict[item]
		file_ref.store_var(dict_prefix + "_" + item)
		file_ref.store_var("=")
		file_ref.store_var(value)
		file_ref.store_var("\n")


func _load_thread_subprocess():
	var script_data = {}
	var theater_data = {}

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
			script_data[key.trim_prefix("script_")] = val

		if (key.begins_with("stage_")):
			theater_data[key.trim_prefix("stage_")] = val # TODO: iterate the stage props
			

	file.close()

	_game_manager.set_script_data(script_data)
	_theater_manager.set_theater_data(theater_data)

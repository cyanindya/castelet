extends CasteletSignedSaveLoadHandler

var _game_manager : CasteletGameManager
var _theater_manager : CasteletTheaterStateManager
var _peek_only : bool = false
var _peek_result = {}


func set_game_manager(obj : CasteletGameManager):
	_game_manager = obj


func set_theater_manager(obj : CasteletTheaterStateManager):
	_theater_manager = obj


func set_save_file_name(filename: String):
	_save_file_name = filename


func set_peek(yesno : bool = true):
	if yesno == true:
		_peek_only = true
	else:
		_peek_only = false


func is_peeking():
	return _peek_only


func get_peek_result():
	return _peek_result


func clear_peek_result():
	_peek_result.clear()


# Saving sub-process for the game.
# The following data are saved when the game data is saved:
	# Save data name
	# Last update date of the save data
	# Screenshot/thumbnail of the game
	# Game session variables
	# Current script data (which script is active, context level, etc)
	# Currently active props 
# This can be extended later depending on the game's context.
func _create_save_dictionary(save_dict : Dictionary):
	
	store_dict(_game_manager.get_all_variables(), "var", save_dict)
	store_dict(_game_manager.get_script_data(), "script", save_dict)
	store_dict(_theater_manager.get_theater_data(), "stage", save_dict)
	

func _process_loaded_data(data : Dictionary):

	var script_data = {}
	var theater_data = {}
	
	for key in data:
		if (key.begins_with("var_")):
			_game_manager.set_variable(key.trim_prefix("var_"), data[key])

		if (key.begins_with("script_")):
			script_data[key.trim_prefix("script_")] = data[key]

		if (key.begins_with("stage_")):
			theater_data[key.trim_prefix("stage_")] = data[key]

	if _peek_only == false:
		_game_manager.set_script_data_temp(script_data)
		_theater_manager.set_theater_data_temp(theater_data)
	else:
		_peek_result = {
			"script_data" : script_data,
			"theater_data" : theater_data,
		}

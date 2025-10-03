extends CasteletSignedSaveLoadHandler

var _game_manager : CasteletGameManager
var _theater_manager : CasteletTheaterStateManager
var _peek_only : bool = false
var _peek_result = {}

signal screenshot_ready(scr)


func set_game_manager(obj : CasteletGameManager):
	_game_manager = obj


func set_theater_manager(obj : CasteletTheaterStateManager):
	_theater_manager = obj
	_theater_manager.viewport_texture_processed.connect(_on_theater_manager_viewport_screenshot_ready)


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

	sub_mutex.lock()

	var screenshot : Image = await _capture_viewport_screenshot()
	# print_debug.call_deferred(screenshot)
	save_dict["screenshot"] = screenshot.save_png_to_buffer()
	
	store_dict(_game_manager.get_all_variables(), "var", save_dict)
	store_dict(_game_manager.get_script_data(), "script", save_dict)
	store_dict(_theater_manager.get_theater_data(), "stage", save_dict)

	sub_mutex.unlock()
	
	
func _process_loaded_data(data : Dictionary):

	# print_debug.call_deferred(data.keys())

	var header_data = {}
	var script_data = {}
	var theater_data = {}
	
	for key in data:
		if key == "last_updated":
			header_data["last_updated"] = data[key]

		if key == "screenshot":
			var scr = Image.new()
			scr.load_png_from_buffer(data[key])
			print_debug.call_deferred(scr)
			header_data["screenshot"] = scr
		
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
			"header_data" : header_data,
			"script_data" : script_data,
			"theater_data" : theater_data,
		}
		print_debug(_peek_result)


func _capture_viewport_screenshot(width : int = 320, height : int = 180) -> Image:
	_theater_manager.call_thread_safe("process_viewport_texture_request")
	var scr : Image = await screenshot_ready
	scr.resize(width, height)
	# scr.save_png("user://saves/Screenshot.png")
	return scr


func _on_theater_manager_viewport_screenshot_ready(scr : Image):
	screenshot_ready.emit(scr)

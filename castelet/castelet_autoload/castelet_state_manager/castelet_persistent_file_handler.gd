extends CasteletSignedSaveLoadHandler


var _game_manager : CasteletGameManager


func _init() -> void:
	_save_file_name = "user://persistent.sav"


func set_game_manager(obj : CasteletGameManager):
	_game_manager = obj


func _create_save_dictionary(save_dict : Dictionary):
	sub_mutex.lock()
	store_dict(_game_manager.get_all_variables(true), "persistent", save_dict)
	sub_mutex.unlock()


func _process_loaded_data(data : Dictionary):
	
	for key in data:
		if (key.begins_with("persistent_")):
			_game_manager.set_variable(key.trim_prefix("persistent_"), data[key], true)
	
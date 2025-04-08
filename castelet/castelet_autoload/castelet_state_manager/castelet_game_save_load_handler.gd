extends CasteletBaseSaveLoadHandler

var game_data_dir = "user://saves/"
var _game_manager : CasteletGameManager


func set_game_manager(obj : CasteletGameManager):
	_game_manager = obj


func set_save_file_name(filename: String):
	_save_file_name = filename


func _save_thread_subprocess():
	pass


func _load_thread_subprocess():
	pass

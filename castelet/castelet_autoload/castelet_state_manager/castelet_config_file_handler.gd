extends CasteletBaseSaveLoadHandler

var _config_section_name : String = "CasteletConfig"
var _config_manager : CasteletConfigManager


func _init() -> void:
	_save_file_name = "user://config.ini"


func set_config_manager(cfg : CasteletConfigManager):
	_config_manager = cfg


func _save_thread_subprocess() -> int:
	# Create new config instance
	var config = ConfigFile.new()

	for conf in _config_manager.ConfigList.keys():
		var conf_value = _config_manager.get_config(
			_config_manager.ConfigList.get(conf)
		)
		if conf_value != null:
			config.set_value(_config_section_name, str(conf), conf_value)

	config.save(_save_file_name)

	return 0


func _load_thread_subprocess() -> int:
	var config = ConfigFile.new()
	var err = config.load(_save_file_name)

	if err != OK:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration nstead."
		)
		return -1
	
	if config.has_section(_config_section_name):
		for conf in config.get_section_keys(_config_section_name):
			var conf_value = config.get_value(_config_section_name, conf)

			# _mutex.lock()
			_config_manager.set_config(
				_config_manager.ConfigList.get(conf),
				conf_value
			)
			# _mutex.unlock()
	
	return 0

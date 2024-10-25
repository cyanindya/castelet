extends RefCounted

@export var config_file = "user://config.ini"
@export var _config_section_name = "CasteletConfig"

func save_config_file():
	# Create new config instance
	var config = ConfigFile.new()

	for conf in CasteletConfig.ConfigList.keys():
		var conf_value = CasteletConfig.get_config(
			CasteletConfig.ConfigList.get(conf)
		)
		if conf_value != null:
			config.set_value(_config_section_name, str(conf), conf_value)

	config.save(config_file)


func load_config_file():
	var config = ConfigFile.new()

	var err = config.load(config_file)

	if err != OK:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration nstead."
		)
		return
	
	if config.has_section(_config_section_name):
		for conf in config.get_section_keys(_config_section_name):
			var conf_value = config.get_value(_config_section_name, conf)

			CasteletConfig.set_config(
				CasteletConfig.ConfigList.get(conf),
				conf_value
			)
	

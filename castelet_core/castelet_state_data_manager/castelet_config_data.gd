extends RefCounted

@export var config_file = "user://config.ini"

func save_config_file():
	# Create new config instance
	var config = ConfigFile.new()

	# First, save the text and dialogue-related data
	# config.set_value("Text", "base_text_speed", CasteletConfig.base_text_speed)
	# config.set_value("Text", "base_automode_timeout", CasteletConfig.base_automode_timeout)
	# config.set_value("Text", "forcibly_stop_ffwd_on_choices", CasteletConfig.forcibly_stop_ffwd_on_choices)
	# config.set_value("Text", "continue_ffwd_after_choices", CasteletConfig.continue_ffwd_after_choices)

	config.save(config_file)


func load_config_file():
	var config = ConfigFile.new()

	var err = config.load(config_file)

	if err != OK:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration instead."
		)
		return

	# CasteletConfig.base_automode_timeout = config.get_value("Text", "base_automode_timeout")
	# CasteletConfig.base_text_speed = config.get_value("Text", "base_text_speed")
	# CasteletConfig.forcibly_stop_ffwd_on_choices = config.get_value("Text", "forcibly_stop_ffwd_on_choices")
	# CasteletConfig.continue_ffwd_after_choices = config.get_value("Text", "continue_ffwd_after_choices")

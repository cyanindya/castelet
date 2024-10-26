extends CasteletSaveFileHandler

var _config_section_name : String = "CasteletConfig"


func _init() -> void:
	save_file_name = "user://config.ini"


func _save_thread_subprocess():
	# Create new config instance
	var config = ConfigFile.new()

	for conf in CasteletConfig.ConfigList.keys():
		var conf_value = CasteletConfig.get_config(
			CasteletConfig.ConfigList.get(conf)
		)
		if conf_value != null:
			config.set_value(_config_section_name, str(conf), conf_value)

	config.save(save_file_name)


func _load_thread_subprocess():
	var config = ConfigFile.new()
	var err = config.load(save_file_name)

	if err != OK:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration nstead."
		)
		return
	
	if config.has_section(_config_section_name):
		for conf in config.get_section_keys(_config_section_name):
			var conf_value = config.get_value(_config_section_name, conf)

			# _mutex.lock()
			CasteletConfig.set_config(
				CasteletConfig.ConfigList.get(conf),
				conf_value
			)
			# _mutex.unlock()


# extends RefCounted

# @export var config_file = "user://config.ini"
# @export var _config_section_name = "CasteletConfig"

# var _save_config_thread : Thread
# var _load_config_thread : Thread
# var _mutex : Mutex
# var _save_semaphore : Semaphore
# var _load_semaphore : Semaphore
# var _exiting_threads : bool = false


# signal load_config_start
# signal load_config_finish


# func initialize_threads():
# 	if _save_config_thread == null:
# 		_save_config_thread = Thread.new()
# 		_save_config_thread.start(_save_config_file_thread_process)
# 	if _load_config_thread == null:
# 		_load_config_thread = Thread.new()
# 		_load_config_thread.start(_load_config_file_thread_process)
# 	if _mutex == null:
# 		_mutex = Mutex.new()
# 	if _load_semaphore == null:
# 		_load_semaphore = Semaphore.new()
# 	if _save_semaphore == null:
# 		_save_semaphore = Semaphore.new()


# func dispose_threads():
# 	_exiting_threads = true

# 	_save_semaphore.post()
# 	_load_semaphore.post()

# 	_save_config_thread.wait_to_finish()
# 	_load_config_thread.wait_to_finish()


# func save_config_file():
# 	_save_semaphore.post()


# func _save_config_file_thread_process():
# 	while true:
# 		_save_semaphore.wait()

# 		# Make sure we halt the execution when being told to
# 		# exit after all semaphores had been cleared.
# 		_mutex.lock()
# 		var should_exit = _exiting_threads
# 		_mutex.unlock()

# 		if should_exit:
# 			break
		
# 		_mutex.lock()
# 		# Create new config instance
# 		var config = ConfigFile.new()

# 		for conf in CasteletConfig.ConfigList.keys():
# 			var conf_value = CasteletConfig.get_config(
# 				CasteletConfig.ConfigList.get(conf)
# 			)
# 			if conf_value != null:
# 				config.set_value(_config_section_name, str(conf), conf_value)

# 		config.save(config_file)
# 		_mutex.unlock()


# func load_config_file():
# 	_load_semaphore.post()


# func _load_config_file_thread_process():

# 	while true:

# 		_load_semaphore.wait()
		
# 		# Make sure we halt the execution when being told to
# 		# exit after all semaphores had been cleared.
# 		_mutex.lock()
# 		var should_exit = _exiting_threads
# 		_mutex.unlock()

# 		if should_exit:
# 			break
		
# 		load_config_start.emit.call_deferred()
		
# 		_mutex.lock()
# 		var config = ConfigFile.new()

# 		var err = config.load(config_file)

# 		if err != OK:
# 			push_warning("Unable to load the game configuration data." +
# 				"The game will use the default configuration nstead."
# 			)
# 			return
		
# 		if config.has_section(_config_section_name):
# 			for conf in config.get_section_keys(_config_section_name):
# 				var conf_value = config.get_value(_config_section_name, conf)

# 				# _mutex.lock()
# 				CasteletConfig.set_config(
# 					CasteletConfig.ConfigList.get(conf),
# 					conf_value
# 				)
# 				# _mutex.unlock()
		
# 		_mutex.unlock()

# 		load_config_finish.emit.call_deferred()
	

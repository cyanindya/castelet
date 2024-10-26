extends CasteletSaveFileHandler


func _init() -> void:
	save_file_name = "user://persistent.sav"


func _save_thread_subprocess():
	var file = FileAccess.open(save_file_name, FileAccess.WRITE)

	for persistent_data in CasteletGameManager.get_all_variables(true):
		var value = CasteletGameManager.get_variable(persistent_data, true)
		file.store_pascal_string(persistent_data)
		file.store_pascal_string("=")
		file.store_var(value)
		file.store_pascal_string("\n")

	file.close()


func _load_thread_subprocess():
	var file = FileAccess.open(save_file_name, FileAccess.READ)
	_mutex.unlock()

	if file == null:
		push_warning("Unable to load the game configuration data." +
			"The game will use the default configuration nstead."
		)
		return

	_mutex.lock()
	while file.get_position() < file.get_length():
		var key = file.get_pascal_string()
		file.get_pascal_string()
		var val = file.get_var()
		file.get_pascal_string()
		CasteletGameManager.set_variable(key, val, true)
	
	file.close()


# extends RefCounted

# var persistent_data_path = "user://persistent.sav"

# var _save_persistent_thread : Thread
# var _load_persistent_thread : Thread
# var _mutex : Mutex
# var _save_semaphore : Semaphore
# var _load_semaphore : Semaphore
# var _exiting_threads : bool = false

# signal load_persistent_start
# signal load_persistent_finish




# func initialize_threads():
# 	if _save_persistent_thread == null:
# 		_save_persistent_thread = Thread.new()
# 		_save_persistent_thread.start(_save_persistent_file_thread_process)
# 	if _load_persistent_thread == null:
# 		_load_persistent_thread = Thread.new()
# 		_load_persistent_thread.start(_load_persistent_file_thread_process)
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

# 	_save_persistent_thread.wait_to_finish()
# 	_load_persistent_thread.wait_to_finish()


# func save_castelet_persistent():
# 	_save_semaphore.post()


# func _save_persistent_file_thread_process():
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
# 		var file = FileAccess.open(persistent_data_path, FileAccess.WRITE)

# 		for persistent_data in CasteletGameManager.get_all_variables(true):
# 			var value = CasteletGameManager.get_variable(persistent_data, true)
# 			file.store_pascal_string(persistent_data)
# 			file.store_pascal_string("=")
# 			file.store_var(value)
# 			file.store_pascal_string("\n")

# 		file.close()
# 		_mutex.unlock()


# func load_castelet_persistent():
# 	_load_semaphore.post()


# func _load_persistent_file_thread_process():
# 	while true:
# 		_load_semaphore.wait()

# 		# Make sure we halt the execution when being told to
# 		# exit after all semaphores had been cleared.
# 		_mutex.lock()
# 		var should_exit = _exiting_threads
# 		_mutex.unlock()

# 		if should_exit:
# 			break
		
# 		_mutex.lock()
# 		var file = FileAccess.open(persistent_data_path, FileAccess.READ)
# 		_mutex.unlock()

# 		if file == null:
# 			push_warning("Unable to load the game configuration data." +
# 				"The game will use the default configuration nstead."
# 			)
# 			return

# 		_mutex.lock()
# 		while file.get_position() < file.get_length():
# 			var key = file.get_pascal_string()
# 			file.get_pascal_string()
# 			var val = file.get_var()
# 			file.get_pascal_string()
# 			CasteletGameManager.set_variable(key, val, true)
		
# 		file.close()
# 		_mutex.unlock()
	

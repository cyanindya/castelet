extends RefCounted
class_name CasteletBaseSaveLoadHandler

var save_file_name : String

var _save_thread : Thread
var _load_thread : Thread
var _mutex : Mutex
var _save_semaphore : Semaphore
var _load_semaphore : Semaphore
var _exiting_threads : bool = false

signal save_start
signal save_finish
signal load_start
signal load_finish


func init_threads():
	if _save_thread == null:
		_save_thread = Thread.new()
		_save_thread.start(_saveload_thread_process.bind(true))
	if _load_thread == null:
		_load_thread = Thread.new()
		_load_thread.start(_saveload_thread_process.bind(false))
	if _mutex == null:
		_mutex = Mutex.new()
	if _load_semaphore == null:
		_load_semaphore = Semaphore.new()
	if _save_semaphore == null:
		_save_semaphore = Semaphore.new()


func join_threads():
	_exiting_threads = true

	_save_semaphore.post()
	_load_semaphore.post()

	_save_thread.wait_to_finish()
	_load_thread.wait_to_finish()


func save_file():
	_save_semaphore.post()


func load_file():
	_load_semaphore.post()


func _saveload_thread_process(saving : bool = true):
	while true:
		if saving:
			_save_semaphore.wait()
		else:
			_load_semaphore.wait()

		# Make sure we halt the execution when being told to
		# exit after all semaphores had been cleared.
		_mutex.lock()
		var should_exit = _exiting_threads
		_mutex.unlock()

		if should_exit:
			break
		
		if saving:
			save_start.emit.call_deferred()
		else:
			load_start.emit.call_deferred()

		_mutex.lock()
		if saving:
			_save_thread_subprocess()
		else:
			_load_thread_subprocess()
		_mutex.unlock()

		if saving:
			save_finish.emit.call_deferred()
		else:
			load_finish.emit.call_deferred()


func _save_thread_subprocess():
	pass


func _load_thread_subprocess():
	pass

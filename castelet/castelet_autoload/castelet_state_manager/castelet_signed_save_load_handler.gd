extends CasteletBaseSaveLoadHandler
class_name CasteletSignedSaveLoadHandler


var sub_thread : Thread
var sub_mutex : Mutex
var raw_dict = {}


func _save_thread_subprocess() -> int:
	raw_dict.clear()
	sub_thread = Thread.new()
	sub_mutex = Mutex.new()

	raw_dict["name"] = _save_file_name.split(".")[0]

	var save_time = Time.get_datetime_string_from_system()
	raw_dict["last_updated"] = save_time

	sub_thread.start(_sub_save)
	sub_thread.wait_to_finish()

	sub_mutex.lock()
	
	# print_debug.call_deferred(raw_dict)
	var data_to_save = var_to_bytes(raw_dict)
	
	var data_hex : String = data_to_save.hex_encode()
	var data_hash = data_hex.sha256_text()

	var file = FileAccess.open_compressed(_save_file_name, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)

	file.store_string(data_hex)
	file.store_string("+++")
	file.store_string(data_hash)
	

	file.close()
	sub_mutex.unlock()

	print_debug.call_deferred(raw_dict.keys())

	return 0


func _load_thread_subprocess() -> int:
	
	var file = FileAccess.open_compressed(_save_file_name, FileAccess.READ, FileAccess.COMPRESSION_GZIP)
	print_debug("FN: ", _save_file_name)
	_mutex.unlock()

	if file == null:
		push_warning("Unable to load the save data.")
		return -1

	_mutex.lock()

	# ...

	var raw_data = file.get_as_text()
	
	var data_key = raw_data.split("+++")

	# Check the SHA-256 hash first
	var is_hash_valid : bool = data_key[0].sha256_text() == data_key[1] 

	if not is_hash_valid:
		print("Invalid hash. The save data cannot be loaded.")
		# return
		# TODO: return status is success/fail
	
	var saved = data_key[0].hex_decode()
	var data = bytes_to_var(saved)

	# print_debug("data=", data)

	_process_loaded_data(data)

	return 0


func store_dict(dict : Dictionary, dict_prefix : String, dict_ref : Dictionary):
	for item in dict:
		var value = dict[item]
		dict_ref[dict_prefix + "_" + item] = value


func _create_save_dictionary(save_dict : Dictionary):
	pass


func _process_loaded_data(data : Dictionary):
	pass

func _sub_save():
	sub_mutex.lock()
	_create_save_dictionary(raw_dict)
	sub_mutex.unlock()

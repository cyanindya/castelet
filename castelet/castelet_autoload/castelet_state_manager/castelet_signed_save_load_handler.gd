extends CasteletBaseSaveLoadHandler
class_name CasteletSignedSaveLoadHandler


func _save_thread_subprocess() -> int:

	var raw_dict = {}

	raw_dict["name"] = _save_file_name.split(".")[0]

	var save_time = Time.get_datetime_string_from_system()
	raw_dict["last_updated"] = save_time

	_create_save_dictionary(raw_dict)

	var data_to_save = var_to_bytes(raw_dict)
	
	var data_hex : String = data_to_save.hex_encode()
	var data_hash = data_hex.sha256_text()

	var file = FileAccess.open_compressed(_save_file_name, FileAccess.WRITE, FileAccess.COMPRESSION_GZIP)

	file.store_string(data_hex)
	file.store_string("+++")
	file.store_string(data_hash)
	

	file.close()

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

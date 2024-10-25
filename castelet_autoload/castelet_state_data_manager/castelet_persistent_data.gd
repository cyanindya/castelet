extends RefCounted

var persistent_data_path = "user://persistent.sav"


func save_castelet_persistent():
	var file = FileAccess.open(persistent_data_path, FileAccess.WRITE)

	for persistent_data in CasteletGameManager.persistent.keys():
		file.store_line(persistent_data)

	file.close()


#func load_castelet_persistent():
	#var file = FileAccess.open(persistent_data_path, FileAccess.READ)
#
	## TODO
	#
	#file.close()
	

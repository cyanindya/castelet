extends Node

# An all-purpose function to go through a specified directory and
# its subdirectories to load a specified type of file.
# Do note that this requires callback function.
func load_all_resources_of_type(starting_dir : String, node : Node, callback_fun : String) -> void:

	var resource_dir = DirAccess.open(starting_dir)

	if resource_dir:

		# Begin iterating through the directory
		resource_dir.list_dir_begin()
		var file_name = resource_dir.get_next()
		
		while file_name != "":

			var fn = resource_dir.get_current_dir().path_join(file_name)
			
			# If the current filename is a sub-directory, perform recursive call
			# of this function by supplementing the subdirectory name,
			# then merge the output dictionary from the recursive call with the
			# main dictionary
			if resource_dir.current_is_dir():
				load_all_resources_of_type(fn, node, callback_fun)
			
			# Call the callback function to load the specific resources here
			var fun = Callable(node, callback_fun)
			fun.call(fn)
			
			# Get the next file to be processed
			file_name = resource_dir.get_next()
				
		# Finish checking through directory
		resource_dir.list_dir_end()

	else:
		printerr("Cannot open the specified assets folder. Please re-check the location.")

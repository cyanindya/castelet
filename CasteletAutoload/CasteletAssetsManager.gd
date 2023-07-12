# This script serves to control a singleton node that contains all story assets
# usable during runtime -- basically a runtime database. The assets will be loaded
# during the start of the game, after which the Theater nodes can access it.
# 
# In general, this node works in the following manner:
# - First, developer must provide the directory name where all resources/assets are stored
# - Early during runtime, this program will search for all PropResource-derived resource
#   files (.tres) for all data related to "stage props" (including puppets/actors).
#   Each of these .tres files will be instantiated into PropNode-class nodes and
#   stored into "props" dictionary.
# - (todo on audio management)
#
# (todo on other important stuffs, such as accessing the loaded resources and assets from script)
#

extends Node
class_name CasteletAssetsManager

@export_dir var resource_dir : String
#@onready var props := _load_prop_resources(resource_dir)
var props := {}
var audio_shorthand = {}

func _ready():
	_load_resources(resource_dir)

# The function to be run automatically for loading all PropResource-driven
# .tres data into PropNode instances. The output of this function is a Dictionary
# containing prop ID/PropNode instance key/value pairs, which is stored in
# the "props" property.
#
# This function will automatically searches for subfolders. However, it is advisable
# to keep all .tres files within one folder.
#
func _load_resources(dir : String) -> void:
	
	# Open the supplied assets/resource folder.
	var res_dir = DirAccess.open(dir)
	
	# Initialize an empty dictionary that will store all of the prop ID/prop
	# node key/value pairs
#	var prop_resources = {}
	
	if dir:
		# Begin iterating through the directory
		res_dir.list_dir_begin()
		var file_name = res_dir.get_next()
		
		# Empty file name indicates the end of the directory has been reached.
		# As such, this search function will be performed so long there are still
		# files to iterate through.
		while file_name != "":
			
			print_debug(file_name + " at " + res_dir.get_current_dir())
			
			# If the current filename is a sub-directory, perform recursive call
			# of this function by supplementing the subdirectory name,
			# then merge the output dictionary from the recursive call with the
			# main dictionary
			if res_dir.current_is_dir():
#				var temp = _load_resources(
				_load_resources(res_dir.get_current_dir().path_join(file_name))
#				prop_resources.merge(temp)
			
			
			# If the file is a proper Godot resource file (.tres), load the resource,
			# then check if it is a PropResource-type data. If it is, generate
			# an instance of PropNode that can be used in the Theater node later.
			#
			# TODO: check if the loaded resource can potentially cause memory leak
			# if it is NOT of compatible type -- how do we handle it?
			if file_name.ends_with(".tres"):

				var res: Resource = load(res_dir.get_current_dir() + "/" + file_name)
				
				if res is PropResource:
					pass
					
					
				
				if res is PropResource:
					var new_prop = PropNode.new(res)
#					prop_resources[res.prop_id] = new_prop
					props[res.prop_id] = new_prop

				if res is AudioListResource:
					for item in (res.audio_list as Dictionary):
						audio_shorthand[item] = load(res.audio_list[item])
			
			# Get the next file to be processed
			file_name = res_dir.get_next()
		
		# Finish checking through directory
		res_dir.list_dir_end()
		
	else:
		print_debug("Cannot open the specified assets folder. Please re-check the location.")
#		return {}
	
#	return prop_resources

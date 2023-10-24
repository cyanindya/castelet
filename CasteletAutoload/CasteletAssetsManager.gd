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

@export_dir var resource_dir : String
var props := {}
var audio_shorthand = {}

func _ready():
	CasteletResourceLoader.load_all_resources_of_type(resource_dir, self, "_prop_loader_callback")

func _prop_loader_callback(file_name : String):

	# If the file is a proper Godot resource file (.tres), load the resource,
	# then check if it is a PropResource-type data. If it is, generate
	# an instance of PropNode that can be used in the Theater node later.
	#
	# TODO: check if the loaded resource can potentially cause memory leak
	# if it is NOT of compatible type -- how do we handle it?
	if file_name.ends_with(".tres"):

		var res: Resource = load(file_name)
		
		if res is PropResource:
			var new_prop = PropNode.new(res)
			props[res.prop_id] = new_prop

		if res is AudioListResource:
			for item in (res.audio_list as Dictionary):
				audio_shorthand[item] = load(res.audio_list[item])

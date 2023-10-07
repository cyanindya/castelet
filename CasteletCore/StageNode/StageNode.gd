extends Node2D

#
# This node is dependent on the following singletons:
# - CasteletGameManager
# - CasteletViewportManager
# - CasteletAssetsManager
#


func scene(prop_name := "", prop_variant := "default", args := {}):
	
	clear_props()
	
	if prop_name != "none":
		show_prop(prop_name, prop_variant, args)
	else:
		CasteletGameManager.progress.emit()
	

func show_prop(prop_name := "", prop_variant := "default", args := {}):

	# If the prop is not in active props list, grab the reference from CasteletAssetsManager
	var prop: PropNode = get_node_or_null(prop_name)
	
	# Default x-position and y-position value
	var xpos = 0.5
	var ypos = 1.0
	var scale_factor = 1.0
	
	# If this is a newly shown prop, add it to the stage. Otherwise, keep
	# track of the last known location
	if prop == null:
		prop = CasteletAssetsManager.props[prop_name]
		add_child(prop)
	else:
		xpos = prop.position.x / CasteletViewportManager.base_viewport_width
		ypos = prop.position.y / CasteletViewportManager.base_viewport_height
		scale_factor = prop.in_viewport_scale / CasteletViewportManager.base_scale_factor
	
	# Check if the defined prop has the particular variant. Otherwise, send
	# a warning and display null object instead.
	prop.set_variant(prop_variant)
	
	# Pass the optional arguments
	if args:
		if args.has("x"):
			xpos = float(args['x'])
		if args.has("y"):
			ypos = float(args['y'])
		if args.has("flip"):
			if args["flip"] == "true":
				prop.set_flip(true)
			else:
				prop.set_flip(false)
		if args.has("scale"):
			scale_factor = float(args["scale"])
	
	# Properly display the prop now
	prop.position.x = CasteletViewportManager.base_viewport_width * xpos
	prop.position.y = CasteletViewportManager.base_viewport_height * ypos
	prop.in_viewport_scale = CasteletViewportManager.base_scale_factor * scale_factor
	
	CasteletGameManager.progress.emit()


func hide_prop(prop_name : String):
	var prop : PropNode = get_node_or_null(prop_name)
	if prop != null:
		remove_child(prop)
	
		CasteletGameManager.progress.emit()


func clear_props():
	for child in get_children():
		if child is PropNode:
			remove_child(child)

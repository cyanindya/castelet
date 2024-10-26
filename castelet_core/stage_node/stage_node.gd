extends Node2D

#
# This node is dependent on the following singletons:
# - CasteletGameManager
# - CasteletViewportManager
# - CasteletAssetsManager
#

@onready var _assets_manager : CasteletAssetsManager = get_node("/root/CasteletAssetsManager")
@onready var _game_manager = get_node("/root/CasteletGameManager")

signal stage_updated


func scene(prop_name := "", prop_variant := "default", args := {}):
	
	clear_props()
	
	if prop_name != "none":
		show_prop(prop_name, prop_variant, args)
	else:
		_game_manager.progress.emit()
	

func show_prop(prop_name := "", prop_variant := "default", args := {}):

	# If the prop is not in active props list, grab the reference from CasteletAssetsManager
	var prop: PropNode = get_node_or_null(prop_name)
	
	# Default x-position and y-position value
	var old_xpos = 0.5
	var old_ypos = 1.0
	var new_xpos = 0.5
	var new_ypos = 1.0
	var scale_factor = 1.0
	var flip = null
	
	# If this is a newly shown prop, add it to the stage. Otherwise, keep
	# track of the last known location
	if prop == null:
		prop = _assets_manager.props[prop_name]
		add_child(prop)

		if args.has("transition"):
			if args["transition"].has("enter_from"):
				if args["transition"]["enter_from"] == "left":
					old_xpos = -0.5
					if args.has("y"):
						old_ypos = args["y"]
					else:
						old_ypos = 1.0
				elif args["transition"]["enter_from"] == "right":
					old_xpos = 1.5
					if args.has("y"):
						old_ypos = args["y"]
					else:
						old_ypos = 1.0
				elif args["transition"]["enter_from"] == "top":
					
					if args.has("x"):
						old_xpos = args["x"]
					else:
						old_xpos = 0.5
					old_ypos = 0.0
				elif args["transition"]["enter_from"] == "bottom":
					
					if args.has("x"):
						old_xpos = args["x"]
					else:
						old_xpos = 0.5
					old_ypos = 2.0
				
				prop.position.x = CasteletViewportManager.base_viewport_width * old_xpos
				prop.position.y = CasteletViewportManager.base_viewport_height * old_ypos
				prop.in_viewport_scale = CasteletViewportManager.base_scale_factor * scale_factor
	else:
		old_xpos = prop.position.x / CasteletViewportManager.base_viewport_width
		old_ypos = prop.position.y / CasteletViewportManager.base_viewport_height
		scale_factor = prop.in_viewport_scale / CasteletViewportManager.base_scale_factor

		new_xpos = old_xpos
		new_ypos = old_ypos
	
	# Pass the optional arguments
	if args:
		if args.has("x"):
			new_xpos = float(args['x'])
		if args.has("y"):
			new_ypos = float(args['y'])
		if args.has("flip"):
			flip = args["flip"]
		if args.has("scale"):
			scale_factor = float(args["scale"])

	# Check if the defined prop has the particular variant. Otherwise, send
	# a warning and display null object instead.
	prop.set_variant(prop_variant)
	if flip != null:
		prop.set_flip(flip)
	
	var viewport_new_xpos = CasteletViewportManager.base_viewport_width * new_xpos
	var viewport_new_ypos = CasteletViewportManager.base_viewport_height * new_ypos

	# Properly display the prop now
	if args.has("transition"):
		if args["transition"]["transition_name"] == "move":
			CasteletTransitionManager.move_object(prop, Vector2(viewport_new_xpos, viewport_new_ypos),
				prop.position, args["transition"])
			await CasteletTransitionManager.transition_completed
	else:
		prop.position.x = viewport_new_xpos
		prop.position.y = viewport_new_ypos
		prop.in_viewport_scale = CasteletViewportManager.base_scale_factor * scale_factor
	
	stage_updated.emit()
	_game_manager.progress.emit()


func hide_prop(prop_name : String, args := {}):
	var prop : PropNode = get_node_or_null(prop_name)
	if prop != null:
		if args.has("transition"):
			var new_xpos = prop.position.x / CasteletViewportManager.base_viewport_width
			var new_ypos = prop.position.y / CasteletViewportManager.base_viewport_height
			
			if args["transition"].has("exit_to"):
				if args["transition"]["exit_to"] == "left":
					new_xpos = -0.5
				elif args["transition"]["exit_to"] == "right":
					new_xpos = 1.5
				elif args["transition"]["exit_to"] == "top":
					new_ypos = 0.0
				elif args["transition"]["exit_to"] == "bottom":
					new_ypos = 2.0
			
			var viewport_new_xpos = CasteletViewportManager.base_viewport_width * new_xpos
			var viewport_new_ypos = CasteletViewportManager.base_viewport_height * new_ypos
			
			if args["transition"]["transition_name"] == "move":
				CasteletTransitionManager.move_object(prop, Vector2(viewport_new_xpos, viewport_new_ypos),
					prop.position, args["transition"])
				await CasteletTransitionManager.transition_completed

		remove_child(prop)

		stage_updated.emit()
		_game_manager.progress.emit()


func clear_props():
	for child in get_children():
		if child is PropNode:
			remove_child(child)

extends Node2D

#
# This node is dependent on the following singletons:
# - CasteletGameManager
# - CasteletViewportManager
# - CasteletAssetsManager
#

@onready var _assets_manager : CasteletAssetsManager = get_node("/root/CasteletAssetsManager")
@onready var _game_manager : CasteletGameManager = get_node("/root/CasteletGameManager")
@onready var _transition_manager : CasteletTransitionManager = get_node("/root/CasteletTransitionManager")
@onready var _viewport_manager : CasteletViewportManager = get_node("/root/CasteletViewportManager")

signal stage_updated


func _ready() -> void:
	_viewport_manager.viewport_resized.connect(_on_viewport_resized)	


func scene(prop_name := "", prop_variant := "default", args := {}):
	
	clear_props()
	
	if prop_name != "none":
		show_prop(prop_name, prop_variant, args)
	else:
		_game_manager.progress.emit()
	

func show_prop(prop_name := "", prop_variant := "default", args := {}):

	# If the prop is not in active props list, grab the reference from CasteletAssetsManager
	var prop: CasteletPropNode = get_node_or_null(prop_name)
	
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
				
				prop.position.x = get_window().content_scale_size.x * old_xpos
				prop.position.y = get_window().content_scale_size.y * old_ypos
				prop.in_viewport_scale = _viewport_manager.base_scale_factor * scale_factor
	else:
		old_xpos = prop.position.x / get_window().content_scale_size.x
		old_ypos = prop.position.y / get_window().content_scale_size.y
		scale_factor = prop.in_viewport_scale / _viewport_manager.base_scale_factor

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
	
	var viewport_new_xpos = get_window().content_scale_size.x * new_xpos
	var viewport_new_ypos = get_window().content_scale_size.y * new_ypos

	# Properly display the prop now
	if args.has("transition"):
		if args["transition"]["transition_name"] == "move":
			_transition_manager.move_object(prop, Vector2(viewport_new_xpos, viewport_new_ypos),
				prop.position, args["transition"])
			await _transition_manager.transition_completed
	else:
		prop.position.x = viewport_new_xpos
		prop.position.y = viewport_new_ypos
		prop.in_viewport_scale = _viewport_manager.base_scale_factor * scale_factor
	
	stage_updated.emit()
	_game_manager.progress.emit()


func hide_prop(prop_name : String, args := {}):
	var prop : CasteletPropNode = get_node_or_null(prop_name)
	if prop != null:
		if args.has("transition"):
			var new_xpos = prop.position.x / get_window().content_scale_size.x
			var new_ypos = prop.position.y / get_window().content_scale_size.y
			
			if args["transition"].has("exit_to"):
				if args["transition"]["exit_to"] == "left":
					new_xpos = -0.5
				elif args["transition"]["exit_to"] == "right":
					new_xpos = 1.5
				elif args["transition"]["exit_to"] == "top":
					new_ypos = 0.0
				elif args["transition"]["exit_to"] == "bottom":
					new_ypos = 2.0
			
			var viewport_new_xpos = get_window().content_scale_size.x * new_xpos
			var viewport_new_ypos = get_window().content_scale_size.y * new_ypos
			
			if args["transition"]["transition_name"] == "move":
				_transition_manager.move_object(prop, Vector2(viewport_new_xpos, viewport_new_ypos),
					prop.position, args["transition"])
				await _transition_manager.transition_completed

		remove_child(prop)

		stage_updated.emit()
		_game_manager.progress.emit()


func clear_props():
	for child in get_children():
		if child is CasteletPropNode:
			remove_child(child)

# Ensures smooth appearance regardless of current resolution, since
# all props' size and position are recalculated.
# FIXME: Currently doesn't work well with Godot's stretch mode and content scaling
func _on_viewport_resized():
	for child in get_children():
		if child is CasteletPropNode:
			var old_viewport_scale = child.in_viewport_scale

			child.in_viewport_scale = _viewport_manager.base_scale_factor
			child.position.x *= child.in_viewport_scale / old_viewport_scale
			child.position.y *= child.in_viewport_scale / old_viewport_scale

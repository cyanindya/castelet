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
	
	

func show_prop(prop_name := "", prop_variant := "default", args := {}):

	# If the prop is not in active props list, grab the reference from CasteletAssetsManager
	var prop: PropNode = get_node_or_null(prop_name)
	
	if prop == null:
		prop = CasteletAssetsManager.props[prop_name]
		add_child(prop)
	
	prop.texture = prop.variants[prop_variant]

	if args:
		pass

	prop.position.x = CasteletViewportManager.base_viewport_width * 0.5
	prop.position.y = CasteletViewportManager.base_viewport_height * 1.0
	prop.default_viewport_scale = CasteletViewportManager.base_scale_factor
	
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

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


func play_audio(audio_file : String, args := {}, channel:="BGM"):
	
	var audio_stream : AudioStream

	if (CasteletAssetsManager.audio_shorthand as Dictionary).has(audio_file):
		audio_stream = CasteletAssetsManager.audio_shorthand[audio_file]
	else:
		var full_path = CasteletAssetsManager.resource_dir.path_join(audio_file)
		audio_stream = load(full_path)

	var audio_node = get_node(channel)
	print_debug(audio_node)
	
	if (audio_node.is_playing()):
		audio_node.stop()
	audio_node.init_stream(audio_stream, args)
	audio_node.play_stream()
	
	CasteletGameManager.progress.emit()

func refresh_audio(args := {}, channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.init_stream(null, args)
	
	CasteletGameManager.progress.emit()

func stop_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stop_stream()
	
	CasteletGameManager.progress.emit()

func pause_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = true
	
	CasteletGameManager.progress.emit()

func resume_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = false
	
	CasteletGameManager.progress.emit()
	

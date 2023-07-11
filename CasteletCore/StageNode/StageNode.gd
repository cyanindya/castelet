extends Node2D

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

	prop.position.x = CasteletConfig.base_viewport_width * 0.5
	prop.position.y = CasteletConfig.base_viewport_height * 1.0
	
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
	
	var audio_node = get_node(channel)
	print_debug(audio_node)
	
	if (audio_node.is_playing()):
		audio_node.stop()
	audio_node.init_stream(audio_file, args)
	audio_node.play_stream()
	
	CasteletGameManager.progress.emit()

func refresh_audio(args := {}, channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.init_stream("", args)
	
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
	

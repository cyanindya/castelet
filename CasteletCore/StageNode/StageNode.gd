extends Node2D

@export_node_path("CasteletGameManager") var game_manager
@export_node_path("CasteletAssetsManager") var asset_manager
@export_node_path("CasteletConfig") var config
@export_node_path("CasteletViewportManager") var vp

func _ready():
	# Before we begin, make sure the required CasteletGameManager and CasteletAssetsManager instances
	# are valid, and try to grab it from root node if necessary. Otherwise, throw an error since they're required.
	if game_manager == null:
		game_manager = get_node("/root/CasteletGameManager")
	
	if asset_manager == null:
		asset_manager = get_node("/root/CasteletAssetsManager")
	
	if config == null:
		config = get_node("/root/CasteletConfig")
	
	if vp == null:
		vp = get_node("/root/CasteletViewportManager")


func scene(prop_name := "", prop_variant := "default", args := {}):
	
	clear_props()
	
	if prop_name != "none":
		show_prop(prop_name, prop_variant, args)
	
	

func show_prop(prop_name := "", prop_variant := "default", args := {}):

	# If the prop is not in active props list, grab the reference from CasteletAssetsManager
	var prop: PropNode = get_node_or_null(prop_name)
	
	if prop == null:
		prop = asset_manager.props[prop_name]
		add_child(prop)
	
	prop.texture = prop.variants[prop_variant]

	if args:
		pass

	prop.position.x = vp.base_viewport_width * 0.5
	prop.position.y = vp.base_viewport_height * 1.0
	prop.default_viewport_scale = vp.base_scale_factor
	
	game_manager.progress.emit()


func hide_prop(prop_name : String):
	var prop : PropNode = get_node_or_null(prop_name)
	if prop != null:
		remove_child(prop)
	
		game_manager.progress.emit()


func clear_props():
	for child in get_children():
		if child is PropNode:
			remove_child(child)


func play_audio(audio_file : String, args := {}, channel:="BGM"):
	
	var audio_stream : AudioStream

	if (asset_manager.audio_shorthand as Dictionary).has(audio_file):
		audio_stream = asset_manager.audio_shorthand[audio_file]
	else:
		var full_path = asset_manager.resource_dir.path_join(audio_file)
		audio_stream = load(full_path)

	var audio_node = get_node(channel)
	print_debug(audio_node)
	
	if (audio_node.is_playing()):
		audio_node.stop()
	audio_node.init_stream(audio_stream, args)
	audio_node.play_stream()
	
	game_manager.progress.emit()

func refresh_audio(args := {}, channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.init_stream(null, args)
	
	game_manager.progress.emit()

func stop_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stop_stream()
	
	game_manager.progress.emit()

func pause_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = true
	
	game_manager.progress.emit()

func resume_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = false
	
	game_manager.progress.emit()
	

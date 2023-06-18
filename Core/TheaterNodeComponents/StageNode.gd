extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func play_audio(audio_file : String, args := {}, channel:="BGM"):
	
	var audio_node = get_node(channel)
	print_debug(audio_node)
	
	if (audio_node.is_playing()):
		audio_node.stop()
	audio_node.init_stream(audio_file, args)
	audio_node.play_stream()

func refresh_audio(args := {}, channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.init_stream("", args)

func stop_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stop_stream()
	
func pause_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = true

func resume_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = false
	

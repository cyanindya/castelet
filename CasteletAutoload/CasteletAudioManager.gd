extends Node

#
# This node is dependent on the following singletons:
# - CasteletAssetsManager
#


func play_audio(audio_file : String, args := {}, channel:="BGM"):
	
	var audio_stream : AudioStream

	if (CasteletAssetsManager.audio_shorthand as Dictionary).has(audio_file):
		audio_stream = CasteletAssetsManager.audio_shorthand[audio_file]
	else:
		var full_path = CasteletAssetsManager.resource_dir.path_join(audio_file)
		audio_stream = load(full_path)

	var audio_node = get_node(channel)
	
	if (audio_node.is_playing()):
		audio_node.stop()
	audio_node.clear_queue()
	audio_node.init_stream(audio_stream, args)
	audio_node.play_stream()

func queue_audio(audio_files := [], args := {}, channel:="BGM"):
	
	var queue = []

	for audio_file in audio_files:

		var audio_stream : AudioStream
		
		if (CasteletAssetsManager.audio_shorthand as Dictionary).has(audio_file):
			audio_stream = CasteletAssetsManager.audio_shorthand[audio_file]
		else:
			var full_path = CasteletAssetsManager.resource_dir.path_join(audio_file)
			audio_stream = load(full_path)
		audio_stream.set_loop(false)
		queue.append(audio_stream)

	var audio_node = get_node(channel)
	
	if (audio_node.is_playing()):
		audio_node.stop()
	audio_node.init_queue(queue, args)
	audio_node.play_stream()

func refresh_audio(args := {}, channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.init_stream(null, args)

func stop_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stop_stream()

func pause_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = true

func resume_audio(channel:="BGM"):
	var audio_node = get_node(channel)
	audio_node.stream_paused = false
	

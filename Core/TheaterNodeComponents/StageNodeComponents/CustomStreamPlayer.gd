# This Node is a custom node derived from AudioStreamPlayer that is customized
# to enable finer control over the audio player, such as enabling fade-in/fadeout
# effect using Tween class and starting/stopping/looping audio track on certain
# points.

extends AudioStreamPlayer
class_name CustomStreamPlayer

var fadein = 0.0
var fadeout = 0.0
var start_point = 0.0
var loop_point = -1
var end_point = -1
var loop = false
var _audio_tween : Tween
var mute_volume_db := -40.0
var set_volume_db := 0.0


# Handle custom end-point and fadeout during frame updates.

func _process(_delta):
	if is_playing:
		if loop:
			if ((end_point != -1) and get_playback_position() >= end_point):
				seek(loop_point)
		else:
			if ((end_point != -1) and get_playback_position() >= end_point - fadeout):
				
				# Make sure to fire the fadeout tween only once.
				if not _audio_tween.is_running():
					stop_stream()
	

# This class doesn't allow overriding play() function apparently, so to implement
# fadein, we need to create new function altogether.
func play_stream():
	
	if (fadein > 0.0):
		fade_audio(mute_volume_db, set_volume_db, fadein)
	
	play(start_point)


# Ditto for stop() function.
func stop_stream():
	
	if (fadeout > 0.0):
		fade_audio(set_volume_db, mute_volume_db, fadeout)
		await _audio_tween.finished
	stop()
	volume_db = set_volume_db


# Fadein and fadeout has inherently similar way of working, so we'll just write
# custom function that handles both.
func fade_audio(from : float =-20.0, to :=0.0, duration :=1.0):
	
	if _audio_tween:
		_audio_tween.kill()
	
	_audio_tween = create_tween()
	_audio_tween.tween_property(self, "volume_db", to, duration).from(from)


# A custom function to set up the stream player parameters (e.g. fadein and
# fadeout time) before actually playing the audio.
func init_stream(track : String, args := {}):
	
	if track:
		if (AssetsDb.audio_shorthand as Dictionary).has(track):
			stream = AssetsDb.audio_shorthand[track]
		else:
			var full_path = AssetsDb.resource_dir.path_join(track)
			stream = load(full_path)
		
	set_volume_db = volume_db
	
	if args.has("loop"):
		if (args['loop'] == "true"):
			stream.set_loop(true)
			loop = true
		else:
			stream.set_loop(false)
			loop = false
	
	if args.has("volume"):
		set_volume_db = _convert_ratio_to_db(args["volume"] as float)
		volume_db = set_volume_db
	
	if args.has("fadein"):
		fadein = args['fadein'] as float
	
	if args.has("fadeout"):
		fadeout = args['fadeout'] as float
	
	if args.has("from"):
		start_point = args['from'] as float
	
	if args.has("to"):
		end_point = args['to'] as float
	else:
		if end_point == -1:
			end_point = stream.get_length()
	
	if args.has("loopfrom"):
		loop_point = args["loopfrom"]
	else:
		if loop_point == -1:
			loop_point = start_point
	

# Function to convert determined value of volume (within percent) to dB
# (the format accepted by Godot stream player)
func _convert_ratio_to_db(ratio := 0.0):
	return 20.0 * log(ratio)

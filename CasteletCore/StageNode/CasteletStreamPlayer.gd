# This Node is a custom node derived from AudioStreamPlayer that is customized
# to enable finer control over the audio player, such as enabling fade-in/fadeout
# effect using Tween class and starting/stopping/looping audio track on certain
# points.

extends AudioStreamPlayer
class_name CasteletStreamPlayer

var fadein = 0.0
var fadeout = 0.0
var start_point = 0.0
var loop_from = -1
var end_point = -1
var loop = false
var _audio_tween : Tween
var mute_vol_db := -40.0
var set_vol_db := 0.0
var max_loop_count : int = 0
var current_loop_count : int = 0

var queue := []
var queue_id = 0
var queue_length = 0

# Borrowed from https://github.com/godotengine/godot/issues/56156#issuecomment-1727974198
# signal audio_finished
@onready var finished_timer = Timer.new()

func _ready():
	finished.connect(_on_finished)
	finished_timer.timeout.connect(_on_finished_timer_timeout)
	add_child(finished_timer)
	# audio_finished.connect(_on_finished)

func _exit_tree():
	finished.disconnect(_on_finished)
	finished_timer.timeout.disconnect(_on_finished_timer_timeout)
	# audio_finished.disconnect(_on_finished)

# Handle custom end-point and fadeout during frame updates.
func _process(_delta):
	if is_playing:
		if loop and len(queue) == 0:
			if ((end_point != -1) and get_playback_position() >= end_point):
				seek(loop_from)
		else:
			if ((end_point != -1) and get_playback_position() >= end_point - fadeout):
				# Check if currently in finite loop mode and has reached the limit
				# or not
				if current_loop_count >= max_loop_count:
				# Make sure to fire the fadeout tween only once.
					if _audio_tween == null or (_audio_tween != null and not _audio_tween.is_running()):
						stop_stream()
				# else:
				# 	finished.emit()

# func _check_is_finished():
# 	if not playing:
# 		audio_finished.emit()
# 		finished_timer.stop()
# 		return

func _on_finished_timer_timeout():
	finished.emit()

# Because Godot has no signal for signifying loop is performed, for finite loop,
# we make use of the "finished" signal instead since technically the loop is off
# (in other words, we manually replay it)
func _on_finished():
	if len(queue) == 0 and max_loop_count > 0 and current_loop_count < max_loop_count:
		current_loop_count += 1
		play(loop_from)
	else:
		if queue_id < queue_length - 1:
			queue_id += 1
			init_stream(queue[queue_id])
			end_point = queue[queue_id].get_length()
			play_stream()
		else:
			if loop and len(queue) > 0:
				queue_id = 0
				init_stream(queue[queue_id])
				end_point = queue[queue_id].get_length()
				play_stream()
	

# This class doesn't allow overriding play() function apparently, so to implement
# fadein, we need to create new function altogether.
func play_stream():
	
	if (fadein > 0.0):
		fade_audio(mute_vol_db, set_vol_db, fadein)
	
	play(start_point)
	finished_timer.start(end_point - loop_from)


# Ditto for stop() function.
func stop_stream():
	
	if (fadeout > 0.0):
		fade_audio(set_vol_db, mute_vol_db, fadeout)
		await _audio_tween.finished
	stop()
	volume_db = set_vol_db


# Fadein and fadeout has inherently similar way of working, so we'll just write
# custom function that handles both.
func fade_audio(from : float =-20.0, to :=0.0, duration :=1.0):
	
	if _audio_tween:
		_audio_tween.kill()
	
	_audio_tween = create_tween()
	_audio_tween.tween_property(self, "volume_db", to, duration).from(from)

func clear_queue():
	queue = []
	queue_id = 0
	queue_length = 0

func init_queue(input_queue = [], args := {}):
	queue = input_queue
	queue_length = len(queue)

	# TODO: enable "queue audio and wait until current track finishes playing"

	init_stream(queue[0] as AudioStream, args)
	stream.set_loop(false)


# A custom function to set up the stream player parameters (e.g. fadein and
# fadeout time) before actually playing the audio.
func init_stream(track : AudioStream, args := {}):
	
	if track != null:
		stream = track
		
	set_vol_db = volume_db
	
	if args.has("loop"):
		# Godot does not have inherent loop signal or inherent
		# finite loop option right now, so for now, we actually disable
		# the loop option and make use of "finished" signal instead
		if (args['loop'] == true and not args.has("loopcount")):
			if stream != null:
				stream.set_loop(true)
			loop = true
		else:
			if stream != null:
				stream.set_loop(false)
			loop = false
	
	if args.has("volume"):
		set_vol_db = _convert_ratio_to_db(args["volume"] as float)
		volume_db = set_vol_db
	
	if args.has("fadein"):
		fadein = args['fadein'] as float
	
	if args.has("fadeout"):
		fadeout = args['fadeout'] as float
	
	if args.has("from"):
		start_point = args['from'] as float
	
	if args.has("to"):
		end_point = args['to'] as float
	else:
		if end_point == -1 and stream != null:
			end_point = stream.get_length()
	
	if args.has("loopfrom"):
		loop_from = args["loopfrom"]
	else:
		if loop_from == -1:
			loop_from = start_point
	if stream != null:
		stream.set_loop_offset(loop_from)
	
	if args.has("loopcount"):
		max_loop_count = args['loopcount'] as int
		if max_loop_count < 0:
			max_loop_count = 0
	

# Function to convert determined value of volume (within percent) to dB
# (the format accepted by Godot stream player)
func _convert_ratio_to_db(ratio := 0.0):
	return 20.0 * log(ratio)

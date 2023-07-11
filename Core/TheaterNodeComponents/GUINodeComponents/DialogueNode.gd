# This node serves to control how a dialogue text is displayed (i.e. based on
# text speed, display instantly on button press, show "click-to-continue" indicator)
# 
# Do note that by default, the dialogue box is NOT shown.
extends Control

@export var cps : float = 20
@export var window_transition_speed : float = 0.5

var _tween : Tween
var _pause_locations : Array = []
var _pause_durations : Array = []
var _text_length = 0
var _next_stop = 0
var _is_skipping = false
@onready var _text = $Dialogue/DialogueLabel

signal window_transition_completed
signal message_paused
signal message_completed
signal request_continue

# In the beginning, set all child nodes to invisible
func _ready():
	
	InputManager.castelet_confirm.connect(_on_castelet_confirm)
	InputManager.castelet_skip.connect(_on_castelet_skip)
	
	if CasteletConfig.base_text_speed != null:
		cps = CasteletConfig.base_text_speed
	
	_hide_subcomponents()
	hide()


# Function to hide all sub-components of dialogue node
func _hide_subcomponents():
	
	$CTC_Indicator.hide()
	$Speaker.hide()
	$Dialogue/DialogueLabel.hide()


func _process(_delta):
	if _is_skipping:
		_fast_forward()


# This is the main function to be called every time we want to display the dialogue.
func show_dialogue(speaker : String, dialogue : String, pause_locations : Array=[], pause_durations : Array=[]):
	
	# For each call, hide the click-to-continue indicator first.
	# It will be shown again when user can continue.
	$CTC_Indicator.hide()
	
	# Preemptively set the speaker name and the dialogue to be displayed
	# before actually showing them, as well as some control variables.
	$Speaker/SpeakerLabel.text = speaker
	$Dialogue/DialogueLabel.text = dialogue
	_pause_locations = pause_locations
	_pause_durations = pause_durations
	_text_length = len(dialogue)
	if not _pause_locations.is_empty():
		_pause_locations.append(_text_length)

	# If the window is hidden, show it using tween/transition.
	if not visible:
		window_transition(0.0, 1.0)
		await window_transition_completed
	
#	print_debug(speaker == "")
	if speaker == "" or speaker == "narrator":
		$Speaker.hide()
	else:
		$Speaker.show()
	
	# Properly animate the dialogue if skip mode is not activated
	if not _is_skipping:
		_animate_dialogue()
	# else:
	# 	_fast_forward()
	


func window_transition(old := 0.0, new := 1.0):
	
	_hide_subcomponents()
	
	# Before doing the window transition, reset any previous instances of tween
	if _tween:
		_tween.kill()
	
	# Maintain the illusion of invisibility
	modulate.a = old
	if new > old:
		show()
	
	# Do the actual tweening for displaying the window
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_property($".", "modulate:a", new, window_transition_speed).from(old)
	await _tween.finished
	
	if old > new:
		hide()
	
	emit_signal("window_transition_completed")


func _animate_dialogue():
	# Calculate the time required to display all texts based on the set speed
	var duration := (_text_length / cps) as float
	
	# Before executing the tween, reset any previous instances of tween
	if _tween:
		_tween.kill()
	
	# Do the actual tweening. This is more complex by the virtue of the dialogues
	# having variable length and possible pauses.
	_tween = create_tween()
	_tween.tween_property(_text, "visible", true, 0.0).from(false)
	
	# If no pauses are detected, do the standard tweening on the "visible characters"
	# parameter.
	# Otherwise, we need to create a chain of complex tweens based on the detected
	# pauses and their duration
	if _pause_locations.is_empty():
		_tween.tween_property(_text, "visible_characters",
			_text_length, duration).from(0)
	else:
		# Temporary variable to store last starting point of the tween
		var starting : int = 0
		_text.visible_characters = 0
		
		# Create additional tweens based on the pause locations and their
		# durations. If the pause value is 0, it means it waits for user input
		# instead.
		# Do note that since tweens in Godot4.x seem to do its own thing, we
		# need to use callbacks for manipulating stuffs like showing the
		# click-to-continue indicator or pausing the tween.
		for i in range(len(_pause_locations)):
			
			_next_stop = _pause_locations[i]
			
			_tween.tween_callback($CTC_Indicator.hide)
			_tween.tween_property(_text, "visible_characters",
				_next_stop, duration * (_next_stop - starting) / _text_length)
			
			# The lines of code below are only applicable if we're not nearing
			# the end of the dialogue
			if _next_stop < _text_length:
				
				_tween.tween_callback(emit_signal.bind("message_paused"))
				
				if _pause_durations[i] == 0.0:
					CasteletGameManager.enter_standby.emit()
					_tween.tween_callback(_tween.pause)
				else:
					_tween.tween_interval(_pause_durations[i])
				
				starting = _next_stop + 1
	
	await _tween.finished
	
	if _text.visible_characters >= _text_length:
		emit_signal("message_completed")


# The specific functionality to be called when fast-forwarding is active.
func _fast_forward():
	print_debug("Skip mode acitvated")
	
	if _tween:
		_tween.kill()
	
	if _text.visible_characters < _text_length:
		_text.visible_characters = _text_length
	elif _text.visible_characters >= _text_length:
		emit_signal("request_continue")


# Signal callback functions go here
func _on_castelet_confirm():
	if _text.visible_characters < _text_length and _pause_locations.is_empty():
		_tween.custom_step(INF)
	elif _text.visible_characters < _text_length and not _pause_locations.is_empty():
		if _tween.is_running():
			# FIXME: There is discrepancy between the detected next stop and the actual
			# one.
			_tween.custom_step((_next_stop - _text.visible_characters)) # Dirty implementation.
		else:
			$CTC_Indicator.hide()
			_tween.play()
	elif _text.visible_characters >= _text_length and $CTC_Indicator.visible:
		# emit_signal("request_continue")
		CasteletGameManager.progress.emit()


func _on_castelet_skip(param: bool):
	if param == true:
		_is_skipping = true
		# _fast_forward() # For some reasons, there is a delay when implemented here, so we activate it at _process instead
	else:
		_is_skipping = false
		_text.visible_characters = _text_length
		emit_signal("message_completed")


func _on_message_completed():
	CasteletGameManager.enter_standby.emit()
	$CTC_Indicator.show()


func _on_message_paused():
	$CTC_Indicator.show()

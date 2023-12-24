# This node is where a single line of dialogue is displayed on, and this node serves to
# control how a dialogue text is displayed (i.e. based on text speed, display instantly
# on interruption, show "click-to-continue" indicator, etc).
# Do note that by default, the dialogue box is NOT shown.
# 
# For the sake of clarity, here are the following limitations imposed on this node:
# - This node is a character dialogue node. It can show the dialogue window, hide it,
#   and display one given line of dialogue whether gradually or instantenuously (e.g. during
#   fast-forwarding mode).
# - Again, this node is only for displaying dialogue. It has no authority to process inputs or
#   changes from the game, BUT it can be controlled by nodes above to respond accordingly.
# - This node is NOT SUPPOSED TO INTERACT with the nodes above, or any singletons for that matter.
#   As such, avoid using singleton events here -- provide relevant functions instead, and let
#   parent nodes to handle them.
#
# Because of these limitations, it is entirely possible to instantiate dialogue node as its own
# without fully relying on Castelet framework's events or predefined input.
# Just call the proper functions and use appropriate signals, and it should be easily integratable
# in other nodes.
# 
# In general, this node is comprised of the following:
# Variables:
# - cps (export)                        - Characters per second - determines how fast one line of
#                                         dialogue is displayed from start to finish.
# - window_transition_speed (export)    - Determines how fast the dialogue window changes visibility
# - completed                           - Denotes whether the dialogue has all been displayed or not
# - _tween (internal)                   - Holds Tween instance to control non-instantenuous dialogue
#                                         display. Due to how the new Tween works, ALWAYS check if a
#                                         Tween instance exists and kill it before creating another
#                                         Tween instance (i.e. start new tween)
# - _pause_locations (internal)         - The extracted points at which the dialogue display should
#                                         temporarily be stopped.
# - _pause_durations (internal)         - How long must the node wait before resuming text display
#                                         at every pause points.
#                                         0.0 means the node waits for user input (or any sort of
#                                         interruption) before resuming.
# - _text_length (internal)             - Total amount of characters to be displayed in one line of
#                                         dialogue.
#                                         Required to handle some pause behaviors.
# - _next_stop (internal)               - Holds data at which point will the text display be paused
#                                         or stopped. Required to handle some pause behaviors.
# - _text (internal, on ready)          - Holds the node instance for the dialogue text node.
#
# Signals:
# - window_transition_completed         - Fired when the dialogue box has finished displaying or
#                                         hiding itself.
# - message_display_paused              - Fired when the dialogue display is stopped in the middle.
# - message_display_completed           - Fired when the dialogue display has been completed.
# - request_refresh                     - Can be fired when user wants to display next instance of
#                                         dialogue. Unused in current version -- it is advisable to
#                                         handle the redraw request on another, upper-level node.
#
# Functions:
# - _ready() 				            - Called when node has entered scene tree. Perform initialization
#                                         such as connecting necessary signals to relevant callbacks,
#                                         and hide this node at start.
# - show_dialogue()			            - Called when user wants to display a line of dialogue.
#                     		              Input consists the dialogue speaker's name, the dialogue content,
#                                         "instant" (whether the dialogue will be displayed instantenuously
#                                         or gradually), pause locations, and pause durations.
# - window_transition() 	            - For manipulating the visibility of this node from the "old"
#                                         opacity value to the "new" value
# - _animate_dialogue() 	            - Contains a series of tweening operations to display the
#                                         dialogue gradually.
# - process_interrupt() 	            - Can be called from outside to handle interruptions on text
#                                         display process (i.e. immediately displays all texts upon
#                                         interruption).
# - _hide_subcomponents()               - Hides all child nodes of this node.
#
# Signal callbacks:
# - _on_window_transition_completed     - Internal handling of window_transition_completed signal
# - _on_message_display_completed       - Internal handling of message_display_completed signal
#                                         Changes the "completed" variable to true and displays
#                                         click-to-continue indicator by default.
# - _on_message_display_paused          - Internal handling of message_display_paused signal
#                                         Displays click-to-continue indicator by default.
#
extends Control

@export var cps : float = 20
@export var window_transition_speed : float = 0.5
var completed = false
var auto_dismiss = false

var _tween : Tween
var _pause_locations : Array = []
var _pause_durations : Array = []
var _text_length = 0
var _next_stop = 0

@onready var _text = $Dialogue/DialogueLabel

signal window_transition_completed
signal message_display_paused(duration : float)
signal message_display_completed(auto : bool)
signal dialogue_window_status_changed(completed: bool, completed_auto: bool, duration: float)
# signal request_refresh


func _ready():

	# Connect to internal signals
	window_transition_completed.connect(_on_window_transition_completed)
	message_display_completed.connect(_on_message_display_completed)
	message_display_paused.connect(_on_message_display_paused)

	# In the beginning, hide this node and all of the sub-nodes
	_hide_subcomponents()
	hide()
	

func show_dialogue(speaker : String = "", dialogue : String = "", instant : bool = false,
					args = {}):
	
	completed = false

	if args.has("auto_dismiss"):
		auto_dismiss = args["auto_dismiss"]
	else:
		auto_dismiss = false
	
	var starting_length := 0
	if speaker == "extend":
		starting_length = len($Dialogue/DialogueLabel.get_parsed_text())

	# For each call, hide the click-to-continue indicator first.
	# It will be shown again when user can continue.
	$CTC_Indicator.hide()
	
	# Preemptively set the speaker name and the dialogue to be displayed
	# before actually showing them, as well as some control variables.
	if speaker != "extend":
		$Speaker/SpeakerLabel.clear()
		$Dialogue/DialogueLabel.clear()
		$Speaker/SpeakerLabel.append_text(speaker)
	$Dialogue/DialogueLabel.append_text(dialogue)
	
	_pause_locations = []
	_pause_durations = []
	if args.has("pause_locations"):
		for _pause in args["pause_locations"]:
			_pause_locations.append(_pause + starting_length)
	if args.has("pause_durations"):
		_pause_durations = args["pause_durations"]
	
	_text_length = starting_length + len(dialogue)

	if not _pause_locations.is_empty(): # Add the text length as the final stop
		_pause_locations.append(_text_length)

	# If the window is hidden, show it using tween/transition.
	if not visible:
		window_transition(0.0, 1.0)
		await window_transition_completed
	
	# If the narrator is speaking, hide the speaker window
	if speaker == "" or speaker == "narrator":
		$Speaker.hide()
	else:
		$Speaker.show()
	
	# Actually display the dialogue.
	if not instant:
		_animate_dialogue(starting_length)
	else:
		_text.visible_characters = _text_length
		_text.visible = true
		message_display_completed.emit(auto_dismiss)
	

func window_transition(old: float = 0.0, new: float = 1.0):
	
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
	
	window_transition_completed.emit()


func _animate_dialogue(initial_visible_characters := 0):

	# First, calculate the time required to display all texts based on the set speed
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
	# pauses and their duration.
	if _pause_locations.is_empty():
		_tween.tween_property(_text, "visible_characters",
			_text_length, duration).from(initial_visible_characters)
	else:
		# Temporary variable to store last starting point of the tween
		var starting : int = initial_visible_characters
		_text.visible_characters = initial_visible_characters
		
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
				
				_tween.tween_callback(emit_signal.bind("message_display_paused", _pause_durations[i]))
				
				if _pause_durations[i] == 0.0:
					_tween.tween_callback(_tween.pause)
				else:
					# FIXME: using tween_interval will automatically display remaining text instead
					# of stopping at pause if it is interrupted before the pause.
					_tween.tween_interval(_pause_durations[i])
				
				starting = _next_stop + 1
	
	# Wait for the message display to complete before sending the signal
	await _tween.finished

	# Debugging line to trace the source of [nw] tag bug
	print_debug("foo")
	print_debug(_text.visible_characters)
	print_debug(_text_length)

	if _text.visible_characters >= _text_length:
		print_debug("meow")
		message_display_completed.emit(auto_dismiss)


func process_interrupt(instant : bool = false):
	if instant:
		if _tween:
			_tween.kill()
		
		if _text.visible_characters < _text_length:
			_text.visible_characters = _text_length
		_text.visible = true
		message_display_completed.emit(auto_dismiss)
	
	else:
		if _text.visible_characters < _text_length and _pause_locations.is_empty():
			if _tween:
				_tween.custom_step(INF)
		elif _text.visible_characters < _text_length and not _pause_locations.is_empty():
			if _tween:
				if _tween.is_running():
					# FIXME: There is discrepancy between the detected next stop and the actual
					# one.
					_tween.custom_step((_next_stop - _text.visible_characters)) # Dirty implementation.
				else:
					$CTC_Indicator.hide()
					_tween.play()
		# elif _text.visible_characters >= _text_length and $CTC_Indicator.visible:
		# 	request_refresh.emit()


# Function to hide all sub-components of dialogue node
func _hide_subcomponents():
	
	$CTC_Indicator.hide()
	$Speaker.hide()
	$Dialogue/DialogueLabel.hide()


# Signal handling functions go here
func _on_window_transition_completed():
	pass


func _on_message_display_completed(auto = false):
	# Debugging line to trace the source of [nw] tag bug
	print_debug("bar")

	$CTC_Indicator.show()
	completed = true
	dialogue_window_status_changed.emit(true, auto, 0.0)


func _on_message_display_paused(duration : float):
	$CTC_Indicator.show()
	completed = false
	dialogue_window_status_changed.emit(false, false, duration)


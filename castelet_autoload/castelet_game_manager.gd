# This node is an autoload/singleton node that serves as "game manager" -- namely, to handle
# various events those happen during runtime. For example, this node keeps tract whether the
# fast-forward or auto-read mode is activated, and send events/signals related to these changes
# accordingly.
# 
# This node is NOT intended to listen to other nodes, nor is it requiring dependency on another
# except for CasteletConfig.
# Instead, this node provides events/signals those can be used by other nodes, and handle
# changes based on the signals accordingly
# 
# This node is dependent on the following autoloads:
# - CasteletConfig
#
# In general, this node is comprised of the following:
# Variables:
# - backlog		                        - Contains data of previously-displayed dialogues.
# - ffwd_active						    - Determines whether fast-forwarding mode is active or not.
# - auto_active						    - Determines whether auto-read mode is active or not.
# - _paused (internal)                  - Determines whether the overall Castelet node is paused or not.
#										  Intended to help with stuffs such as pausing auto-read mode.
# - _standby (internal)		            - Determines whether the node is currently in standby/idle mode
#										  or not, and thus can proceed to read next command if prompted.
# - _automode_timer (internal)          - Holds timer instance to be executed while auto-read is active.
#
# Signals:
#

extends Node

var parser = preload("res://castelet_core/parser/castelet_script_parser.gd").new()
var script_trees = {}
var jump_checkpoints_list = {}
var vars = {}
var persistent = {}

var backlog = []
var backlog_max_limit = 200

var _callsub_stack = []
var _context_level = 0

var ffwd_active := false
var auto_active := false :
	set(value):
		auto_active = value
		toggle_automode.emit()

var _automode_timer : Timer
var _paused := false
var _standby := false :
	set(value):
		_standby = value

var menu_showing = false


signal confirm
signal ffwd_hold(state : bool)
signal ffwd_toggle

signal backlog_update(new_data : Dictionary, replace : bool)
signal toggle_automode
signal enter_standby
signal progress


func _script_loader_callback(file_name : String):

	if file_name.ends_with(".tsc"):		
		parser.execute_parser(file_name)
		

func _ready():

	# Go through the resource directory to check all script files
	CasteletResourceLoader.load_all_resources_of_type("res://", self, "_script_loader_callback")

	# Initialize some signal connections, whether from internal or other nodes
	enter_standby.connect(_on_standby)
	toggle_automode.connect(_on_toggle_automode)
	progress.connect(_on_progress)

	ffwd_hold.connect(_on_ffwd_hold)
	ffwd_toggle.connect(_on_ffwd_toggle)
	

	# Initialize automode timer
	_automode_timer = Timer.new()
	add_child(_automode_timer)
	if CasteletConfig.base_automode_timeout != null:
		_automode_timer.wait_time = CasteletConfig.base_automode_timeout
	else:
		_automode_timer.wait_time = 3
	_automode_timer.timeout.connect(_on_automode_timer_timeout)

	if auto_active:
		_automode_timer.start()
	

func append_dialogue(dialogue_data: Dictionary):

	if len(backlog) >= backlog_max_limit:
		var _old = backlog.pop_front()
	
	backlog.append(dialogue_data)
	backlog_update.emit(dialogue_data, false)


func append_dialogue_extend(dialogue_data: Dictionary):
	if len(backlog) >= backlog_max_limit:
		var _old = backlog.pop_front()
	
	var current_dialogue = backlog.pop_back()
	current_dialogue['dialogue'] += dialogue_data['dialogue']
	if current_dialogue["args"].has("auto_dismiss"):
		current_dialogue['args']['auto_dismiss'] = dialogue_data['args']['auto_dismiss']
	backlog.append(current_dialogue)

	backlog_update.emit(current_dialogue, true)
	

func toggle_pause(state : bool):
	_paused = state

	if auto_active:
		_automode_timer.paused = _paused


func get_context_level():
	return _context_level


func _advance_context_level():
	_context_level += 1


func _reduce_context_level():
	if _context_level > 0:
		_context_level -= 1


func append_callsub_stack(source : String, index : int):
	_callsub_stack.append({
		"tree" : source,
		"index" : index,
		"level" : _context_level,
	})
	_advance_context_level()


func pop_callsub_stack():
	_reduce_context_level()
	return _callsub_stack.pop_back()


func _on_standby():
	_standby = true
	if auto_active:
		_automode_timer.start()


func _on_toggle_automode():
	if auto_active:
		# print_debug("auto mode enabled")
		if _standby:
			_automode_timer.start()
	else:
		# print_debug("auto mode disabled")
		_automode_timer.stop()
		

func _on_automode_timer_timeout():

	# Instead of emitting 'progress' signal (which signifies to read the next part of the scene),
	# we forcibly emulate "confirm" input to handle things those may not require progressing
	# to next scene yet
	_standby = false
	if auto_active:
		_automode_timer.stop()
	confirm.emit()


func _on_progress():
	_standby = false
	if auto_active:
		_automode_timer.stop()


func _on_ffwd_hold(state: bool):
	ffwd_active = state


func _on_ffwd_toggle():
	ffwd_active = !ffwd_active

func print(s1 : String, s2: String):
	prints(s1, s2)

# This node is an autoload/singleton node that serves as "game manager" -- namely, to handle
# various events those happen during runtime. For example, this node keeps tract whether the
# fast-forward or auto-read mode is activated, and send events/signals related to these changes
# accordingly.
# 
# This node is NOT intended to listen to other nodes, nor is it requiring dependency on another
# except for _config_manager.
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
class_name CasteletGameManager

var _parser = preload("res://castelet/castelet_core/parser/castelet_script_parser.gd").new()
var script_trees = {}
var jump_checkpoints_list = {}
var _vars = {}
var _persistent = {}

var backlog = []
var backlog_max_limit = 200

var _current_script_tree = ""
var _current_script_tree_index = 0
var _callsub_stack = []
var _context_level = 0

var _temp_script_tree = ""
var _temp_script_tree_index = 0
var _temp_callsub_stack = []
var _temp_context_level = 0
var _temp_backlog = []

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

var _mutex : Mutex
var _script_ready := false
@export var _script_directory := "res://"

@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")

signal confirm
signal ffwd_hold(state : bool)
signal ffwd_toggle

signal backlog_update(new_data : Dictionary, replace : bool)
signal backlog_purge
signal toggle_automode
signal enter_standby
signal progress
signal script_tree_updated(script_tree : String, index : int)
signal script_tree_override

signal persistent_updated(name, value)


func _script_loader_callback(file_name : String):

	if file_name.ends_with(".ths"):		
		_parser.execute_parser(file_name)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:

		_mutex = Mutex.new()

		_parser.add_to_checkpoints_list.connect(
			func(checkpoint_name : String, checkpoint_data : Dictionary):
				jump_checkpoints_list[checkpoint_name] = checkpoint_data
		)
		_parser.add_to_script_tree.connect(
			func(tree_name : String, tree : CasteletSyntaxTree):
				script_trees[tree_name] = tree
		)

		var thread = Thread.new()
		thread.start(_load_script_subprocess)
		thread.wait_to_finish()
		_script_ready = true
	

func _load_script_subprocess():
	# Go through the resource directory to check all script files
	_mutex.lock()
	var _res_loader : CasteletResourceLoader = CasteletResourceLoader.new()
	var _result = _res_loader.load_all_resources_of_type(_script_directory, self, "_script_loader_callback")
	_mutex.unlock()
	

func is_script_ready() -> bool:
	return _script_ready


func _ready():
	# Initialize some signal connections, whether from internal or other nodes
	enter_standby.connect(_on_standby)
	toggle_automode.connect(_on_toggle_automode)
	progress.connect(_on_progress)

	ffwd_hold.connect(_on_ffwd_hold)
	ffwd_toggle.connect(_on_ffwd_toggle)
	_config_manager.config_updated.connect(_on_automode_timeout_changed)

	script_tree_updated.connect(_on_script_tree_updated)
	script_tree_override.connect(_on_script_tree_override)

	# Initialize automode timer
	_automode_timer = Timer.new()
	add_child(_automode_timer)
	if _config_manager.get_config(_config_manager.ConfigList.AUTOMODE_TIMEOUT) != null:
		_automode_timer.wait_time = _config_manager.get_config(_config_manager.ConfigList.AUTOMODE_TIMEOUT)
	else:
		_automode_timer.wait_time = 3
		_config_manager.set_config(_config_manager.ConfigList.AUTOMODE_TIMEOUT, 3)
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


func _on_automode_timeout_changed(conf, val):
	if conf == _config_manager.ConfigList.AUTOMODE_TIMEOUT:
		_automode_timer.wait_time = val
	
	# TODO: restart the timer if auto-mode is active


func _on_progress():
	_standby = false
	if auto_active:
		_automode_timer.stop()


func _on_ffwd_hold(state: bool):
	ffwd_active = state


func _on_ffwd_toggle():
	ffwd_active = !ffwd_active


func _on_script_tree_updated(script_tree : String, index : int):
	_current_script_tree = script_tree
	_current_script_tree_index = index


func set_variable(var_name : String, var_value, persistent := false):
	if persistent == true:
		_persistent[var_name] = var_value
		persistent_updated.emit.call_deferred(var_name, var_value)
	else:
		_vars[var_name] = var_value
	

func get_variable(var_name : String, persistent := false) -> Variant:

	if persistent == true:
		if not _persistent.keys().has(var_name): # find_key() bonked for some reasons
			return null
		return _persistent[var_name]
	
	if not _vars.keys().has(var_name):
		return null
	return _vars[var_name]


func get_all_variables(persistent := false) -> Dictionary:
	if persistent == true:
		return _persistent
	else:
		return _vars


func get_script_data():
	var script_data_dict = {}
	script_data_dict["script"] = _current_script_tree
	script_data_dict["index"] = _current_script_tree_index
	script_data_dict["callsub_stack"] = _callsub_stack
	script_data_dict["context_lv"] = _context_level
	script_data_dict["backlog"] = backlog

	return script_data_dict


func set_script_data_temp(script_data_dict : Dictionary):
	_temp_script_tree = script_data_dict["script"]
	_temp_script_tree_index = script_data_dict["index"]
	_temp_callsub_stack = script_data_dict["callsub_stack"]
	_temp_context_level = script_data_dict["context_lv"]
	_temp_backlog = script_data_dict["backlog"]


func _on_script_tree_override():
	_current_script_tree = _temp_script_tree
	_current_script_tree_index = _temp_script_tree_index
	_context_level = _temp_context_level
	
	_callsub_stack.clear()
	for st in _temp_callsub_stack:
		_callsub_stack.append(st)
	_temp_callsub_stack.clear()

	backlog.clear()
	backlog_purge.emit()
	for bl in range(len(_temp_backlog) - 1): # Avoid duplicate backlog entry after loading
		append_dialogue(_temp_backlog[bl])
	_temp_backlog.clear()

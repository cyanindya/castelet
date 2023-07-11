extends Node


var backlog = []

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
		print_debug(value)


signal backlog_update(new_data : Dictionary)
signal toggle_automode
signal enter_standby
signal progress


func _ready():

	# Initialize some internal signal connections
	enter_standby.connect(_on_standby)
	toggle_automode.connect(_on_toggle_automode)
	progress.connect(_on_progress)

	# Initialize automode timer
	_automode_timer = Timer.new()
	add_child(_automode_timer)
	_automode_timer.wait_time = CasteletConfig.base_automode_timeout
	_automode_timer.timeout.connect(_on_automode_timer_timeout)

	if auto_active:
		_automode_timer.start()
	

func append_dialogue(dialogue_data: Dictionary):
	backlog.append(dialogue_data)
	backlog_update.emit(dialogue_data)


func toggle_pause(state : bool):
	_paused = state

	if auto_active:
		_automode_timer.paused = _paused


func _on_standby():
	_standby = true
	if auto_active:
		_automode_timer.start()


func _on_toggle_automode():
	if auto_active:
		print_debug("auto mode enabled")
		if _standby:
			_automode_timer.start()
	else:
		print_debug("auto mode disabled")
		_automode_timer.stop()
		

func _on_automode_timer_timeout():

	# Instead of emitting 'progress' signal (which signifies to read the next part of the scene),
	# we forcibly emulate "confirm" input to handle things those may not require progressing
	# to next scene yet
	_standby = false
	if auto_active:
		_automode_timer.stop()
	InputManager.castelet_confirm.emit()


func _on_progress():
	_standby = false
	if auto_active:
		_automode_timer.stop()

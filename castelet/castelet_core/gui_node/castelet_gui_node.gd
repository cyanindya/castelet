#
# This node is dependent on the following singletons:
# - CasteletGameManager
# - CasteletConfig
#

extends CanvasLayer

const ChoiceNode = preload("res://castelet/castelet_core/gui_node/choice_menu/castelet_choice_node.tscn")

@onready var _game_manager : CasteletGameManager = get_node("/root/CasteletGameManager")
@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")
@onready var _viewport_manager : CasteletViewportManager = get_node("/root/CasteletViewportManager")
@onready var _state_manager : CasteletStateManager = get_node("/root/CasteletStateManager")

signal choice_made(sub)


func _ready():
	_game_manager.confirm.connect(_dialogue_node_interrupt)
	_game_manager.backlog_update.connect(_on_backlog_updated)
	_config_manager.config_updated.connect(_on_config_updated)
	_viewport_manager.viewport_resized.connect(_on_viewport_resized)
	
	choice_made.connect(_on_choice_made)

	if _config_manager.get_config(_config_manager.ConfigList.TEXT_SPEED) != null:
		$DialogueNode.cps = _config_manager.get_config(_config_manager.ConfigList.TEXT_SPEED)


func _process(_delta):

	var stop_ffwd_on_menu_show =  (
			_game_manager.menu_showing == true
			and _config_manager.get_config(_config_manager.ConfigList.FORCE_STOP_FFWD_ON_CHOICE) == true
	)

	if _game_manager.ffwd_active and not stop_ffwd_on_menu_show:
		_dialogue_node_interrupt(true)


# The function to show the dialogue. The process is as follows:
# - show the dialogue window if it's hidden
# - show the text gradually based on text speed, 
# - when it finishes displaying, send a signal that the script can proceed
func update_dialogue(dialogue_data : Dictionary):
	$DialogueNode.show_dialogue(dialogue_data["speaker"], dialogue_data["dialogue"],
								_game_manager.ffwd_active,
								dialogue_data["args"]
								)

func show_window():
	await $DialogueNode.window_transition(0.0, 1.0)
	_game_manager.progress.emit()


func hide_window():
	await $DialogueNode.window_transition(1.0, 0.0)
	_game_manager.progress.emit()
	

func _dialogue_node_interrupt(instant : bool = false):
	if $DialogueNode.completed:
		_game_manager.progress.emit()
	else:
		$DialogueNode.process_interrupt(instant)


func _on_automode_button_toggled(button_pressed: bool):
	$QuickMenuControl.accept_event()
	_game_manager.auto_active = button_pressed


# func _on_dialogue_node_request_refresh():
# 	_game_manager.progress.emit()


# To avoid execution order conflict, we use the signal from DialogueNode that will only
# be emitted when all of the status changes had been completed.
func _on_dialogue_node_dialogue_window_status_changed(completed, completed_auto, duration):
	if not completed:
		if duration == 0.0:
			_game_manager.enter_standby.emit()
	else:
		if completed_auto:
			_game_manager.progress.emit()
		else:
			_game_manager.enter_standby.emit()


func _on_backlog_button_pressed():
	$QuickMenuControl.accept_event()
	$BacklogNode.show()


func _on_backlog_updated(backlog_entry : Dictionary, replace = false):
	$BacklogNode.update_backlog(backlog_entry, replace)


func _on_backlog_window_visibility_changed():
	_game_manager.toggle_pause($BacklogNode.visible)
	_game_manager.set_block_signals($BacklogNode.visible)


func show_choices(choices := []):
	for choice in choices:
		# modify this if you want to make the choice still visible
		# but still disabled when the conditions aren't fulfilled.
		if choice["condition"] == true:
			var choice_node = ChoiceNode.instantiate()

			choice_node.get_node("Button").text = choice["choice"]
			choice_node.subevent_id = choice["sub"]
			choice_node.subroutine.connect(_process_choice)

			$MenuNode.add_child(choice_node)

	$MenuNode.show()


func _process_choice(choice : String, sub : String):
	var choice_dialogue = {
		"speaker": "(Choice)",
		"dialogue" : choice,
		"args" : [],
	}

	_game_manager.append_dialogue(choice_dialogue)
	choice_made.emit(sub)


func _on_choice_made(_sub : String):
	var buttons = $MenuNode.get_children()
	
	for button in buttons:
		button.subroutine.disconnect(_process_choice)
		$MenuNode.remove_child(button)
		button.queue_free()
	
	$MenuNode.hide()


func _on_config_button_pressed() -> void:
	$QuickMenuControl.accept_event()
	$SettingsNode.show()


func _on_config_updated(conf, val):
	if conf == _config_manager.ConfigList.TEXT_SPEED:
		$DialogueNode.cps = val
		print_debug($DialogueNode.cps)


func _on_viewport_resized():
	var ui_scale : float = 1.0
	
	if _viewport_manager.enable_window_content_resize:
		if _config_manager.get_config(_config_manager.ConfigList.WINDOW_MODE) == _config_manager.WindowMode.FULLSCREEN:
			ui_scale = _config_manager.WINDOW_RESOLUTION_MAP[_config_manager.WindowResolutions.RES_1920_1080]["ui_scaling"]
		else:
			ui_scale = _config_manager.WINDOW_RESOLUTION_MAP[
				_config_manager.get_config(_config_manager.ConfigList.WINDOW_RESOLUTION)
			]["ui_scaling"]
	
	# Dirty scaling and may result in blurry UI elements, but this works for now.
	$DialogueNode.resize_node(ui_scale)
	$SettingsNode.resize_node(ui_scale)
	$BacklogNode.resize_node(ui_scale)
	$MenuNode.scale = Vector2(ui_scale, ui_scale)
	$QuickMenuControl.scale = Vector2(ui_scale, ui_scale)


func _on_quicksave_button_pressed():
	_state_manager.save_game_data("user://qsave.sav")


func _on_quickload_button_pressed():
	_state_manager.load_game_data("user://qsave.sav")
	await _state_manager.game_load_finish
	

extends Control

@export_node_path("CasteletGameManager") var game_manager
@export_node_path("CasteletAssetsManager") var asset_manager
@export_node_path("CasteletConfig") var config
@export_node_path("CasteletViewportManager") var vp

func _ready():
	# Before we begin, make sure the required CasteletGameManager and CasteletAssetsManager instances
	# are valid, and try to grab it from root node if necessary. Otherwise, throw an error since they're required.
	if game_manager == null:
		game_manager = get_node("/root/CasteletGameManager")
		assert(game_manager != null, "Cannot find any valid instance of CasteletGameManager. Check whether the node has been included in the scene tree and try again.")
	
	if asset_manager == null:
		asset_manager = get_node("/root/CasteletAssetsManager")
		assert(asset_manager != null, "Cannot find any valid instance of CasteletAssetsManager. Check whether the node has been included in the scene tree and try again.")
	
	if config == null:
		config = get_node("/root/CasteletConfig")
		assert(config != null, "Cannot find any valid instance of CasteletConfig. Check whether the node has been included in the scene tree and try again.")
	
	if vp == null:
		vp = get_node("/root/CasteletViewportManager")

	game_manager.confirm.connect(_dialogue_node_interrupt)
	game_manager.backlog_update.connect(_on_backlog_updated)
	$BacklogNode.visibility_changed.connect(_on_backlog_window_visibility_changed)

	if config.base_text_speed != null:
		$DialogueNode.cps = config.base_text_speed


func _process(_delta):

	if game_manager.ffwd_active:
		_dialogue_node_interrupt(true)


# The function to show the dialogue. The process is as follows:
# - show the dialogue window if it's hidden
# - show the text gradually based on text speed, 
# - when it finishes displaying, send a signal that the script can proceed
func update_dialogue(dialogue_data : Dictionary):
	$DialogueNode.show_dialogue(dialogue_data["speaker"], dialogue_data["dialogue"], game_manager.ffwd_active,
		dialogue_data["pause_locations"], dialogue_data["pause_durations"])


func show_window():
	await $DialogueNode.window_transition(0.0, 1.0)
	game_manager.progress.emit()


func hide_window():
	await $DialogueNode.window_transition(1.0, 0.0)
	game_manager.progress.emit()
	

func _dialogue_node_interrupt(instant : bool = false):
	if $DialogueNode.completed:
		game_manager.progress.emit()
	else:
		$DialogueNode.process_interrupt(instant)



func _on_automode_button_toggled(button_pressed: bool):
	accept_event()
	game_manager.auto_active = button_pressed


# func _on_dialogue_node_request_refresh():
# 	CasteletGameManager.progress.emit()


func _on_dialogue_node_message_display_paused(duration : float):
	if duration == 0.0:
		game_manager.enter_standby.emit()


func _on_dialogue_node_message_display_completed():
	game_manager.enter_standby.emit()


func _on_backlog_button_pressed():
	accept_event()
	$BacklogNode.show()

func _on_backlog_updated(backlog_entry : Dictionary):
	$BacklogNode.update_backlog(backlog_entry)

func _on_backlog_window_visibility_changed():
	game_manager.toggle_pause($BacklogNode.visible)
	game_manager.set_block_signals($BacklogNode.visible)

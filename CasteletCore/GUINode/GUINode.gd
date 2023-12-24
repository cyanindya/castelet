#
# This node is dependent on the following singletons:
# - CasteletGameManager
# - CasteletConfig
#

extends Control

func _ready():

	CasteletGameManager.confirm.connect(_dialogue_node_interrupt)
	CasteletGameManager.backlog_update.connect(_on_backlog_updated)

	if CasteletConfig.base_text_speed != null:
		$DialogueNode.cps = CasteletConfig.base_text_speed


func _process(_delta):

	if CasteletGameManager.ffwd_active:
		_dialogue_node_interrupt(true)


# The function to show the dialogue. The process is as follows:
# - show the dialogue window if it's hidden
# - show the text gradually based on text speed, 
# - when it finishes displaying, send a signal that the script can proceed
func update_dialogue(dialogue_data : Dictionary):
	$DialogueNode.show_dialogue(dialogue_data["speaker"], dialogue_data["dialogue"],
								CasteletGameManager.ffwd_active,
								dialogue_data["args"]
								)

func show_window():
	await $DialogueNode.window_transition(0.0, 1.0)
	CasteletGameManager.progress.emit()


func hide_window():
	await $DialogueNode.window_transition(1.0, 0.0)
	CasteletGameManager.progress.emit()
	

func _dialogue_node_interrupt(instant : bool = false):
	if $DialogueNode.completed:
		CasteletGameManager.progress.emit()
	else:
		$DialogueNode.process_interrupt(instant)



func _on_automode_button_toggled(button_pressed: bool):
	accept_event()
	CasteletGameManager.auto_active = button_pressed


# func _on_dialogue_node_request_refresh():
# 	CasteletGameManager.progress.emit()

# To avoid execution order conflict, we use the signal from DialogueNode that will only
# be emitted when all of the status changes had been completed.
func _on_dialogue_node_dialogue_window_status_changed(completed, completed_auto, duration):
	if not completed:
		if duration == 0.0:
			CasteletGameManager.enter_standby.emit()
	else:
		if completed_auto:
			CasteletGameManager.progress.emit()
		else:
			CasteletGameManager.enter_standby.emit()


func _on_backlog_button_pressed():
	accept_event()
	$BacklogNode.show()

func _on_backlog_updated(backlog_entry : Dictionary, replace = false):
	$BacklogNode.update_backlog(backlog_entry, replace)

func _on_backlog_window_visibility_changed():
	CasteletGameManager.toggle_pause($BacklogNode.visible)
	CasteletGameManager.set_block_signals($BacklogNode.visible)


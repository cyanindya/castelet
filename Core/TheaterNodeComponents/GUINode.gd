extends Control

signal can_continue

# The function to show the dialogue. The process is as follows:
# - show the dialogue window if it's hidden
# - show the text gradually based on text speed, 
# - when it finishes displaying, send a signal that the script can proceed
func update_dialogue(dialogue_data : Dictionary):
	$DialogueNode.show_dialogue(dialogue_data["speaker"], dialogue_data["dialogue"],
		dialogue_data["pause_locations"], dialogue_data["pause_durations"])


func show_window():
	await $DialogueNode.window_transition(0.0, 1.0)
	# emit_signal("can_continue")
	CasteletGameManager.progress.emit()


func hide_window():
	await $DialogueNode.window_transition(1.0, 0.0)
	# emit_signal("can_continue")
	CasteletGameManager.progress.emit()
	

func _on_dialogue_node_request_continue():
	emit_signal("can_continue")


func _on_backlog_button_pressed():
	accept_event()
	$BacklogNode.show()


func _on_automode_button_toggled(button_pressed: bool):
	accept_event()
	CasteletGameManager.auto_active = button_pressed


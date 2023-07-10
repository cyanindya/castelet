extends Control

@onready var _backlog_container = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var dialogue_data_node = load("res://Core/TheaterNodeComponents/GUINodeComponents/SingleDialogueLogNode.tscn")
@onready var _scroll_container = $PanelContainer/VBoxContainer/ScrollContainer
@onready var _scrollbar = $PanelContainer/VBoxContainer/ScrollContainer.get_v_scroll_bar()
var max_scroll_length = 0

func _ready():
	BacklogData.backlog_update.connect(_on_backlog_update)

	# Credits: https://www.reddit.com/r/godot/comments/qhbi8y/how_to_scroll_a_scrollcontainer_to_the_bottom/
	_scrollbar.changed.connect(_handle_scrollbar_changed)
	max_scroll_length = _scrollbar.max_value


func _on_return_button_down():
	accept_event()
	hide()


func _on_backlog_update(dialogue_data : Dictionary):
	var dat = dialogue_data_node.instantiate()
	dat.load_dialogue(dialogue_data['speaker'], dialogue_data['dialogue'])
	_backlog_container.add_child(dat)


# Credits: https://www.reddit.com/r/godot/comments/qhbi8y/how_to_scroll_a_scrollcontainer_to_the_bottom/
func _handle_scrollbar_changed():
	if max_scroll_length != _scrollbar.max_value:
		
		max_scroll_length = _scrollbar.max_value	
		_scroll_container.scroll_vertical = max_scroll_length


func _on_visibility_changed():
	if visible:
		InputManager.set_block_signals(true)
	else:
		InputManager.set_block_signals(false)

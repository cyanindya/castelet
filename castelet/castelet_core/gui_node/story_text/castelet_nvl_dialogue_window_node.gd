extends CasteletDialogueNode

const NVLDialogueEntry = preload("res://castelet/castelet_core/gui_node/story_text/castelet_nvl_dialogue_entry_node.tscn")

func _ready():

	# Connect to internal signals
	_init_signals()
	
	# In the beginning, hide this node and all of the sub-nodes
	_hide_subcomponents()
	hide()


func show_dialogue(speaker : String = "", dialogue : String = "", instant : bool = false,
					args = {}):
	if speaker != "extend":
		var dialogue_entry = NVLDialogueEntry.instantiate()
		_text = dialogue_entry.get_node("DialogueLabel")
		_speaker = dialogue_entry.get_node("SpeakerLabel")
		_speaker_label = dialogue_entry.get_node("SpeakerLabel")
		
		$PanelContainer/VBoxContainer.add_child(dialogue_entry)

	super(speaker, dialogue, instant, args)


func clear_nvl_window():
	for entry in $PanelContainer/VBoxContainer.get_children():
		$PanelContainer/VBoxContainer.remove_child(entry)
		entry.queue_free()

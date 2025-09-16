extends Control


@onready var data_id_node : Node = $Button/SaveDataContainer/VBoxContainer/HBoxContainer/DataID
@onready var data_date_node: Node = $Button/SaveDataContainer/VBoxContainer/HBoxContainer2/DataDate
@onready var data_time_node: Node = $Button/SaveDataContainer/VBoxContainer/HBoxContainer2/DataTime
@onready var data_comment_node : Node = $Button/SaveDataContainer/VBoxContainer/DataComment


signal saveload_entry_event(data_id : String)
signal request_saveload_entry_update(data_id, time, date, comment)

var saveload_entry_prefix = "#"
var saveload_entry_suffix = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_button_pressed() -> void:
	saveload_entry_event.emit(data_id_node.text.replace(saveload_entry_prefix, "").replace(saveload_entry_suffix, ""))


func _on_request_saveload_entry_update(data_id: Variant, time: Variant, date: Variant, comment: Variant) -> void:
	data_id_node.text = saveload_entry_prefix + data_id + saveload_entry_suffix
	if date.length() > 0:
		data_date_node.text = date
	if time.length() > 0:
		data_time_node.text = time
	if comment.length() > 0:
		data_comment_node.text = comment

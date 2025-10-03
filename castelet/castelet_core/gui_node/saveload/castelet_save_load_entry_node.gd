extends Control


@onready var data_id_node : Node = $Button/SaveDataContainer/VBoxContainer/HBoxContainer/DataID
@onready var data_date_node: Node = $Button/SaveDataContainer/VBoxContainer/HBoxContainer2/DataDate
@onready var data_time_node: Node = $Button/SaveDataContainer/VBoxContainer/HBoxContainer2/DataTime
@onready var data_comment_node : Node = $Button/SaveDataContainer/VBoxContainer/DataComment
@onready var thumbnail_node : Sprite2D = $Button/SaveDataContainer/VBoxContainer2/Sprite2D


signal saveload_entry_event(data_id : String)
signal request_saveload_entry_update(data_id, save_time, comment, screenshot)

var saveload_entry_prefix = "#"
var saveload_entry_suffix = ""
var thumbnail_distance_from_border : Vector2 = Vector2(7, 7)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func disable():
	$Button.disabled = true


func enable():
	$Button.disabled = false


func _on_button_pressed() -> void:
	saveload_entry_event.emit(data_id_node.text.replace(saveload_entry_prefix, "").replace(saveload_entry_suffix, ""))


func _on_request_saveload_entry_update(data_id: Variant, save_time: Variant, comment: Variant, thumbnail : Image) -> void:
	data_id_node.text = saveload_entry_prefix + data_id + saveload_entry_suffix
	if save_time.length() > 0:
		var datetime = save_time.split("T") 
		data_date_node.text = datetime[0].replace("-", "/")
		data_time_node.text = datetime[1]
	if comment.length() > 0:
		data_comment_node.text = comment	
	if thumbnail != null:
		var tex : ImageTexture = ImageTexture.create_from_image(thumbnail)
		thumbnail_node.texture = tex
		thumbnail_node.offset = tex.get_size() / 2 + thumbnail_distance_from_border

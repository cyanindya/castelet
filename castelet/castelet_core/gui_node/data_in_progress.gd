extends Control


@export var text_to_display : String = "Load in progress...":
	set(value):
		text_to_display = value
		text_changed.emit(value)

signal text_changed(text : String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_text_changed(text: String) -> void:
	$PanelContainer/Label.text = text

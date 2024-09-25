extends Control

@export var subevent_id : String = "":
	set(val):
		subevent_id = val

signal subroutine(choice, sub_name)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_button_pressed() -> void:
	var text = $Button.text
	subroutine.emit(text, subevent_id)

extends HBoxContainer

@export var label_text : String = "":
	set(value):
		label_text = value
		_label_node.text = value
@export var min_slider_value : float = 0:
	set(value):
		min_slider_value = value
		_slider_node.min_value = value
@export var max_slider_value : float = 100:
	set(value):
		max_slider_value = value
		_slider_node.max_value = value
@export var slider_value : float = 0:
	set(value):
		slider_value = clamp(value, min_slider_value, max_slider_value)


@export var _label_node : Control
@export var _slider_node : Control
@export var _slider_value_label_node : Control

signal slider_updated(value : float)


#func _on_slider_drag_ended(_value_changed: bool) -> void:
	#slider_updated.emit(slider_value)


func _on_slider_value_changed(value: float) -> void:
	slider_value = value
	_slider_value_label_node.text = str(floor(slider_value))
	slider_updated.emit(slider_value)


func set_value_no_signal(value : float):
	slider_value = value
	_slider_node.value = value

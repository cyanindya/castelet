extends Control


signal yesno(yn : bool)
signal confirm


@onready var prompt_label : RichTextLabel = $PanelContainer/VBoxContainer/PopupLabel
@onready var yesno_buttons = $PanelContainer/VBoxContainer/YesNo
@onready var confirm_button = $PanelContainer/VBoxContainer/SingleYes


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	yesno.connect(_on_yesno)
	confirm.connect(_on_confirm)
	yesno_buttons.hide()
	confirm_button.hide()


func _dismiss():
	accept_event()
	hide()


func yesno_popup(message : String):
	prompt_label.clear()
	prompt_label.append_text(message)
	confirm_button.hide()
	yesno_buttons.show()

	show()


func info_popup(message : String):
	prompt_label.clear()
	prompt_label.append_text(message)
	yesno_buttons.hide()
	confirm_button.hide()

	show()


func confirm_popup(message : String):
	prompt_label.clear()
	prompt_label.append_text(message)
	yesno_buttons.hide()
	confirm_button.show()

	show()


func _on_yesno(_yn : bool):
	_dismiss()


func _on_confirm():
	_dismiss()


func _on_button_accept():
	yesno.emit(true)


func _on_button_deny():
	yesno.emit(false)


func _on_button_confirm():
	confirm.emit()
	

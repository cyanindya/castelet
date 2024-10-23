extends Control

@onready var window_option = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer/WindowModeOptionButton
@onready var text_spd_slider = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer2/TextSpeedSlider
@onready var stop_skip_checkbox = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer3/SkipOnChoiceCheckBox
@onready var resume_skip_checkbox = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer/HBoxContainer4/ResumeSkipAfterChoiceCheckBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window_option.set_item_id(0, CasteletConfig.WindowMode.FULLSCREEN)
	window_option.set_item_id(1, CasteletConfig.WindowMode.WINDOWED)
	window_option.select(window_option.get_item_index(CasteletConfig.get_config(CasteletConfig.WINDOW_MODE)))
	text_spd_slider.set_value_no_signal(CasteletConfig.get_config(CasteletConfig.TEXT_SPEED))
	stop_skip_checkbox.set_pressed_no_signal(CasteletConfig.get_config(CasteletConfig.FORCE_STOP_FFWD_ON_CHOICE))
	resume_skip_checkbox.set_pressed_no_signal(CasteletConfig.get_config(CasteletConfig.CONTINUE_FFWD_ON_CHOICE))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_return_button_button_down() -> void:
	accept_event()
	hide()


func _on_window_mode_option_button_item_selected(_index: int) -> void:	
	CasteletConfig.set_config(CasteletConfig.WINDOW_MODE, window_option.get_selected_id())


func _on_text_speed_slider_drag_ended(value_changed: bool) -> void:
	CasteletConfig.set_config(CasteletConfig.TEXT_SPEED, text_spd_slider.value)


func _on_skip_on_choice_check_box_toggled(toggled_on: bool) -> void:
	CasteletConfig.set_config(CasteletConfig.FORCE_STOP_FFWD_ON_CHOICE, toggled_on)


func _on_resume_skip_after_choice_check_box_toggled(toggled_on: bool) -> void:
	CasteletConfig.set_config(CasteletConfig.CONTINUE_FFWD_ON_CHOICE, toggled_on)

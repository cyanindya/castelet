extends Control

# List of settings nodes
# Display-related nodes
@export var window_mode_option : Control
@export var window_resolution_option : Control

# Text settings
@export var text_speed_slider : Control
@export var auto_mode_timeout_slider : Control
@export var stop_skip_checkbox : Control
@export var resume_skip_checkbox : Control

# Audio settings
@export var master_volume_slider : Control
@export var master_volume_mute_button : Control
@export var bgm_volume_slider : Control
@export var bgm_volume_mute_button : Control
@export var sfx_volume_slider : Control
@export var sfx_volume_mute_button : Control
@export var voice_volume_slider : Control
@export var voice_volume_mute_button : Control

@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initialize_settings_node()


func _initialize_settings_node() -> void:
	window_mode_option.set_item_id(0, _config_manager.WindowMode.FULLSCREEN)
	window_mode_option.set_item_id(1, _config_manager.WindowMode.WINDOWED)
	window_mode_option.select(
		window_mode_option.get_item_index(
			_config_manager.get_config(_config_manager.ConfigList.WINDOW_MODE)
			)
		)
	
	for rs in _config_manager.WindowResolutions.values():
		window_resolution_option.set_item_id(rs, rs)
		window_resolution_option.select(
			_config_manager.get_config(_config_manager.ConfigList.WINDOW_RESOLUTION)
		)
	
	text_speed_slider.set_value_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.TEXT_SPEED)
		)
	auto_mode_timeout_slider.set_value_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.AUTOMODE_TIMEOUT)
		)
	stop_skip_checkbox.set_pressed_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.FORCE_STOP_FFWD_ON_CHOICE)
		)
	resume_skip_checkbox.set_pressed_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.CONTINUE_FFWD_ON_CHOICE)
		)
	
	master_volume_slider.set_value_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.MASTER_VOLUME)
	)
	master_volume_mute_button.button_pressed = (
		_config_manager.get_config(_config_manager.ConfigList.MASTER_MUTE)
	)
	bgm_volume_slider.set_value_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.BGM_VOLUME)
	)
	bgm_volume_mute_button.button_pressed = (
		_config_manager.get_config(_config_manager.ConfigList.BGM_MUTE)
	)
	sfx_volume_slider.set_value_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.SFX_VOLUME)
	)
	sfx_volume_mute_button.button_pressed = (
		_config_manager.get_config(_config_manager.ConfigList.SFX_MUTE)
	)
	voice_volume_slider.set_value_no_signal(
		_config_manager.get_config(_config_manager.ConfigList.VOICE_VOLUME)
	)
	voice_volume_mute_button.button_pressed = (
		_config_manager.get_config(_config_manager.ConfigList.VOICE_MUTE)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_return_button_button_down() -> void:
	_config_manager.finalize_config()
	accept_event()
	hide()


func _on_window_mode_option_button_item_selected(_index: int) -> void:	
	_config_manager.set_config(_config_manager.ConfigList.WINDOW_MODE, window_mode_option.get_selected_id())


func _on_window_res_option_button_item_selected(index: int) -> void:	
	_config_manager.set_config(_config_manager.ConfigList.WINDOW_RESOLUTION, index)


func _on_skip_on_choice_check_box_toggled(toggled_on: bool) -> void:
	_config_manager.set_config(_config_manager.ConfigList.FORCE_STOP_FFWD_ON_CHOICE, toggled_on)


func _on_resume_skip_after_choice_check_box_toggled(toggled_on: bool) -> void:
	_config_manager.set_config(_config_manager.ConfigList.CONTINUE_FFWD_ON_CHOICE, toggled_on)


func _on_text_speed_slider_updated(value: float) -> void:
	_config_manager.set_config(_config_manager.ConfigList.TEXT_SPEED, value)


func _on_auto_mode_slider_updated(value: float) -> void:
	_config_manager.set_config(_config_manager.ConfigList.AUTOMODE_TIMEOUT, value)


func _on_master_volume_slider_updated(value: float) -> void:
	_config_manager.set_config(_config_manager.ConfigList.MASTER_VOLUME, value)


func _on_bgm_volume_slider_updated(value: float) -> void:
	_config_manager.set_config(_config_manager.ConfigList.BGM_VOLUME, value)


func _on_sfx_volume_slider_updated(value: float) -> void:
	_config_manager.set_config(_config_manager.ConfigList.SFX_VOLUME, value)


func _on_voice_volume_slider_updated(value: float) -> void:
	_config_manager.set_config(_config_manager.ConfigList.VOICE_VOLUME, value)


func _on_master_mute_button_toggled(toggled_on: bool) -> void:
	_config_manager.set_config(_config_manager.ConfigList.MASTER_MUTE, toggled_on)


func _on_bgm_mute_button_toggled(toggled_on: bool) -> void:
	_config_manager.set_config(_config_manager.ConfigList.BGM_MUTE, toggled_on)


func _on_sfx_mute_button_toggled(toggled_on: bool) -> void:
	_config_manager.set_config(_config_manager.ConfigList.SFX_MUTE, toggled_on)


func _on_voice_mute_button_toggled(toggled_on: bool) -> void:
	_config_manager.set_config(_config_manager.ConfigList.VOICE_MUTE, toggled_on)

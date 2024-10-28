extends Node
class_name CasteletViewportManager

# Base viewport size, as its name suggests, is the size of the main viewport
# that determines the size of the window.
var base_viewport_width : float
var base_viewport_height : float
var base_scale_factor = 1.0
var reference_width : float = 1920
var reference_height : float = 1080
var enable_window_content_resize = false
var _current_display_mode_index = 0
var _reference_ratio = reference_width / reference_height

@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")

signal viewport_resized


func _ready():
	_config_manager.config_updated.connect(_on_config_updated)
	
	var init_res : Array = _config_manager.WINDOW_RESOLUTION_MAP[
			_config_manager.get_config(_config_manager.ConfigList.WINDOW_RESOLUTION)
		]["resolution"]
	_set_viewport(_config_manager.get_config(_config_manager.ConfigList.WINDOW_MODE),
			init_res[0], init_res[1])
	

func _set_viewport(win : CasteletConfigManager.WindowMode,
		target_width : int = 1920,
		target_height : int = 1080
	):
	_set_window_mode(win)
	_setup_viewport_dimension(win, target_width, target_height)
	_calculate_base_scale_factor()
	viewport_resized.emit()


func _set_window_mode(win : CasteletConfigManager.WindowMode):
	_current_display_mode_index = win
	if win == _config_manager.WindowMode.FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif win == _config_manager.WindowMode.BORDERLESS:
		pass # TODO: Implement borderless mode
	else: # Defaults to windowed mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _setup_viewport_dimension(
		win : CasteletConfigManager.WindowMode,
		target_width : int = 1920,
		target_height : int = 1080
	):

	if win == _config_manager.WindowMode.FULLSCREEN:
		base_viewport_width = DisplayServer.screen_get_size().x
		base_viewport_height = DisplayServer.screen_get_size().y
	elif win == _config_manager.WindowMode.BORDERLESS:
		pass # TODO: Implement borderless mode
	else: # Defaults to windowed mode
		base_viewport_width = target_width
		base_viewport_height = target_height
	
	# get_viewport().get_visible_rect().size = Vector2(base_viewport_width, base_viewport_height)

	get_viewport().size = Vector2(base_viewport_width, base_viewport_height)

	# This potentially interferes with other game aspects (i.e. when you're using pixel art)
	if enable_window_content_resize:
		# To mitigate non-uniform size, we first check the ratio of reference size and compare
		# it to current resolution.
		# The width or height of the viewport/content will be adjusted accordingly to the ratio
		#
		# Do note that this works optimally only with the stretch aspects "ignore" and "keep".
		# For "expand", further work is required.
		var vp_ratio = base_viewport_width / base_viewport_height
		if _reference_ratio > vp_ratio: # bigger height
			base_viewport_height = base_viewport_width / _reference_ratio
		elif _reference_ratio < vp_ratio: # bigger width
			base_viewport_width = base_viewport_height * _reference_ratio
		else:
			pass
		get_window().content_scale_size = Vector2(base_viewport_width, base_viewport_height)
	

func _calculate_base_scale_factor():

	if enable_window_content_resize:
		base_scale_factor = base_viewport_width / reference_width
	else:
		base_scale_factor = get_window().content_scale_size.x / reference_width

	print_debug(base_scale_factor)


func _on_config_updated(config, value):
	# print(config, value)
	if config == _config_manager.ConfigList.WINDOW_MODE:
		_set_viewport(value)
	if config == _config_manager.ConfigList.WINDOW_RESOLUTION:
		var res : Array = _config_manager.WINDOW_RESOLUTION_MAP[value]["resolution"]
		_set_viewport(_current_display_mode_index,
				res[0], res[1]
		)
	

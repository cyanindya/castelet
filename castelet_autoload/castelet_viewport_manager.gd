extends Node
class_name CasteletViewportManager

# Base viewport size, as its name suggests, is the size of the main viewport
# that determines the size of the window.
var base_viewport_width : float
var base_viewport_height : float
var base_scale_factor = 1.0
var reference_width : float = 1920
var reference_height : float = 1080
var enable_window_content_resize = true

@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")

signal viewport_resized


func _ready():
	_config_manager.config_updated.connect(_on_config_updated)
	_set_viewport(_config_manager.get_config(_config_manager.ConfigList.WINDOW_MODE))
	

func _set_viewport(win : CasteletConfigManager.WindowMode):
	_set_window_mode(win)
	_setup_viewport_dimension(win)
	_calculate_base_scale_factor()
	viewport_resized.emit()


func _set_window_mode(win : CasteletConfigManager.WindowMode):
	if win == _config_manager.WindowMode.FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif win == _config_manager.WindowMode.BORDERLESS:
		pass # TODO: Implement borderless mode
	else: # Defaults to windowed mode
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _setup_viewport_dimension(win : CasteletConfigManager.WindowMode):

	if win == _config_manager.WindowMode.FULLSCREEN:
		base_viewport_width = DisplayServer.screen_get_size().x
		base_viewport_height = DisplayServer.screen_get_size().y
	elif win == _config_manager.WindowMode.BORDERLESS:
		pass # TODO: Implement borderless mode
	else: # Defaults to windowed mode
		base_viewport_width = 1366
		base_viewport_height = 768
	
	# get_viewport().get_visible_rect().size = Vector2(base_viewport_width, base_viewport_height)

	get_viewport().size = Vector2(base_viewport_width, base_viewport_height)

	# This potentially interferes with other game aspects (i.e. when you're using pixel art)
	if enable_window_content_resize:
		get_window().content_scale_size = Vector2(base_viewport_width, base_viewport_height)
	

func _calculate_base_scale_factor():
	# print_debug(base_viewport_width)
	# print_debug(get_viewport().size.x)
	# print_debug(get_viewport().get_visible_rect().size.x)
	# print_debug(get_window().content_scale_size.x)
	
	if enable_window_content_resize:
		base_scale_factor = base_viewport_width / reference_width
	else:
		base_scale_factor = get_window().content_scale_size.x / reference_width

	print_debug(base_scale_factor)


func _on_config_updated(config, value):
	# print(config, value)
	if config == _config_manager.ConfigList.WINDOW_MODE:
		_set_viewport(value)

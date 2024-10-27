extends Node
class_name CasteletViewportManager

var base_viewport_width : float
var base_viewport_height : float
var base_scale_factor = 1.0
@export var reference_window_width : float = 1920
@export var reference_window_height : float = 1080

@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")

func _ready():
	_config_manager.config_updated.connect(_on_config_updated)
	_set_viewport(_config_manager.get_config(_config_manager.ConfigList.WINDOW_MODE))
	

func _set_viewport(win : CasteletConfigManager.WindowMode):
	_set_window_mode(win)
	_setup_viewport_dimension()
	_calculate_base_scale_factor()


func _set_window_mode(win : CasteletConfigManager.WindowMode):
	if win == _config_manager.WindowMode.FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif win == _config_manager.WindowMode.WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _setup_viewport_dimension():
	base_viewport_width = get_viewport().get_visible_rect().size.x
	base_viewport_height = get_viewport().get_visible_rect().size.y

	get_window().content_scale_size = Vector2(
			base_viewport_width as int, base_viewport_height as int
		)


func _calculate_base_scale_factor():
	base_scale_factor = base_viewport_width / reference_window_width


func _on_config_updated(config, value):
	# print(config, value)
	if config == _config_manager.ConfigList.WINDOW_MODE:
		_set_window_mode(value)

extends Node

var base_viewport_width : float
var base_viewport_height : float
var base_scale_factor = 1.0
@export var reference_window_width : float = 1920
@export var reference_window_height : float = 1080
@export var base_text_speed : float = 30
@export var base_automode_timeout : float = 3


# Called when the node enters the scene tree for the first time.
func _ready():
	_setupViewportDefault()
	base_scale_factor = base_viewport_width / reference_window_width


func _setupViewportDefault():
	DisplayServer.window_get_size()
	base_viewport_width = get_viewport().get_visible_rect().size.x
	base_viewport_height = get_viewport().get_visible_rect().size.y
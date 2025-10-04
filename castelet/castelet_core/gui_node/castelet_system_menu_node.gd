extends CanvasLayer

@onready var _config_manager : CasteletConfigManager = get_node("/root/CasteletConfigManager")
@onready var _viewport_manager : CasteletViewportManager = get_node("/root/CasteletViewportManager")

signal system_load_confirmed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_viewport_resized():
	var ui_scale : float = 1.0
	
	if _viewport_manager.enable_window_content_resize:
		if _config_manager.get_config(_config_manager.ConfigList.WINDOW_MODE) == _config_manager.WindowMode.FULLSCREEN:
			ui_scale = _config_manager.WINDOW_RESOLUTION_MAP[_config_manager.WindowResolutions.RES_1920_1080]["ui_scaling"]
		else:
			ui_scale = _config_manager.WINDOW_RESOLUTION_MAP[
				_config_manager.get_config(_config_manager.ConfigList.WINDOW_RESOLUTION)
			]["ui_scaling"]
	
	# Dirty scaling and may result in blurry UI elements, but this works for now.
	$SettingsNode.resize_node(ui_scale)
	$SaveLoadNode.resize_node(ui_scale)


func show_config_menu():
	$SettingsNode.show()


func show_saveload_menu(saving : bool = true):
	if saving == true:
		$SaveLoadNode.show_saveload_entries(true)
	else:
		$SaveLoadNode.show_saveload_entries(false)
		var result : int = await $SaveLoadNode.gui_load_confirmed
		system_load_confirmed.emit(result)


func quick_save():
	$SaveLoadNode.save("qsave")


func quick_load():
	$SaveLoadNode.load_data("qsave")
	var result : int = await $SaveLoadNode.gui_load_confirmed
	system_load_confirmed.emit(result)
	

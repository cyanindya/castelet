extends Control


@onready var _state_manager : CasteletStateManager = get_node("/root/CasteletStateManager")

signal gui_save_confirmed
signal gui_load_confirmed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func save(save_name : String):
	show()

	$SystemPopupNode.yesno_popup(
		"This will overwrite current save slot. Are you sure you want to save?"
	)
	var yn = await $SystemPopupNode.yesno
	if yn != true:
		hide()
		return
	
	_state_manager.save_game_data(save_name)

	$SystemPopupNode.info_popup("Saving...\nPlease do not close the game.")
	var status : int = await _state_manager.game_save_finish
	
	if status == 0:
		$SystemPopupNode.confirm_popup("Save completed successfully.")
	else:
		$SystemPopupNode.confirm_popup("Save failed.")
	await $SystemPopupNode.confirm

	hide()


func load(save_name : String):
	show()

	$SystemPopupNode.yesno_popup(
		"This will load the game into the last saved state, and any unsaved progress will be lost. Are you sure you want to load?"
	)
	var yn = await $SystemPopupNode.yesno
	if yn != true:
		hide()
		return
	
	_state_manager.load_game_data(save_name)

	$SystemPopupNode.info_popup("Loading...\nPlease do not close the game.")
	var status : int = await _state_manager.game_load_finish
	
	if status == 0:
		$SystemPopupNode.confirm_popup("Load completed successfully.")
	else:
		$SystemPopupNode.confirm_popup("Load failed.")
	await $SystemPopupNode.confirm

	gui_load_confirmed.emit(status)

	hide()

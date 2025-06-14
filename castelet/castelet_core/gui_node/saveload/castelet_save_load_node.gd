extends Control


@onready var _state_manager : CasteletStateManager = get_node("/root/CasteletStateManager")

signal save_confirmed
signal load_confirmed


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
	await _state_manager.game_save_finish
	
	$SystemPopupNode.confirm_popup("Save completed.")
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
	await _state_manager.game_load_finish
	
	$SystemPopupNode.confirm_popup("Load completed.")
	await $SystemPopupNode.confirm

	load_confirmed.emit()

	hide()

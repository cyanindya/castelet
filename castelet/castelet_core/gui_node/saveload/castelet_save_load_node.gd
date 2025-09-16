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

	if $CasteletSaveLoadContainerPage.visible:
		$CasteletSaveLoadContainerPage.hide()

	hide()


func load_data(save_name : String):
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
	
	if $CasteletSaveLoadContainerPage.visible:
		$CasteletSaveLoadContainerPage.hide()

	hide()


func show_saveload_entries(saving : bool = true):
	$CasteletSaveLoadContainerPage.saving = saving
	show()
	$CasteletSaveLoadContainerPage.show()


func hide_saveload_entries():
	hide()
	$CasteletSaveLoadContainerPage.hide()


func resize_node(new_scale : float):
	scale = Vector2(new_scale, new_scale)
	

func _on_save_load_entry_interaction(data_id: String) -> void:
	var filename = "save_" + data_id
	if $CasteletSaveLoadContainerPage.saving == true:
		#print_debug("requesting save")
		save(filename)
	else:
		#print_debug("requesting load")
		load_data(filename)


func _on_castelet_save_load_container_page_save_load_page_dismiss() -> void:
	hide_saveload_entries()


func _on_castelet_save_load_container_page_request_save_load_entry_validation(data_id : String) -> void:
	var savefile_name = "user://saves/save_" + data_id + ".sav"
	var save_load_entry_is_ok = FileAccess.file_exists(savefile_name)
	if save_load_entry_is_ok == true:
		#print_debug(_state_manager)
		_state_manager.peek_game_data(savefile_name)
		var result = await _state_manager.peek_game_data_finish
		# print_debug("Save data preview completed. All clear.")

		# Make sure to use deferred emit to give time to the saveload entry nodes to
		# process stuffs first.
		if result[0] == 0:
			$CasteletSaveLoadContainerPage.request_save_load_entry_validation_completed.emit.call_deferred(true, result[1])
		else:
			$CasteletSaveLoadContainerPage.request_save_load_entry_validation_completed.emit.call_deferred(false, null)
	else:
		print_debug("Save data preview completed. The data doesn't exist.")
		$CasteletSaveLoadContainerPage.request_save_load_entry_validation_completed.emit.call_deferred(false, null)

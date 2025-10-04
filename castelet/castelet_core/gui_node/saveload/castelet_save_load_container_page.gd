extends Control

const NUMBER_OF_SAVES = 10

@onready var save_load_page_title_label : Node = $PanelContainer/VBoxContainer/SaveLoadLabel
@onready var save_load_entries_container : Node = $PanelContainer/VBoxContainer/ScrollContainer/SaveLoadEntriesContainer

const CasteletSaveLoadEntryNode = preload("res://castelet/castelet_core/gui_node/saveload/castelet_save_load_entry_node.tscn")

signal save_load_entry_interaction(data_id : String)
signal save_load_page_dismiss
signal request_save_load_entry_validation(data_id)
signal request_save_load_entry_validation_completed(is_ok, data)

var saving : bool = false:
	set(val):
		saving = val
		_save_or_load_change()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_generate_entry_buttons()


func _generate_entry_buttons() -> void:
	for num_of_save in range(NUMBER_OF_SAVES):
		var nod = CasteletSaveLoadEntryNode.instantiate()
		save_load_entries_container.add_child(nod)
		nod.saveload_entry_event.connect(_on_saveload_entry_event)
		
		request_save_load_entry_validation.emit.call_deferred("%d" % num_of_save) # ensuring state manager is loaded first
		var save_load_entry_is_ok = await self.request_save_load_entry_validation_completed
		print_debug(save_load_entry_is_ok)
		
		# print_debug("num_of_save=", num_of_save)
		
		# check for existing save files. If they exist, load the latest save data from there
		# and overwrite the node information. Otherwise, only assign the number.
		if save_load_entry_is_ok[0] == true:
			print_debug("File exists")
			nod.request_saveload_entry_update.emit(
				"%d" % num_of_save,
				save_load_entry_is_ok[1]["header_data"]["last_updated"],
				"",
				save_load_entry_is_ok[1]["header_data"]["screenshot"]
			)
		else:
			print_debug("File doesn't exist")
			nod.request_saveload_entry_update.emit("%d" % num_of_save, "", "", null)


func _save_or_load_change():
	
	for num_of_save in range(NUMBER_OF_SAVES):
		request_save_load_entry_validation.emit.call_deferred("%d" % num_of_save) # ensuring state manager is loaded first
		var save_load_entry_is_ok = await self.request_save_load_entry_validation_completed

		var nod = save_load_entries_container.get_child(num_of_save)
		if save_load_entry_is_ok[0] == true:
			print_debug("File exists")
			nod.request_saveload_entry_update.emit(
				"%d" % num_of_save,
				save_load_entry_is_ok[1]["header_data"]["last_updated"],
				"",
				save_load_entry_is_ok[1]["header_data"]["screenshot"]
			)

		if saving == true:
			nod.enable()

		else:
			if save_load_entry_is_ok[0] == false:
				nod.disable()

	if saving == true:
		save_load_page_title_label.text = "Save Data"
	else:
		save_load_page_title_label.text = "Load Data"


func _on_saveload_entry_event(data_id : String):
	save_load_entry_interaction.emit(data_id)


func _on_return_button_pressed() -> void:
	save_load_page_dismiss.emit()

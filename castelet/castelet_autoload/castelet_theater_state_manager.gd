extends Node
class_name CasteletTheaterStateManager

var _props = []
var _current_bgm = {
	"bgm" : [],
	"stop" : false,
	"pause" : false,
}

var _temp_props = []
var _temp_current_bgm = {}

signal override_stage
signal request_reconstruct_stage(list_of_props, bgm)
signal reconstruct_stage_finished
	


func _ready() -> void:
	override_stage.connect(_on_override_stage)
	reconstruct_stage_finished.connect(_on_reconstruct_stage_finished)


func _exit_tree() -> void:
	override_stage.disconnect(_on_override_stage)
	reconstruct_stage_finished.disconnect(_on_reconstruct_stage_finished)


func set_theater_data_temp(theater_data : Dictionary):
	_temp_props = theater_data["props"]
	_temp_current_bgm = theater_data["current_bgm"]


func get_theater_data():
	var theater_data = {}

	theater_data["props"] = _props
	theater_data['current_bgm'] = _current_bgm

	return theater_data


func clear_prop_data():
	# TODO: check for memory leak since it's possible that the dictionary
	# containing the data is not released from memory.
	_props.clear()


func remove_prop_data(prop_name : String):
	# TODO: implement z-order in stage node signal and immediately access that
	# index instead of iterating one by one
	for i in range(len(_props)):
		if _props[i]["prop"] == prop_name:
			_props.remove_at(i)
			break


func update_prop_data(args : Dictionary):
	var has_prop = false
	var idx = 0

	# TODO: implement z-order in stage node signal and immediately access that
	# index instead of iterating one by one
	for i in range(len(_props)):
		if _props[i]["prop"] == args["prop"]:
			has_prop = true
			idx = i
			break
	
	if has_prop == true:
		_props[idx] = args
	else:
		_props.append(args)
	

func update_bgm_data(bgm := [], args := {}):
	if len(bgm) > 0:
		_current_bgm["bgm"] = bgm
		_current_bgm["stop"] = false
		_current_bgm["pause"] = false
	
	if not args.is_empty():
		if args.has("stop"):
			_current_bgm["stop"] = args["stop"]
		if args.has("pause"):
			_current_bgm["pause"] = args["pause"]


func _on_override_stage():
	request_reconstruct_stage.emit(_temp_props, _temp_current_bgm)


func _on_reconstruct_stage_finished():
	_temp_props = []
	_temp_current_bgm = {}

extends Node
class_name CasteletTheaterStateManager

var _props = []
var _current_bgm = ""


signal request_reconstruct_stage(list_of_props, bgm)



func set_theater_info():
	pass


func get_theater_info():
	var theater_data = {}

	theater_data["props"] = _props
	theater_data['current_bgm'] = _current_bgm

	return theater_data

extends Node

var backlog = []

signal backlog_update(new_data : Dictionary)

func append_dialogue(dialogue_data: Dictionary):
	backlog.append(dialogue_data)
	backlog_update.emit(dialogue_data)
	

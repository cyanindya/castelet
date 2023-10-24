extends Node

const TheaterNode = preload("res://CasteletCore/TheaterNode.tscn")

func _ready():
	var script = TheaterNode.instantiate()
	script.load_script("test_scene_2")
	
	add_child(script)
	script.play_scene()

	await script.end_of_script
	script.end()

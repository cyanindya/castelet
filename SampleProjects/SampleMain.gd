extends Node

const TheaterNode = preload("res://CasteletCore/TheaterNode.tscn")

func _ready():
	var exit_timer = Timer.new()
	exit_timer.wait_time = 0.5
	add_child(exit_timer)
	var script = TheaterNode.instantiate()
	script.load_script("test_scene_3")
	
	add_child(script)
	script.play_scene()

	await script.end_of_script
	script.end()

	exit_timer.start()
	await exit_timer.timeout
	exit_timer.queue_free()
	get_tree().quit()

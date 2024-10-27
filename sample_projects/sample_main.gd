extends Node

const TheaterNode = preload("res://castelet_core/theater_node.tscn")
@onready var _game_manager : CasteletGameManager = get_node("/root/CasteletGameManager")


func _ready():
	var exit_timer = Timer.new()
	exit_timer.wait_time = 0.5
	add_child(exit_timer)

	var script = TheaterNode.instantiate()
	script.load_script("test_scene_2")
	add_child(script)
	await script.load_script_finished
	script.play_scene()

	await script.end_of_script
	script.end()

	exit_timer.start()
	await exit_timer.timeout
	exit_timer.queue_free()
	get_tree().quit()

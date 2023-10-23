extends Node

const CasteletScriptParser = preload("res://CasteletCore/parser/CasteletScriptParser.gd")
const TheaterNode = preload("res://CasteletCore/TheaterNode.tscn")

func _ready():
	var parser = CasteletScriptParser.new()
	var ast =  parser.execute_parser("res://TestAssets/script/test_scene_2.tsc")
	var script = TheaterNode.instantiate()
	script.load_ast(ast)
	
	add_child(script)
	script.play_scene()

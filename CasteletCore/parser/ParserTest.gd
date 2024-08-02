extends Node

const CasteletInputStream = preload("CasteletInputStream.gd")
const CasteletScriptParser = preload("CasteletScriptParser.gd")
const Tokenizer = preload("Tokenizer.gd")
const SyntaxTreeBuilder = preload("SyntaxTreeBuilder.gd")

func _ready():
	# Testing loading script file content.
	var file = "res://TestAssets/script/test_scene_3.tsc"
	var parser = CasteletScriptParser.new()
	var file_contents = parser.load_script_file(file)
	# print_debug(file_contents)

	# Testing loading the script file into input stream.
	# var input_stream = CasteletInputStream.new(file_contents)
	# print_debug(input_stream)

	# Testing the tokenizer
	var tokenizer = Tokenizer.new(file_contents)
	tokenizer.tokenize_from_input_stream()
	print_debug(tokenizer.tokens)

	# Testing the syntax tree generator and the resulting tree
	var tree_generator = SyntaxTreeBuilder.new(file, tokenizer)
	var tree = tree_generator.parse()
	print_debug(tree)

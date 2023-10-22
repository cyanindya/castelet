extends Node

var parser = ScriptParserNew.new()

func _ready():
	var file = "res://TestAssets/script/test_scene_2.tsc"
	
	# var file_contents = parser.load_script_file(file)
	# print_debug(file_contents)
	
	# var input_stream = parser.CasteletInputStream.new(file_contents)
	# print_debug(input_stream.text)
	
	# var lexer = parser.Tokenizer.new(file_contents)
	# print_debug(lexer)

	# while not lexer.input_stream.is_eof():
	#     var lex = lexer.tokenize_next()
	#     if lex != null:
	#         print_debug(lex)

	# lexer.tokenize()
	# print_debug(lexer.tokens)

	# var parser_tree = parser.ParseTreeBuilder.new(lexer)

	# parser_tree.parse()

	# print_debug(parser_tree.syntax_tree.values)

	var parse = parser.Parser.new()
	var tree = parse.execute_parser(file)
	print_debug(tree.values)


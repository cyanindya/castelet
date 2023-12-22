# The core parser package to be directly accessed
# by the TheaterNode.
# Call upon the execute_parser() function to get
# the output in the form of the ready-to-be-read
# syntax tree.

extends RefCounted

# const Tokenizer = preload("Tokenizer.gd")
# const SyntaxTreeBuilder = preload("SyntaxTreeBuilder.gd")

func load_script_file(script_file : String) -> String:
	var content = ""
	
	assert(FileAccess.file_exists(script_file),
			"Cannot open the specified script file. Please check again the name" +
			" or the location of the script.")
	var f = FileAccess.open(script_file, FileAccess.READ)
	content = f.get_as_text()
	f.close()
	
	return content

# func execute_parser(input_file : String):
# 	var file_content = load_script_file(input_file)
# 	# print_debug(file_content)

# 	var tokenizer = Tokenizer.new(file_content)
# 	tokenizer.tokenize()
# 	# print_debug(tokenizer.tokens)
	
# 	var tree_builder = SyntaxTreeBuilder.new(input_file.get_file(), tokenizer)
# 	var tree = tree_builder.parse()
# 	# print_debug(tree.body)
	
# 	return tree

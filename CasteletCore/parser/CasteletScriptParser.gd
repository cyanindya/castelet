extends RefCounted
## The main parser class to be accessed upon converting a script file into
## syntax tree. Call upon execute_parser() by supplying the file name to get
## the resulting syntax tree in return.


const Tokenizer = preload("Tokenizer.gd")


func load_script_file(script_file : String) -> String:
	var script_content = ""
	
	assert(FileAccess.file_exists(script_file),
			"Cannot open the specified script file. Please check again the name" +
			" or the location of the script.")
	var f = FileAccess.open(script_file, FileAccess.READ)
	script_content = f.get_as_text()
	f.close()
	
	return script_content


func execute_parser(input_file : String) -> CasteletSyntaxTree:
	var file_content = load_script_file(input_file)
	#print_debug(file_content)

	var tokenizer : Tokenizer = Tokenizer.new(file_content)
	tokenizer.tokenize_from_input_stream()
	#print_debug(tokenizer.tokens)
	
	var tree_builder = SyntaxTreeBuilder.new(input_file.get_file()
				.trim_suffix(".tsc"), tokenizer)
	var tree = tree_builder.parse(true)
	#print_debug(tree.body)
	
	return tree

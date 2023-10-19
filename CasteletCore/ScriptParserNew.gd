# Converts the contents of a script file into an abstract syntax tree (AST)
# 
# The steps:
## - Read the input file and convert it into a custom file stream object
## - Convert the stream into a bunch of tokenis (assign the information types)
## - Build a parse tree based on the tokens
extends RefCounted
class_name ScriptParserNew

const TOKENS := {
	STRING_LITERAL = "String",
	NEWLINE = "Newline",
	OPERATOR = "Operator",
	SYMBOL = "Symbol",
	BOOLEAN = "Boolean",
	NUMBER = "Number",
	COMMENT = "Comment",
	EOF = "End Of File",
}

const INPUT_TYPES := {
	COMMAND = "Command",
	DIALOGUE = "Dialogue",
}

const OPERATORS := ["@", "[", "]", "+", "-", ":", ","]
const VALID_SYMBOL_TERMINATORS := [" ", "\r", "\n", ":", ",", "[", "]"]
const CONDITIONALS := ["and", "or", "not"]
const BOOLEAN_VALUES = [ "true", "false" ]

# Stage commands are preceded by @
const STAGE_COMMANDS := {
	SCENE = "scene",
	SHOW = "show",
	HIDE = "hide",
	BGM = "bgm",
	SFX = "sfx",
	VOICE = "voice",
	WINDOW = "window",
	LABEL = "label",
	TRANSITION = "transition",
}

class CasteletInputStream:
	
	var text = ""
	var stream_length := 0
	var current_index := -1
	
	func _init(file_content : String):
		self.text = file_content
		self.stream_length = len(file_content)
		print_debug("Stream length: ", self.stream_length)

	func peek_next_char() -> String:
		# Always check if we've reached end-of-file first
		if not self.is_eof():
			return self.text[self.current_index + 1]
		else:
			return ""
	
	func get_next_char() -> String:

		# Always check if we've reached end-of-file first
		if not self.is_eof():
			current_index += 1
			return self.text[self.current_index]
		else:
			return ""
	
	func get_current_char() -> String:
		return self.text[self.current_index]

	func get_previous_char():
		return self.text[self.current_index - 1]
	
	func is_eof() -> bool:
		return self.current_index >= self.stream_length - 1
	
	func error(message : String):
		printerr(message)

class CasteletToken:

	var token_type = ""
	var token_value = ""

	func  _init(token_type : String, token_value : String):
		self.token_type = token_type
		self.token_value = token_value
	
	func _to_string():
		return "CasteletToken(%s, %s)" % [self.token_type, self.token_value]


func load_script_file(script_file : String) -> String:
	var content = ""
	
	assert(FileAccess.file_exists(script_file),
			"Cannot open the specified script file. Please check again the name" +
			" or the location of the script.")
	var f = FileAccess.open(script_file, FileAccess.READ)
	content = f.get_as_text()
	f.close()
	
	return content

class Tokenizer:

	var source_string = ""
	var input_stream : CasteletInputStream
	var tokens = []

	func _init(source_string : String):
		self.source_string = source_string

		self.input_stream = CasteletInputStream.new(source_string)
	
	func tokenize():
		while not input_stream.is_eof():
			tokens.append(_generate_next_token())
		
		tokens.append(CasteletToken.new(TOKENS.EOF, ""))

	func _generate_next_token() -> CasteletToken:

		# Check if it has reached EOF or not.
		if not input_stream.is_eof():

			# If not EOF, check the next character
			var next_char : String = self.input_stream.peek_next_char()
			
			# Comments
			if next_char == "#":
				return _tokenize_comment()
				
			# Numbers
			elif next_char.is_valid_float() or next_char.is_valid_int():
				return _tokenize_number()

			# Operators
			elif next_char in OPERATORS:
				return _tokenize_operator()
			
			# Newlines (both CR-LF and LF)
			elif next_char == "\r":
				return _tokenize_cr()

			elif next_char == "\n":
				return _tokenize_lf()

			# General symbols (can be prop name or stage commands)
			elif next_char.is_valid_identifier():
				return _tokenize_symbol()

			# String literals
			elif next_char == "\"":
				return _tokenize_string_literal()

			else:
				self.input_stream.get_next_char()
				return null
		
		else:
			return CasteletToken.new(TOKENS.EOF, "")


	
	func _tokenize_comment():
		# Skip the "#" sign
		self.input_stream.get_next_char()

		# Skip possible whitespaces
		while self.input_stream.peek_next_char() == " ":
			self.input_stream.get_next_char()

		var val = ""
		
		# One line covers one comment token
		while not self.input_stream.is_eof():
			var next_char = self.input_stream.peek_next_char()

			if next_char not in ["\r", "\n"]:
				val += self.input_stream.get_next_char()
			else:
				break
		
		return CasteletToken.new(TOKENS.COMMENT, val)
	
	func _tokenize_number():
		var num_regex = RegEx.new()
		num_regex.compile("[\\d]")

		var val = "%s" % self.input_stream.get_next_char()

		while not self.input_stream.is_eof():
			var next_char = self.input_stream.peek_next_char()

			# Check if value already has decimal separator. If it has,
			# throw an error
			if next_char == ".":
				if not val.contains("."):
					val += self.input_stream.get_next_char()
				else:
					push_error("Decimal error. The value already has decimal separator.")
			elif num_regex.search(next_char):
				val += self.input_stream.get_next_char()
			elif next_char in VALID_SYMBOL_TERMINATORS:
				break
			else:
				push_error("Unidentified character %s inside number." %next_char)
		
		return CasteletToken.new(TOKENS.NUMBER, val)
	
	func _tokenize_cr():
		self.input_stream.get_next_char()

		var next_char = self.input_stream.peek_next_char()
		if next_char == "\n":
			return _tokenize_lf()
		else:
			push_error("No line feed detected.")
			return null

	func _tokenize_lf():
		self.input_stream.get_next_char()
		return CasteletToken.new(TOKENS.NEWLINE, "")

	func _tokenize_operator():
		var val = ""
		val += self.input_stream.get_next_char()
		return CasteletToken.new(TOKENS.OPERATOR, val)
	
	func _tokenize_string_literal():
		self.input_stream.get_next_char()

		var val = ""

		while not self.input_stream.is_eof():
			var next_char = self.input_stream.peek_next_char()

			if next_char == "\"":
				# Add the quote to the list if it is escaped
				if self.input_stream.get_current_char() == "\\":
					val += self.input_stream.get_next_char()
					continue
				# Otherwise, consider it as string termination quote
				else:
					break
			else:
				if next_char == "\n":
					if self.input_stream.get_current_char() != "\"":
						push_error("No string termination quote found")
						break
					
				val += self.input_stream.get_next_char()
			
		self.input_stream.get_next_char()
		
		# print_debug("String value: ", val)
		return CasteletToken.new(TOKENS.STRING_LITERAL, val)
	
	func _tokenize_symbol():
		var symbol_regex = RegEx.new()
		symbol_regex.compile("[\\._a-zA-Z0-9]")

		var val = "%s" % self.input_stream.get_next_char()

		while not self.input_stream.is_eof():
			var next_char = self.input_stream.peek_next_char()

			if symbol_regex.search(next_char):
				val += self.input_stream.get_next_char()
			elif next_char in VALID_SYMBOL_TERMINATORS:
				break
			else:
				push_error("Unidentified character %s inside symbol" %next_char)

		if val in BOOLEAN_VALUES:
			return CasteletToken.new(TOKENS.BOOLEAN, val)
		else:
			return CasteletToken.new(TOKENS.SYMBOL, val)




			



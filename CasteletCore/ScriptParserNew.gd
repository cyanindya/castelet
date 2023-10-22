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

# Stage commands/keywords are preceded by @
# Returns KeywordError when the predicted keyword does not exist in the list
const KEYWORDS := {
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

class Tokenizer:

	var source_string = ""
	var input_stream : CasteletInputStream
	var tokens = []
	var token_index = -1 # so we'll start from 0 proper
	var number_of_tokens = 0

	func _init(source_string : String):
		self.source_string = source_string
		self.input_stream = CasteletInputStream.new(source_string)
		self.tokenize()
	
	func peek() -> CasteletToken:
		return self.tokens[token_index + 1]
	
	func next():
		if not self.is_eof_token():
			self.token_index += 1
			return self.tokens[token_index]
		else:
			push_error("End of token list reached.")
	
	func is_eof_token():
		return self.token_index == number_of_tokens - 1

	func tokenize():
		while not input_stream.is_eof():
			var token = self._generate_next_token()
			if token != null:
				self.tokens.append(token)
		
		self.tokens.append(CasteletToken.new(TOKENS.EOF, ""))

		self.number_of_tokens = len(self.tokens)

	func _generate_next_token() -> CasteletToken:

		# Check if it has reached EOF or not.
		if not self.input_stream.is_eof():

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

			else: # null will be discarded in the parser
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

# The class that combines them all.
class Parser:
	extends RefCounted

	func load_script_file(script_file : String) -> String:
		var content = ""
		
		assert(FileAccess.file_exists(script_file),
				"Cannot open the specified script file. Please check again the name" +
				" or the location of the script.")
		var f = FileAccess.open(script_file, FileAccess.READ)
		content = f.get_as_text()
		f.close()
		
		return content
	
	func execute_parser(input_file : String):
		var file_content = load_script_file(input_file)
		print_debug(file_content)
		var tokens = Tokenizer.new(file_content)
		print_debug(tokens)
		var parse_tree = ParseTreeBuilder.new(tokens)
		print_debug(parse_tree)
		return parse_tree.syntax_tree

# Generates the AST tree from the tokens.
# A rough example of the generated syntax tree:
# file_name = [
#	{type : "command", keyword : "scene", data : {prop : "bg", variant : "carcocena"}, args : { xpos : 0.5, ypos : 0.5 } }
# 	{type : "command", keyword : "choice", ...}
# 	{type : "dialogue", speaker : "id_dietrich", dialogue : "....You [i]never[/i] change, do you?", pause_locations : [], pause_durations = []},
# ]
# General behavior:
# - if the current token is an @ symbol, expect keyword in a symbol-type token. Returns KeywordError when the defined keyword doesn't exist.
# - every time it is terminated by newline, check again whether it is started by an @ (keyword), $ (variable), or other symbols (expects dialogue)
class ParseTreeBuilder:

	var tokens : Tokenizer
	var syntax_tree = SyntaxTree.new()
	var token_cache = []

	func _init(tokens_list : Tokenizer):
		self.tokens = tokens_list
		self._parse()
	
	func _parse():
		while not self.tokens.is_eof_token():
			var tree = self._parse_token()
			if tree != null:
				self.syntax_tree.append(tree)

	# Go through the list of tokens and begin building the parse tree
	func _parse_token():

		var next_token_preview : CasteletToken = self.tokens.peek()
		
		# Stage commands and variable assignments (denoted by @ and $) take precedence
		if next_token_preview.token_type == TOKENS.OPERATOR:
			
			# Stage commands (denoted by @ operator in beginning of line)
			if next_token_preview.token_value == "@":
				return _parse_commands()
			else:
				# TODO: handle variable assignment
				tokens.next()

		# Otherwise, attempt to parse dialogue with one of these following formats:
		# - prop_name "dialogue"
		# - "narration dialogue"
		# - "One-Time Character" "dialogue"
		elif next_token_preview.token_type == TOKENS.SYMBOL:
			return _parse_dialogue()

		elif next_token_preview.token_type == TOKENS.STRING_LITERAL:
			return _parse_dialogue()
		
		# Skip newlines and comments
		elif next_token_preview.token_type == TOKENS.NEWLINE or next_token_preview.token_type == TOKENS.COMMENT:
			tokens.next()
		
		elif next_token_preview.token_type == TOKENS.EOF:
			print_debug("End of tokens list reached")
			tokens.next()
		else:
			push_error("Unidentified token with type %s. Skipping." % next_token_preview.token_type)
			tokens.next()

	func _parse_commands():
		var type = ""
		var value = []
		var args = {}

		# Advance the tokenizer iteration
		tokens.next()
		
		# Next, check the token to see if it is (a) a symbol and (b) it has
		# same value as any listed in the KEYWORDS.
		var next_token_preview = tokens.peek()

		if next_token_preview.token_type != TOKENS.SYMBOL:
			push_error()
		if next_token_preview.token_value not in KEYWORDS.values():
			push_error()
		
		type = tokens.next().token_value

		# The next will be adaptive. Some stage commands like BGM or SFX
		# supports multiple inputs for queue-ing, while others only support
		# one input and return error instead. 
		next_token_preview = tokens.peek()

		if next_token_preview.token_value == "[":
			if type not in [KEYWORDS.SFX, KEYWORDS.BGM, KEYWORDS.VOICE]:
				push_error("The parsed stage command does not support queued inputs.")
			tokens.next()
			next_token_preview = tokens.peek()

			while next_token_preview.token_type == TOKENS.SYMBOL or next_token_preview.token_value == ",":
				var token = tokens.next()
				if next_token_preview.token_type == TOKENS.SYMBOL:
					value.append(token.token_value)
			
				next_token_preview = tokens.peek()
			
			# Throw an error if it is not closed by ]
			if next_token_preview.token_value != "]":
				push_error()
			
			tokens.next()
			
		elif next_token_preview.token_type == TOKENS.SYMBOL:
			var token = tokens.next()
			value.append(token.token_value)
		else:
			push_error()

		# Check for arguments until newline is reached
		while tokens.peek().token_type != TOKENS.NEWLINE:
			var argument : CommandArgExpression = _parse_args()
			args[argument.param] = argument.value

		return StageCommandExpression.new(type, value, args)


	func _parse_args():
		var param = ""
		var value

		var next_token_preview = tokens.peek()

		if (next_token_preview.token_type != TOKENS.SYMBOL):
			push_error("Expected a Symbol type token, but found %s instead." % next_token_preview.token_type)
		
		param = tokens.next().token_value
		next_token_preview = tokens.peek()

		if (next_token_preview.token_type != TOKENS.OPERATOR and next_token_preview.token_value != ":"):
			push_error("Expected argument assignment using :, but found %s type token instead." % next_token_preview.token_type)
		
		tokens.next()

		next_token_preview = tokens.peek()
		if next_token_preview.token_type == TOKENS.BOOLEAN:
			if next_token_preview.token_value == "true":
				value = true
			else:
				value = false
			tokens.next()
		elif next_token_preview.token_type == TOKENS.NUMBER:
			value = tokens.next().token_value as float
		elif next_token_preview.token_type == TOKENS.SYMBOL:
			value = tokens.next().token_value
		else:
			push_error("Expected a Symbol, Boolean, or Number type token for argument value, but found %s type token instead." % next_token_preview.token_type)

		return CommandArgExpression.new(param, value)

	func _parse_dialogue():
		var speaker = ""
		var dialogue = ""

		# Throw the immediate next token into token cache first.
		token_cache.append(tokens.next())

		# Check the next following token, then check existing tokens in the array.
		# Throw an error if it doesn't follow the designated dialogue format.
		var next_token_preview = tokens.peek()

		while next_token_preview.token_type != TOKENS.NEWLINE:
			# Add whatever first string literal available next
			if next_token_preview.token_type == TOKENS.STRING_LITERAL:
				token_cache.append(tokens.next())
			
			# If a plus sign is available, expect another string literal to be joined later.
			elif next_token_preview.token_type == TOKENS.OPERATOR and next_token_preview.token_value == "+":
				
				while next_token_preview.token_type != TOKENS.STRING_LITERAL:
					tokens.next()
					next_token_preview = tokens.peek()

					if next_token_preview.token_type in [TOKENS.SYMBOL, TOKENS.OPERATOR]:
						push_error("Expected a string literal to be joined with previous string literal, but found %s token instead" % next_token_preview.token_type)
				
				# Discard this present token and join its contents with the last one available in token cache.
				token_cache[-1].token_value += tokens.next().token_value
			
			# Otherwise, throw an error
			else:
				push_error()
			
			next_token_preview = tokens.peek()

		# Once newline is met, evaluate the token cache contents.
		# If only one string literal, assume the token cache content is a narrative dialogue
		if len(token_cache) == 1 and token_cache[0].token_type == TOKENS.STRING_LITERAL:
			dialogue = token_cache[0].token_value
		elif len(token_cache) > 1:
			# Speaker assignment
			if token_cache[0].token_type == TOKENS.SYMBOL:
				if token_cache[0].token_value != "extend":
					speaker = "id_" + token_cache[0].token_value
				else:
					speaker = token_cache[0].token_value
			elif token_cache[0].token_type == TOKENS.STRING_LITERAL:
				speaker = token_cache[0].token_value
			else:
				push_error("Expected a Symbol or string literal token for the dialogue speaker data, but found %s type token instead" % token_cache[0].token_type)
			
			var dialogue_cache = ""

			# Dialogue assignment
			for i in range(1, len(token_cache)):
				if token_cache[i].token_type == TOKENS.STRING_LITERAL:
					dialogue_cache += token_cache[i].token_value
				else:
					push_error("Expected a string literal, but found %s token type instead." % token_cache[i].token_type)
			
			dialogue = dialogue_cache

		else:
			push_error("Invalid dialogue format.")
		
		token_cache.clear()

		# Lastly, extract custom tags such as wait [w] and auto-dismiss [nw].
		# They're not meant to be custom BBCodes and can interfere with other
		# functionalities those don't need them (e.g. dialogue history), so
		# we extract them here and store it into the expression instead.

		return DialogueExpression.new(speaker, dialogue)


class SyntaxTree:
	var values = []

	func append(expression : BaseExpression):
		values.append(expression)

class BaseExpression:
	var type = ""
	var value

	func _init(type : String, value):
		self.type = type
		self.value = value

	func _to_string():
		return "BaseExpression(%s, %s)" % [self.type, self.value]

class StageCommandExpression:
	extends BaseExpression

	var data
	var args = {}

	func _init(type : String, value, args = {}):
		super(type, value)
		self.args = args
	
	func _to_string():
		return "StageCommandExpression(%s, %s, %s)" % [self.type, self.value, self.args]

class CommandArgExpression:
	extends BaseExpression

	var param

	func _init(param : String, value):
		self.type = "Argument"
		self.param = param
		self.value = value
	
	func _to_string():
		return "CommandArgExpression(%s, %s)" % [self.param, self.value]

class DialogueExpression:
	extends BaseExpression
	var speaker = ""
	var dialogue = ""
	var pause_locations = []
	var pause_durations = []
	var auto_dismiss = false

	func _init(speaker : String, dialogue : String, pause_locations = [], pause_durations = [],
		auto_dismiss = false):
		self.speaker = speaker
		self.dialogue = dialogue
		self.pause_locations = pause_locations
		self.pause_durations = pause_durations
		self.auto_dismiss = auto_dismiss

	func assign_prop_notation():
		self.speaker = "id_" + self.speaker
	
	func _to_string():
		return "DialogueExpression(%s, %s)" % [self.speaker, self.dialogue]

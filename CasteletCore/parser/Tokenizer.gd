# A tokenizer class to convert a script stream file into
# a series of information tokens for building the parse tree
# later.

extends RefCounted

const CasteletInputStream = preload("CasteletInputStream.gd")

# Define the list of tokens to be recognized.
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

const OPERATORS := ["@", "[", "]", "+", "-", ":", ",", "$", "=", "%"]

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
	JUMP = "jump",
	CHOICE = "choice",
}

var _source_string = ""
var _input_stream : CasteletInputStream
var tokens = []:
	get:
		return tokens
var _token_index = -1 # so we'll start from 0 proper
var _number_of_tokens = 0

func _init(source_string : String) -> void:
	self._source_string = source_string
	self._input_stream = CasteletInputStream.new(source_string)

func peek() -> CasteletToken:
	return self.tokens[_token_index + 1]

func next() -> CasteletToken:
	if not self.is_eof_token():
		self._token_index += 1
		return self.tokens[_token_index]
	else:
		push_error("End of token list reached.")
		return CasteletToken.new("", "")

func is_eof_token() -> bool:
	return self._token_index == self._number_of_tokens - 1

func tokenize() -> void:
	while not _input_stream.is_eof():
		var token = self._generate_next_token()
		if token != null:
			self.tokens.append(token)
	
	self.tokens.append(CasteletToken.new(TOKENS.EOF, ""))

	self._number_of_tokens = len(self.tokens)

func _generate_next_token() -> CasteletToken:

	# Check if it has reached EOF or not.
	if not self._input_stream.is_eof():

		# If not EOF, check the next character
		var next_char : String = self._input_stream.peek_next_char()
		
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
			self._input_stream.get_next_char()
			return null
	
	else:
		return CasteletToken.new(TOKENS.EOF, "")



func _tokenize_comment() -> CasteletToken:
	# Skip the "#" sign
	self._input_stream.get_next_char()

	# Skip possible whitespaces
	while self._input_stream.peek_next_char() == " ":
		self._input_stream.get_next_char()

	var val = ""
	
	# One line covers one comment token
	while not self._input_stream.is_eof():
		var next_char = self._input_stream.peek_next_char()

		if next_char not in ["\r", "\n"]:
			val += self._input_stream.get_next_char()
		else:
			break
	
	return CasteletToken.new(TOKENS.COMMENT, val)


func _tokenize_number() -> CasteletToken:
	var num_regex = RegEx.new()
	num_regex.compile("[\\d]")

	var val = "%s" % self._input_stream.get_next_char()

	while not self._input_stream.is_eof():
		var next_char = self._input_stream.peek_next_char()

		# Check if value already has decimal separator. If it has,
		# throw an error
		if next_char == ".":
			if not val.contains("."):
				val += self._input_stream.get_next_char()
			else:
				push_error("Decimal error. The value already has decimal separator.")
		elif num_regex.search(next_char):
			val += self._input_stream.get_next_char()
		elif next_char in VALID_SYMBOL_TERMINATORS:
			break
		else:
			push_error("Unidentified character %s inside number." %next_char)
	
	return CasteletToken.new(TOKENS.NUMBER, val)


func _tokenize_cr() -> CasteletToken:
	self._input_stream.get_next_char()

	var next_char = self._input_stream.peek_next_char()
	if next_char == "\n":
		return _tokenize_lf()
	else:
		push_error("No line feed detected.")
		return null


func _tokenize_lf() -> CasteletToken:
	self._input_stream.get_next_char()
	return CasteletToken.new(TOKENS.NEWLINE, "")

func _tokenize_operator() -> CasteletToken:
	var val = ""
	val += self._input_stream.get_next_char()
	return CasteletToken.new(TOKENS.OPERATOR, val)


func _tokenize_string_literal() -> CasteletToken:
	self._input_stream.get_next_char()

	var val = ""

	while not self._input_stream.is_eof():
		var next_char = self._input_stream.peek_next_char()

		if next_char == "\"":
			# Add the quote to the list if it is escaped
			if self._input_stream.get_current_char() == "\\":
				val += self._input_stream.get_next_char()
				continue
			# Otherwise, consider it as string termination quote
			else:
				break
		else:
			if next_char == "\n":
				if self._input_stream.get_current_char() != "\"":
					push_error("No string termination quote found")
					break
				
			val += self._input_stream.get_next_char()
		
	self._input_stream.get_next_char()
	
	# print_debug("String value: ", val)
	return CasteletToken.new(TOKENS.STRING_LITERAL, val)


func _tokenize_symbol() -> CasteletToken:
	var symbol_regex = RegEx.new()
	symbol_regex.compile("[\\._a-zA-Z0-9]")

	var val = "%s" % self._input_stream.get_next_char()

	while not self._input_stream.is_eof():
		var next_char = self._input_stream.peek_next_char()

		if symbol_regex.search(next_char):
			val += self._input_stream.get_next_char()
		elif next_char in VALID_SYMBOL_TERMINATORS:
			break
		else:
			push_error("Unidentified character %s inside symbol" %next_char)
	
	if val in BOOLEAN_VALUES:
		return CasteletToken.new(TOKENS.BOOLEAN, val)
	else:
		return CasteletToken.new(TOKENS.SYMBOL, val)


class CasteletToken:

	var type = ""
	var value = ""

	func  _init(token_type : String, token_value : String) -> void:
		self.type = token_type
		self.value = token_value
	
	func _to_string() -> String:
		return "CasteletToken(%s, %s)" % [self.type, self.value]

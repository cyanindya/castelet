extends RefCounted
## A class that holds all of the tokens to be parsed and converted into syntax
## tree later.

const CasteletInputStream = preload("castelet_input_stream.gd")

# Define the list of tokens to be recognized.
const TOKENS := {
	STRING_LITERAL = "String",
	NEWLINE = "Newline",
	OPERATOR = "Operator",
	SYMBOL = "Symbol",
	BOOLEAN = "Boolean",
	BRACES = "Braces", # for [](){}
	NUMBER = "Number",
	COMMENT = "Comment",
	EOF = "End Of File",
}

const INPUT_TYPES := {
	COMMAND = "Command",
	DIALOGUE = "Dialogue",
}

const OPERATORS := ["@", "[", "]", ":", ",", "$"]
const MATH_OPERATORS := ["+", "-", "/", "*",  "%", "^", "="]
const COMPARISON_OPERATORS := [">", ">=", "<", "<=", "==", "!="]
const ASSIGNMENT_OPERATORS := ["=", "+=", "-=", "/=", "*=", "%="]
const BOOLEAN_OPERATORS := ["&&", "||", "!", "and", "or", "not"]

const VALID_SYMBOL_TERMINATORS := [" ", "\r", "\n", ":", ","]
const BRACES_PAREN := ["[", "]", "(", ")", "{", "}"]
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
	JUMPTO = "jumpto",
	CALLSUB = "callsub",
	RETURN = "return",
	IF = "if",
	ELSEIF = "elseif",
	ELSE = "else",
	ENDIF = "endif",
	WHILE = "while",
	ENDWHILE = "endwhile",
	MENU = "menu",
	CHOICE = "choice",
	ENDMENU = "endmenu",
}

var tokens = []:
	get:
		return tokens

var _input_stream : CasteletInputStream
var _token_index = -1 # so we'll start from 0 proper
var _number_of_tokens = 0


func _init(source_string := "") -> void:
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


func current() -> CasteletToken:
	return self.tokens[_token_index]


func prev() -> CasteletToken:
	if not self._token_index == 0:
		self._token_index -= 1
		return self.tokens[_token_index]
	else:
		push_error("Currently at the beginning of token list. Cannot step back.")
		return CasteletToken.new("", "")


func is_at_end() -> bool:
	return self._token_index == self._number_of_tokens - 1


func is_eof_token() -> bool:
	return self.tokens[_token_index + 1].type == TOKENS.EOF


func tokenize_from_input_stream() -> void:
	while not _input_stream.is_eof():
		var token = self._generate_next_token()
		if token != null:
			self.tokens.append(token)
	
	self.tokens.append(CasteletToken.new(TOKENS.EOF, ""))

	self._number_of_tokens = len(self.tokens)


func set_from_tokens_list(tk := [], add_eof := false):
	self.tokens = tk

	if add_eof:
		self.tokens.append(CasteletToken.new(TOKENS.EOF, ""))

	self._number_of_tokens = len(self.tokens)


func append_tokens(tokens_to_append : Array) -> void:
	self.tokens = tokens_to_append
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
		elif next_char in OPERATORS + MATH_OPERATORS + ASSIGNMENT_OPERATORS + COMPARISON_OPERATORS + ["&", "|", "!"]:
			return _tokenize_operator()
		
		# Brackets and parentheses
		elif next_char in BRACES_PAREN:
			return _tokenize_braces()
		
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
		elif next_char in VALID_SYMBOL_TERMINATORS or next_char in BRACES_PAREN:
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

	# Check if this one is currently a math operator and possibly a compound
	if val in MATH_OPERATORS and self._input_stream.peek_next_char() == "=":
		val += self._input_stream.get_next_char()

	# On the other hand, also check if this is a boolean operator
	if val in ["&", "|", "!"] and self._input_stream.peek_next_char() == val:
		val += self._input_stream.get_next_char()

	return CasteletToken.new(TOKENS.OPERATOR, val)


func _tokenize_boolean() -> CasteletToken:
	var val = ""
	val += self._input_stream.get_next_char()

	return CasteletToken.new(TOKENS.BOOLEAN, val)


func _tokenize_braces() -> CasteletToken:
	var val = ""
	val += self._input_stream.get_next_char()
	return CasteletToken.new(TOKENS.BRACES, val)


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
		elif next_char in VALID_SYMBOL_TERMINATORS or next_char in BRACES_PAREN:
			break
		else:
			push_error("Unidentified character %s inside symbol" %next_char)
	
	if val in BOOLEAN_VALUES:
		return CasteletToken.new(TOKENS.BOOLEAN, val)
	elif val in BOOLEAN_OPERATORS:
		return CasteletToken.new(TOKENS.OPERATOR, val)
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

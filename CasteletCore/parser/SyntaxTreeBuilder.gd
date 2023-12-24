# Generates the syntax tree from the extracted script tokens.
# Castelet syntax tree generally contains the following information:
# - name: Name of the file the syntax tree originates from.
# - body: Contains a list of expressions generated from the analysis.
# - checkpoints:
# 
# A rough example of the generated syntax tree:
# 	"name" :"test_script.tsc",
#	"body" : [
#		{type : "command", keyword : "scene", data : {prop : "bg", variant : "carcocena"}, args : { xpos : 0.5, ypos : 0.5 } }
# 		{type : "command", keyword : "choice", ...}
# 		{type : "dialogue", speaker : "id_dietrich", dialogue : "....You [i]never[/i] change, do you?", pause_locations : [], pause_durations = []},
# 	],
#	"checkpoints" : {}
# 
# This parser works according to these behaviors:
# - If the current token is an @ operator, expect keyword in a symbol-type token.
#	Returns KeywordError when the defined keyword doesn't exist.
# - every time a series of tokens is terminated by newline, check again whether
#	the new line it is started by an @ (keyword), $ (variable), or other symbols (expects dialogue)

extends RefCounted

const Tokenizer = preload("Tokenizer.gd")
const CasteletToken = Tokenizer.CasteletToken

var _name = ""
var _tokens : Tokenizer
var _token_cache = []


func _init(tree_name : String, tokens_list : Tokenizer):
	self._name = tree_name
	self._tokens = tokens_list


func parse() -> CasteletSyntaxTree:
	
	var tree = CasteletSyntaxTree.new(self._name)

	while not self._tokens.is_eof_token():
		var expression = self._parse_token()
		if expression != null:
			tree.append(expression)
	
	return tree


# Go through the list of _tokens and begin building the parse tree
func _parse_token():

	var next_token_preview : CasteletToken = self._tokens.peek()
	
	# Stage commands and variable assignments (denoted by @ and $) take precedence
	if next_token_preview.type == Tokenizer.TOKENS.OPERATOR:
		
		# Stage commands (denoted by @ operator in beginning of line)
		if next_token_preview.value == "@":
			return self._parse_commands()
		# Variable assignment (denoted by $ operator in beginning of line)
		elif next_token_preview.value == "$":
			return self._parse_assignment()
		else:
			# TODO: handle variable assignment
			self._tokens.next()

	# Otherwise, attempt to parse dialogue with one of these following formats:
	# - prop_name "dialogue"
	# - "narration dialogue"
	# - "One-Time Character" "dialogue"
	elif next_token_preview.type == Tokenizer.TOKENS.SYMBOL:
		return self._parse_dialogue()

	elif next_token_preview.type == Tokenizer.TOKENS.STRING_LITERAL:
		return self._parse_dialogue()
	
	# Skip newlines and comments
	elif next_token_preview.type in [Tokenizer.TOKENS.NEWLINE, Tokenizer.TOKENS.COMMENT]:
		self._tokens.next()
	
	elif next_token_preview.type == Tokenizer.TOKENS.EOF:
		# print_debug("End of _tokens list reached")
		self._tokens.next()
	else:
		push_error("Unidentified token with type %s. Skipping." % next_token_preview.type)
		self._tokens.next()

func _parse_commands():
	var type = ""
	var value = []
	var args = {}

	# Advance the tokenizer iteration
	self._tokens.next()
	
	# Next, check the token to see if it is (a) a symbol and (b) it has
	# same value as any listed in the KEYWORDS.
	var next_token_preview = _tokens.peek()

	if next_token_preview.type != Tokenizer.TOKENS.SYMBOL:
		push_error()
	if next_token_preview.value not in Tokenizer.KEYWORDS.values():
		push_error()
	
	type = self._tokens.next().value

	# The next will be adaptive. Some stage commands like BGM or SFX
	# supports multiple inputs for queue-ing, while others only support
	# one input and return error instead. 
	next_token_preview = _tokens.peek()

	if next_token_preview.value == "[":
		if type not in [Tokenizer.KEYWORDS.SFX, Tokenizer.KEYWORDS.BGM, Tokenizer.KEYWORDS.VOICE]:
			push_error("The parsed stage command does not support queued inputs.")
		self._tokens.next()
		next_token_preview = _tokens.peek()

		while next_token_preview.type in [Tokenizer.TOKENS.SYMBOL, ","]:
			var token = self._tokens.next()
			if next_token_preview.type == Tokenizer.TOKENS.SYMBOL:
				value.append(token.value)
		
			next_token_preview = _tokens.peek()
		
		# Throw an error if it is not closed by ]
		if next_token_preview.value != "]":
			push_error()
		
		self._tokens.next()
		
	elif next_token_preview.type == Tokenizer.TOKENS.SYMBOL:
		var token = self._tokens.next()
		value.append(token.value)
	else:
		push_error()

	# Check for arguments until newline is reached
	while _tokens.peek().type != Tokenizer.TOKENS.NEWLINE:
		var argument : CasteletSyntaxTree.CommandArgExpression = _parse_args()
		args[argument.param] = argument.value

	return CasteletSyntaxTree.StageCommandExpression.new(type, value, args)

# TODO: Parse branching, binary operations
func _parse_assignment():
	var lh
	var rh
	var operators = [] # TODO: rewrite this for compound assignment

	var temp = ""
	
	# Advance the tokenizer iteration
	self._tokens.next()
	
	# Next, check the token to see if it is (a) a symbol and (b) it has
	# same value as any listed in the KEYWORDS.
	var next_token_preview = self._tokens.peek()

	# Do some checking before parsing the symbol as variable:
	## Check if it is a symbol token
	## Check if it is not part of reserved keyword already
	## Put on temporary variable, then do some more checking.
	## If the next token is not part of valid operator (either assignment
	## operator or compound assignment), throw an error.
	if next_token_preview.type != Tokenizer.TOKENS.SYMBOL:
		push_error()
	if next_token_preview.value in Tokenizer.KEYWORDS.values():
		push_error("Invalid variable name. The name is already part of reserved keyword.")
	
	temp = self._tokens.next()

	next_token_preview = self._tokens.peek()
	
	# TODO: check for compound operators
	if next_token_preview.type != Tokenizer.TOKENS.OPERATOR:
		push_error()
	if next_token_preview.value != "=":
		push_error()
	
	lh = CasteletSyntaxTree.VariableExpression.new(temp.value)
	self._tokens.next()

	# TODO: check for binary expressions
	temp = self._tokens.next()
	rh = CasteletSyntaxTree.BaseExpression.new(temp.type, temp.value)
	
	next_token_preview = self._tokens.peek()
	if next_token_preview.type != Tokenizer.TOKENS.NEWLINE:
		push_error()

	return CasteletSyntaxTree.AssignmentExpression.new(lh, rh)
	



func _parse_args():
	var param = ""
	var value

	var next_token_preview = _tokens.peek()

	if (next_token_preview.type != Tokenizer.TOKENS.SYMBOL):
		push_error("Expected a Symbol type token, but found %s instead." % next_token_preview.type)
	
	param = self._tokens.next().value
	next_token_preview = _tokens.peek()

	if (next_token_preview.type != Tokenizer.TOKENS.OPERATOR and next_token_preview.value != ":"):
		push_error("Expected argument assignment using :, but found %s type token instead." % next_token_preview.type)
	
	self._tokens.next()

	next_token_preview = _tokens.peek()
	if next_token_preview.type == Tokenizer.TOKENS.BOOLEAN:
		if next_token_preview.value == "true":
			value = true
		else:
			value = false
		self._tokens.next()
	elif next_token_preview.type == Tokenizer.TOKENS.NUMBER:
		value = self._tokens.next().value as float
	elif next_token_preview.type == Tokenizer.TOKENS.SYMBOL:
		value = self._tokens.next().value
	else:
		push_error("Expected a Symbol, Boolean, or Number type token for argument value, but found %s type token instead." % next_token_preview.type)

	return CasteletSyntaxTree.CommandArgExpression.new(param, value)

func _parse_dialogue():
	var speaker = ""
	var dialogue = ""
	var args = {}
	var formatter = []

	# Throw the immediate next token into token cache first.
	_token_cache.append(self._tokens.next())

	# Check the next following token, then check existing _tokens in the array.
	# Throw an error if it doesn't follow the designated dialogue format.
	var next_token_preview = _tokens.peek()

	while next_token_preview.type != Tokenizer.TOKENS.NEWLINE:
		# Add whatever first string literal available next
		if next_token_preview.type == Tokenizer.TOKENS.STRING_LITERAL:
			_token_cache.append(self._tokens.next())
		
		# If a plus sign is available, expect another string literal to be joined later.
		elif next_token_preview.type == Tokenizer.TOKENS.OPERATOR:
			if next_token_preview.value == "+":
			
				while next_token_preview.type != Tokenizer.TOKENS.STRING_LITERAL:
					self._tokens.next()
					next_token_preview = _tokens.peek()

					if next_token_preview.type in [Tokenizer.TOKENS.SYMBOL, Tokenizer.TOKENS.OPERATOR]:
						push_error("Expected a string literal to be joined with previous string literal, but found %s token instead" % next_token_preview.type)
				
				# Discard this present token and join its contents with the last one available in token cache.
				_token_cache[-1].value += self._tokens.next().value
			
			elif next_token_preview.value == "%":
				# TODO: bracketed formatter
				self._tokens.next()
				next_token_preview = _tokens.peek()

				if next_token_preview.type == Tokenizer.TOKENS.OPERATOR and next_token_preview.value == "[":
					self._tokens.next()

					while next_token_preview.value != "]":
						next_token_preview = _tokens.peek()

						if next_token_preview.type in [Tokenizer.TOKENS.SYMBOL,
							Tokenizer.TOKENS.STRING_LITERAL, Tokenizer.TOKENS.NUMBER, Tokenizer.TOKENS.BOOLEAN]:
							formatter.append(next_token_preview)
						elif next_token_preview.type == Tokenizer.TOKENS.OPERATOR and next_token_preview.value in [",", "]"]:
							pass
						else:
							push_error(next_token_preview)
						
						self._tokens.next()
						
					self._tokens.next()

				elif next_token_preview.type == Tokenizer.TOKENS.SYMBOL:
					formatter.append(next_token_preview.value)

					self._tokens.next()
				
				else:
					push_error()


		
		# Otherwise, throw an error
		else:
			push_error()
		
		next_token_preview = _tokens.peek()

	# Once newline is met, evaluate the token cache contents.
	# If only one string literal, assume the token cache content is a narrative dialogue
	if len(_token_cache) == 1 and _token_cache[0].type == Tokenizer.TOKENS.STRING_LITERAL:
		dialogue = _token_cache[0].value
	elif len(_token_cache) > 1:
		# Speaker assignment
		if _token_cache[0].type == Tokenizer.TOKENS.SYMBOL:
			if _token_cache[0].value != "extend":
				speaker = "id_" + _token_cache[0].value
			else:
				speaker = _token_cache[0].value
		elif _token_cache[0].type == Tokenizer.TOKENS.STRING_LITERAL:
			speaker = _token_cache[0].value
		else:
			push_error("Expected a Symbol or string literal token for the dialogue speaker data, but found %s type token instead" % _token_cache[0].type)
		
		var dialogue_cache = ""

		# Dialogue assignment
		for i in range(1, len(_token_cache)):
			if _token_cache[i].type == Tokenizer.TOKENS.STRING_LITERAL:
				dialogue_cache += _token_cache[i].value
			else:
				push_error("Expected a string literal, but found %s token type instead." % _token_cache[i].type)
		
		dialogue = dialogue_cache

	else:
		push_error("Invalid dialogue format.")
	
	_token_cache.clear()

	
	args["formatter"] = formatter

	return CasteletSyntaxTree.DialogueExpression.new(speaker,dialogue, args)

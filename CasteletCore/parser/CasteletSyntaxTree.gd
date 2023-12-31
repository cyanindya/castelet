class_name CasteletSyntaxTree
extends RefCounted

var name = ""
var body = []
var checkpoints = {}

var _current_index = -1
var body_size = 0

func _init(tree_name : String):
	self.name = tree_name

func _to_string() -> String:
	return "CasteletSyntaxTree { name : %s,body : %s, checkpoints : %s }" % [self.name, self.body, self.checkpoints]

func append(expression : BaseExpression):
	self.body.append(expression)
	self.body_size += 1

func reset():
	self._current_index = -1

func peek() -> BaseExpression:
	if not self.is_at_end():
		return self.body[self._current_index + 1]
	return null

func next() -> BaseExpression:
	if not self.is_at_end():
		self._current_index += 1
		return self.body[self._current_index]
	return null

func is_at_end() -> bool:
	return self._current_index >= self.body_size - 1

class BaseExpression:
	var type = ""
	var value

	func _init(expression_type : String, expression_value):
		self.type = expression_type
		self.value = expression_value

	func _to_string():
		return "BaseExpression {type: %s,\n value: %s}" % [self.type, self.value]

class StageCommandExpression:
	extends BaseExpression

	var data
	var args = {}

	func _init(expression_type : String, expression_value, expression_args = {}):
		super(expression_type, expression_value)
		self.args = expression_args
	
	func _to_string():
		return "StageCommandExpression{type: %s,\n value: %s,\n args:%s}" % [self.type, self.value, self.args]

class CommandArgExpression:
	extends BaseExpression

	var param

	func _init(arg_param : String, arg_value):
		self.type = "Argument"
		self.param = arg_param
		self.value = arg_value
	
	func _to_string():
		return "CommandArgExpression{param: %s, value: %s}" % [self.param, self.value]

class DialogueExpression:
	extends BaseExpression
	var speaker = ""
	var dialogue = ""
	var args = {}

	func _init(speaker_name : String, dialogue_text : String, arguments = {}):
		self.speaker = speaker_name
		self.dialogue = dialogue_text
		self.args = arguments

	func assign_prop_notation():
		self.speaker = "id_" + self.speaker
	
	func _to_string():
		return "DialogueExpression{speaker: %s, dialogue: %s, args: %s}" % [self.speaker, self.dialogue, self.args]

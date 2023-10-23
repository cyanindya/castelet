class_name CasteletSyntaxTree
extends RefCounted

var name = ""
var body = []
var checkpoints = {}

func _init(tree_name : String):
	self.name = tree_name

func _to_string() -> String:
	return "CasteletSyntaxTree { name : %s,\nbody : %s,\ncheckpoints : %s }" % [self.name, self.body, self.checkpoints]

func append(expression : BaseExpression):
	self.body.append(expression)

class BaseExpression:
	var type = ""
	var value

	func _init(expression_type : String, expression_value):
		self.type = expression_type
		self.value = expression_value

	func _to_string():
		return "BaseExpression(%s, %s)" % [self.type, self.value]

class StageCommandExpression:
	extends BaseExpression

	var data
	var args = {}

	func _init(expression_type : String, expression_value, expression_args = {}):
		super(expression_type, expression_value)
		self.args = expression_args
	
	func _to_string():
		return "StageCommandExpression(%s, %s, %s)" % [self.type, self.value, self.args]

class CommandArgExpression:
	extends BaseExpression

	var param

	func _init(arg_param : String, arg_value):
		self.type = "Argument"
		self.param = arg_param
		self.value = arg_value
	
	func _to_string():
		return "CommandArgExpression(%s, %s)" % [self.param, self.value]

class DialogueExpression:
	extends BaseExpression
	var speaker = ""
	var dialogue = ""
	var pause_locations = []
	var pause_durations = []
	var auto_dismiss = false

	func _init(speaker_name : String, dialogue_text : String, pauses = [], durations = [],
		auto_dismiss_on_end = false):
		self.speaker = speaker_name
		self.dialogue = dialogue_text
		self.pause_locations = pauses
		self.pause_durations = durations
		self.auto_dismiss = auto_dismiss_on_end

	func assign_prop_notation():
		self.speaker = "id_" + self.speaker
	
	func _to_string():
		return "DialogueExpression(%s, %s)" % [self.speaker, self.dialogue]

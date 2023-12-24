class_name CasteletSyntaxTree
extends RefCounted

var name = ""
var body = []
var checkpoints = {}

var _current_index = -1
var body_size = 0

const BINARY_OPERATORS = {
	"=" : "Assignment",
	"+" : "Summation",
	"-" : "Subtraction",
	"*" : "Multiplication",
	"/" : "Division",
}

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

class VariableExpression:
	extends BaseExpression
	
	func _init(val : String):
		self.type = "Variable"
		self.value = val

	func _to_string():
		return "VariableExpression{name: %s}" % [self.value]


class BinaryExpression:
	extends BaseExpression

	var lhs : BaseExpression # Left-hand side
	var rhs : BaseExpression # Right-hand side
	var op : String # Operator

	func _init(left_hand : BaseExpression, right_hand : BaseExpression, operator : String):

		if operator not in BINARY_OPERATORS.keys():
			push_error("Invalid binary operation. The operator is not part of valid operator.")

		self.type = BINARY_OPERATORS[operator]
		self.lhs = left_hand
		self.rhs = right_hand
	
	func _to_string():
		return "BinaryExpression{left hand: %s, right hand: %s,}" % [self.lhs, self.rhs]

class AssignmentExpression:
	extends BinaryExpression

	func _init(left_hand : VariableExpression, right_hand : BaseExpression):
		self.type = BINARY_OPERATORS["="]
		self.lhs = left_hand
		self.rhs = right_hand

	func _to_string():
		return "AssignmentExpression{left hand: %s, right hand: %s}" % [self.lhs, self.rhs]


class CompoundAssignmentExpression:
	extends AssignmentExpression

	var compound_operator = ""

	func _init(left_hand : VariableExpression, right_hand : BaseExpression, operator : String):
		super._init(left_hand, right_hand)
		self.compound_operator = operator

	func _to_string():
		return "CompoundAssignmentExpression{left hand: %s, right hand: %s, operator: %s}" % [self.lhs, self.rhs, self.compound_operator]
		

class StatementExpression:
	extends BaseExpression

	func _init(statement : String):
		self.type = "Statement"
		self.value = statement
	
	func _to_string():
		return "StatementExpression{statement: %s}" % [self.value]
	

class_name CasteletSyntaxTree
extends RefCounted
## The class representing a Castelet script's syntax tree.
## 
## Castelet tree generally contains the following information:
## - name:			Name of the syntax tree. Usually comes from the name of the file
##					it was extracted from, but can also be custom names (such as to
##					denote that the tree is a sub-tree of a script).
## - body:			Contains a list of expressions generated from the script parsing.
## - checkpoints:	List of specific checkpoints for the Jumpto or Callsub command to
##					leap into. Generally generated from @label expression.
##
## Upon creating syntax tree from a bunch of tokens, it is advised to avoid directly
## instantiating this class and instead use the SyntaxTreeBuilder class to handle it.


const BINARY_OPERATORS = {
	"=" : "Assignment",
	"+" : "Summation",
	"-" : "Subtraction",
	"*" : "Multiplication",
	"/" : "Division",
	">" : "GreaterThan",
	">=" : "GreaterEqual",
	"<" : "LessThan",
	"<=" : "LessEqual",
	"==" : "Equal",
	"!=" : "NotEqual",
	"&&" : "And",
	"||" : "Or",
	"!" : "Not",
	"and" : "And",
	"or" : "Or",
	"not" : "Not",
}

var name = ""
var body_size = 0
var body = []
var checkpoints = []

var _current_index = -1


func _init(tree_name : String):
	self.name = tree_name


func _to_string() -> String:
	return "CasteletSyntaxTree { name : %s,body : %s, checkpoints : %s }" % [self.name, self.body, self.checkpoints]


func append(expression : BaseExpression):
	self.body.append(expression)
	self.body_size += 1


func reset():
	self._current_index = -1


func set_index(idx : int):
	self._current_index = idx


func get_index():
	return self._current_index


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

		self.type = "Binary"
		self.lhs = left_hand
		self.rhs = right_hand
		self.op = operator
	
	func _to_string():
		return "BinaryExpression{left hand: %s, right hand: %s, op : %s}" % [self.lhs, self.rhs, self.op]


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


class FunctionCallExpression:
	extends BaseExpression

	var func_name = ""
	var vars = []
	var vals = []

	func _init(function_name : String, input_vars = [], input_vals = []):
		self.type = "Function"
		self.func_name = function_name
		self.vars = input_vars
		self.vals = input_vals
	
	func _to_string():
		return "FunctionCallExpression{func_name: %s, vars: %s, vals: %s}" % [self.func_name, self.vars, self.vals]


class JumptoExpression:
	extends BaseExpression

	func _init(target_name : String):
		self.type = "Jumpto"
		self.value = target_name
	
	func _to_string():
		return "JumptoExpression{value: %s}" % [self.value]


class LabelExpression:
	extends BaseExpression

	var position = 0

	func _init(label_name : String, label_position : int):
		self.type = "Label"
		self.value = label_name
		self.position = label_position

	func _to_string():
		return "LabelExpression{value: %s, position: %s}" % [self.value, self.position]


class CallsubExpression:
	extends JumptoExpression

	func _init(target_name : String):
		super(target_name)
		self.type = "Callsub"
		
	func _to_string():
		return "CallsubExpression{value: %s}"


class ReturnExpression:
	extends BaseExpression

	func _init():
		self.type = "Return"
	
	func _to_string():
		return "ReturnExpression"


class IfElseExpression:
	extends BaseExpression

	func _init(conditions := []):
		self.type = "IfElse"
		self.value = conditions
	
	func add_condition(cond : CasteletSyntaxTree.ConditionalExpression):
		self.value.append(cond)

	func _to_string():
		return "IfElseExpression{value: " + str(value) + "}"


class WhileExpression:
	extends BaseExpression

	func _init(condition : ConditionalExpression):
		self.type = "While"
		self.value = condition
	
	func _to_string():
		return "WhileExpression{value: " + str(value) + "}"


class ConditionalExpression:
	extends BaseExpression

	var evaluator : BaseExpression # can cover binary comparison or just one
	var subroutine : String

	func _init(eval : BaseExpression, sub : String):
		self.evaluator = eval
		self.subroutine = sub

	func _to_string():
		return "ConditionalExpression{eval: %s, subroutine: %s}" % [self.evaluator, self.subroutine]


class LoopBackExpression:
	extends BaseExpression

	func _init(tree : CasteletSyntaxTree):
		self.type = "LoopBack"
		self.value = tree

	func _to_string():
		return "LoopBackExpression"


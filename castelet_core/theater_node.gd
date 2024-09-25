# The main displayed node of this framework.
#
# This node goes through a script's syntax tree generated by the parser,
# and updates the stage and GUI nodes accordingly. This node is akin to
# a movie player, although it is intended only for a single scene/script file.
# This node only needs to play the script based on the syntax tree, and has no
# need to know where it is currently at.
# 
# Management of all of the scenes, however, should be done in other node.
# 
# To properly play/pause/stop the scene, use the following functions:
# - play(from_beginning) - start or resume the scene
# - pause() - makes sure _next() won't be triggered while pause is active
# - stop() - stops the scene playback and reset to the beginning
# - end() - terminates this node.

extends SubViewportContainer

const Tokenizer = preload("res://castelet_core/parser/castelet_tokenizer.gd")

var _tree : CasteletSyntaxTree
var _paused = false
var DialogueTools = load("res://castelet_core/dialogue_processing_tools.gd")
var dialogue_tools
var _timer : Timer
var _is_menu := false

signal end_of_script


func load_script(script_id : String):
	print_debug(CasteletGameManager.script_trees)
	self._tree = CasteletGameManager.script_trees[script_id]


func _ready():
	_timer = Timer.new()
	_timer.wait_time = 0.1
	add_child(_timer)

	CasteletTransitionManager.vp = $SubViewport
	dialogue_tools = DialogueTools.new()
	# Connect the required signals to relevant callback functions
	end_of_script.connect(_on_end_of_script)
	CasteletGameManager.progress.connect(_on_progress)


func _next():

	# Preview the next expression on the tree before
	# actually grabbing them
	var next = self._tree.peek()

	# If end of script is reached, terminate.
	if self._tree.is_at_end():
		emit_signal("end_of_script")
		return
	
	# Perform different tasks based on the detected
	# expressions.
	if next is CasteletSyntaxTree.StageCommandExpression:
		if next.type in [Tokenizer.KEYWORDS.SCENE, Tokenizer.KEYWORDS.SHOW]:
			_update_stage_prop(CasteletTransitionManager.object_transition_data)
		elif next.type == Tokenizer.KEYWORDS.HIDE:
			_hide_stage_prop(CasteletTransitionManager.object_transition_data)
		elif next.type in [Tokenizer.KEYWORDS.BGM, Tokenizer.KEYWORDS.SFX]:
			_update_audio_channel()
		elif next.type == Tokenizer.KEYWORDS.VOICE:
			pass
		elif next.type == Tokenizer.KEYWORDS.TRANSITION:
			_update_transition()
		elif next.type == Tokenizer.KEYWORDS.WINDOW:
			_update_window()
		else:
			pass
	
	elif next is CasteletSyntaxTree.LabelExpression:
		self._tree.next()
		CasteletGameManager.progress.emit()
	
	elif next is CasteletSyntaxTree.JumptoExpression:

		# If it's call function, append the call source to the stack
		if next is CasteletSyntaxTree.CallsubExpression:
			CasteletGameManager.append_callsub_stack(self._tree.name, self._tree.get_index())

		if next.value in CasteletGameManager.script_trees.keys():
			self.load_script(next.value)
			self._tree.reset()
		else:
			if CasteletGameManager.jump_checkpoints_list[next.value]["tree"] != self._tree.name:
				self.load_script(CasteletGameManager.jump_checkpoints_list[next.value]["tree"])
			self._tree.set_index(CasteletGameManager.jump_checkpoints_list[next.value]["index"])
	
		CasteletGameManager.progress.emit()
	
	elif next is CasteletSyntaxTree.ReturnExpression:
		if CasteletGameManager.get_context_level() > 0:
			var origin = CasteletGameManager.pop_callsub_stack()
			self.load_script(origin["tree"])
			self._tree.set_index(origin["index"] + 1)
			CasteletGameManager.progress.emit()
		# TODO: terminate the script
		else:
			end_of_script.emit()

	elif next is CasteletSyntaxTree.LoopBackExpression:
		self._tree = next.value
		self._tree.reset()
		CasteletGameManager.progress.emit()
		
	elif next is CasteletSyntaxTree.FunctionCallExpression:
		var caller_object = self
		var func_name = ""
		var args = []
		
		var fnc = self._tree.next()
		var fnc_name = fnc.func_name.split(".")
		if len(fnc_name) > 1:
			caller_object = get_node("/root/" + fnc_name[0])
			func_name = fnc_name[-1]
		else:
			func_name = fnc_name[-1]
		
		for arg_tree in fnc.vals:
			args.append(_translate_expression(arg_tree))
		
		var func_callable = Callable(caller_object, func_name)
		func_callable.callv(args)

		CasteletGameManager.progress.emit()
	
	elif next is CasteletSyntaxTree.IfElseExpression:
		var if_else_block = self._tree.next()

		# Evaluate each condition, then transfer the execution to each
		# condition's associated subroutines
		for condition in if_else_block.value:
			var eval = _translate_expression(condition.evaluator)
			if eval == true:
				self._tree = CasteletGameManager.script_trees[condition.subroutine]
				self._tree.reset()
				break
		
		CasteletGameManager.progress.emit()

	elif next is CasteletSyntaxTree.WhileExpression:
		var while_block = self._tree.next()

		# Evaluate each condition, then transfer the execution to each
		# condition's associated subroutines
		var eval = _translate_expression(while_block.value.evaluator)
		if eval == true:
			self._tree = CasteletGameManager.script_trees[while_block.value.subroutine]
			self._tree.reset()
		
		CasteletGameManager.progress.emit()

	elif next is CasteletSyntaxTree.AssignmentExpression:
		var assignment = self._tree.next()
		var is_persistent = (assignment.lhs.value as String).begins_with("persistent.")
		var varname = assignment.lhs.value
		var var_storage = CasteletGameManager.vars
		if is_persistent:
			varname = (assignment.lhs.value as String).trim_prefix("persistent.")
			var_storage = CasteletGameManager.persistent
		
		var result = _translate_expression(assignment.rhs)

		if assignment is CasteletSyntaxTree.CompoundAssignmentExpression:
			if assignment.compound_operator == "+=":
				var_storage[varname] += result
			elif assignment.compound_operator == "-=":
				var_storage[varname] -= result
			elif assignment.compound_operator == "/=":
				var_storage[varname] /= result
			elif assignment.compound_operator == "*=":
				var_storage[varname] *= result
			elif assignment.compound_operator == "^=":
				var_storage[varname] ^= result
			elif assignment.compound_operator == "%=":
				var_storage[varname] %= result
		else:
			var_storage[varname] = result
		
		CasteletGameManager.progress.emit()
	
	elif next is CasteletSyntaxTree.MenuExpression:
		var menu = self._tree.next()
		_show_menu(menu)

	elif next is CasteletSyntaxTree.DialogueExpression:
		var command : CasteletSyntaxTree.DialogueExpression = self._tree.next()
		_update_dialogue(command)
	
	else:
		self._tree.next()


func _translate_expression(expr : CasteletSyntaxTree.BaseExpression):

	var expr_result

	if expr is CasteletSyntaxTree.BinaryExpression:
		expr_result = _process_binary(expr)
	elif expr is CasteletSyntaxTree.VariableExpression:
		var is_persistent = (expr.value as String).begins_with("persistent.")
		var varname = expr.value
		var var_storage = CasteletGameManager.vars
		if is_persistent:
			varname = (expr.value as String).trim_prefix("persistent.")
			var_storage = CasteletGameManager.persistent

		expr_result = var_storage[varname]
	elif expr is CasteletSyntaxTree.FunctionCallExpression:
		pass #TODO
	else:
		if expr.type == Tokenizer.TOKENS.BOOLEAN:
			if expr.value == "true":
				expr_result = true
			else:
				expr_result = false
		elif expr.type == Tokenizer.TOKENS.NUMBER:
			expr_result = expr.value as float
		else:
			expr_result = expr.value as String
	
	return expr_result


func _process_binary(expr : CasteletSyntaxTree.BinaryExpression):

	var left_hand
	var right_hand
	var op = expr.op

	left_hand = _translate_expression(expr.lhs)
	right_hand = _translate_expression(expr.rhs)

	if (op == "+"):
		return left_hand + right_hand
	elif (op == "-"):
		return left_hand - right_hand
	elif (op == "/"):
		return left_hand / right_hand
	elif (op == "*"):
		return left_hand * right_hand
	elif (op == "%"):
		return left_hand % right_hand
	elif (op == ">"):
		return left_hand > right_hand
	elif (op == ">="):
		return left_hand >= right_hand
	elif (op == "=="):
		return left_hand == right_hand
	elif (op == "<"):
		return left_hand < right_hand
	elif (op == "<="):
		return left_hand <= right_hand
	elif (op == "!="):
		return left_hand != right_hand
	elif (op in ["&&", "and"]):
		return left_hand and right_hand
	elif (op in ["||", "or"]):
		return left_hand or right_hand
	elif (op in ["!", "not"]):
		return not right_hand


func _update_stage_prop(transition : Dictionary = {}):
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()
	var cb = ""

	if command.type == Tokenizer.KEYWORDS.SCENE:
		cb = "scene"
	elif command.type == Tokenizer.KEYWORDS.SHOW:
		cb = "show_prop"
	
	var params = (command.value[0] as String).split(".")
	var prop_func = Callable($SubViewport/StageNode, cb)

	var args = command.args

	if not transition.is_empty():
		args["transition"] = transition
	
	if len(params) > 1:
		prop_func.call(params[0], params[1], args)
	else:
		prop_func.call(params[0], 'default', args)
	

func _hide_stage_prop(transition = {}):
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()
	var params = (command.value[0] as String).split(".")

	var args = command.args

	if not transition.is_empty():
		args["transition"] = transition
	
	$SubViewport/StageNode.hide_prop(params[0], args)
	

func _update_transition():
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()

	var transition_name : String = command.value[0]
	var transition_properties : Dictionary = command.args

	if not CasteletGameManager.ffwd_active:

		
		if CasteletTransitionManager.transitioning == true:
			CasteletGameManager.set_block_signals(true)
			await CasteletTransitionManager.transition_completed
			
			_timer.start()
			await _timer.timeout

			CasteletGameManager.set_block_signals(false)
			

		if CasteletTransitionManager.TransitionScope.OBJECT not in CasteletTransitionManager.transition_types[transition_name]:
			CasteletTransitionManager.transition(transition_name, CasteletTransitionManager.TransitionScope.VIEWPORT, transition_properties)
		elif CasteletTransitionManager.TransitionScope.VIEWPORT not in CasteletTransitionManager.transition_types[transition_name]:
			CasteletTransitionManager.transition(transition_name, CasteletTransitionManager.TransitionScope.OBJECT, transition_properties)
		else:
			if command.args.has("object") and command.args["object"] == true:
				CasteletTransitionManager.transition(transition_name, CasteletTransitionManager.TransitionScope.OBJECT, transition_properties)
			else:
				CasteletTransitionManager.transition(transition_name, CasteletTransitionManager.TransitionScope.VIEWPORT, transition_properties)

	CasteletGameManager.progress.emit()


func _update_audio_channel():
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()
	var channel : String = command.type.to_upper()

	if command.value[0] == "stop":
		CasteletAudioManager.stop_audio(channel)
	elif command.value[0] == "pause":
		CasteletAudioManager.pause_audio(channel)
	elif command.value[0] == "resume":
		CasteletAudioManager.resume_audio(channel)
	elif command.value[0] == "":
		CasteletAudioManager.refresh_audio(command.args, channel)
	else:
		if len(command.value) > 1:
			CasteletAudioManager.queue_audio(command.value, command.args, channel)
		else:
			CasteletAudioManager.play_audio(command.value[0], command.args, channel)
	
	CasteletGameManager.progress.emit()
	

func _update_window():
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()

	if command.value[0] in ["show", "on"]:
		$SubViewport/GUINode.show_window()
	elif command.value[0] in ["hide", "off"]:
		$SubViewport/GUINode.hide_window()


func _update_dialogue(command : CasteletSyntaxTree.DialogueExpression):
	
	if CasteletTransitionManager.transitioning == true:
		CasteletGameManager.set_block_signals(true)
		await CasteletTransitionManager.transition_completed
		CasteletGameManager.set_block_signals(false)
	
	var dialogue = {
		"speaker": command.speaker,
		"dialogue" : command.dialogue,
		"args" : command.args,
	}

	# Read if any variables/values to be interpolated exist
	var formatter = []
	for vr in dialogue["args"]["formatter"]:
		var val;
		print(vr)
		if vr.type == Tokenizer.TOKENS.SYMBOL:
			if vr.value.begins_with("persistent."):
				val = CasteletGameManager.persistent[vr.value.trim_prefix("persistent.")]
			else:
				val = CasteletGameManager.vars[vr.value]
		else:
			val = vr.value
		if vr.type == Tokenizer.TOKENS.NUMBER:
			val = val as float
		elif vr.type == Tokenizer.TOKENS.BOOLEAN:
			if val == "true":
				val = true
			else:
				val = false
		else:
			pass
		formatter.append(val)
	dialogue["dialogue"] = dialogue["dialogue"] % formatter

	# Lastly, extract custom tags such as wait [w] and auto-dismiss [nw].
	# They're not meant to be custom BBCodes and can interfere with other
	# functionalities those don't need them (e.g. dialogue history), so
	# we extract them here and store it into the expression instead.
	var dialogue_processed : Dictionary = dialogue_tools.extract_custom_non_bbcode_tags(dialogue["dialogue"])
	for arg in dialogue_processed["args"].keys():
		dialogue["args"][arg] = dialogue_processed["args"][arg]
	dialogue["dialogue"] = dialogue_processed["dialogue"]
	
	# If the speaker data starts with "id_", make sure to check the assets database
	# for the proper speaker name.
	if command.speaker.begins_with("id_"):
		if not (CasteletAssetsManager.props.has(command.speaker.trim_prefix("id_"))):
			push_warning("The defined prop does not actually exist." +
				" Temporarily assigning prop ID as speaker label.")
			dialogue["speaker"] = command.speaker.trim_prefix("id_")
		else:
			dialogue["speaker"] = CasteletAssetsManager.props[command.speaker
									.trim_prefix("id_")].prop_name
	
	$SubViewport/GUINode.update_dialogue(dialogue)

	# Append current dialogue to the seen-dialogue cache
	if command.speaker != "extend":
		CasteletGameManager.append_dialogue(dialogue)
	else:
		CasteletGameManager.append_dialogue_extend(dialogue)


func _on_end_of_script():
	print_debug("End of script reached")


# Only progress when not paused.
# (Requires more testing with multiple scenes active)
func _on_progress():
	if not _paused:
		if not self._tree.is_at_end():
			_next()
		else:
			end_of_script.emit()


func play_scene(from_beginning = true):
	if from_beginning:
		_tree.reset()
	_paused = false
	_next()


func pause_scene():
	_paused = true	


func stop_scene():
	_tree.reset()


func _show_menu(menu : CasteletSyntaxTree.MenuExpression):
	
	CasteletGameManager.menu_showing = true

	if not CasteletConfig.continue_ffwd_after_choices:
		CasteletGameManager.ffwd_active = false
	
	# CasteletGameManager.auto_active = false

	# CasteletGameManager.set_block_signals(true)

	if menu.value != null:
		_update_dialogue(menu.value)

	var choices = []
	for choice in menu.choices:
		choices.append({
				"choice" : choice.value,
				"sub" : choice.subroutine,
				"condition" : _translate_expression(choice.condition),
		})

	$SubViewport/GUINode.show_choices(choices)

	var next_tree = await $SubViewport/GUINode.choice_made

	self.load_script(next_tree)
	self._tree.reset()

	# CasteletGameManager.set_block_signals(false)

	CasteletGameManager.menu_showing = false
	CasteletGameManager.progress.emit()


	


# Terminates this node. Intended to be called
func end():
	
	stop_scene()

	CasteletTransitionManager.vp = null
	remove_child(_timer)
	_timer.queue_free()

	# Ensures the signal handler is disconnected before this node is destroyed, just in case.
	CasteletGameManager.progress.disconnect(_on_progress)
	end_of_script.disconnect(_on_end_of_script)

	$SubViewport/StageNode.hide()
	$SubViewport/GUINode.hide()
	
	queue_free()
	

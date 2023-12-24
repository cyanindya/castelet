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

extends Node

const Tokenizer = preload("parser/Tokenizer.gd")

var _tree : CasteletSyntaxTree
var _paused = false
var DialogueTools = load("CasteletCore/DialogueTools.gd")
var dialogue_tools

signal end_of_script


func load_script(script_id : String):
	print_debug(CasteletGameManager.script_trees)
	self._tree = CasteletGameManager.script_trees[script_id]


func _ready():
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
			_update_stage_prop()
		elif next.type == Tokenizer.KEYWORDS.HIDE:
			_hide_stage_prop()
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
	elif next is CasteletSyntaxTree.AssignmentExpression:
		var assignment = self._tree.next()
		
		if (assignment.lhs.value as String).begins_with("persistent."):
			CasteletGameManager.persistent[(assignment.lhs.value as String).split("")[1]] = assignment.rhs.value
		else:
			CasteletGameManager.vars[assignment.lhs.value] = assignment.rhs.value
		
		CasteletGameManager.progress.emit()
		
	elif next is CasteletSyntaxTree.DialogueExpression:
		_update_dialogue()
	else:
		self._tree.next()

func _update_stage_prop():
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()
	var cb = ""

	if command.type == Tokenizer.KEYWORDS.SCENE:
		cb = "scene"
	elif command.type == Tokenizer.KEYWORDS.SHOW:
		cb = "show_prop"
	
	var params = (command.value[0] as String).split(".")
	var prop_func = Callable($StageNode, cb)
	
	if len(params) > 1:
		prop_func.call(params[0], params[1], command.args)
	else:
		prop_func.call(params[0], 'default', command.args)

func _hide_stage_prop():
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()
	var params = (command.value[0] as String).split(".")
	$StageNode.hide_prop(params[0])
	
func _update_transition():
	var command : CasteletSyntaxTree.StageCommandExpression = self._tree.next()

	# Check transition type
	

	# Check if a target exists in tree node.

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
		$GUINode.show_window()
	elif command.value[0] in ["hide", "off"]:
		$GUINode.hide_window()


func _update_dialogue():
	var command : CasteletSyntaxTree.DialogueExpression = self._tree.next()
	var dialogue = {
		"speaker": command.speaker,
		"dialogue" : command.dialogue,
		"args" : command.args,
	}

	# Read if any variables/values to be interpolated exist
	var formatter = []
	for vr in dialogue["args"]["formatter"]:
		var val;
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
	print_debug(dialogue)

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
	
	$GUINode.update_dialogue(dialogue)

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

# Terminates this node. Intended to be called
func end():
	
	stop_scene()

	# Ensures the signal handler is disconnected before this node is destroyed, just in case.
	CasteletGameManager.progress.disconnect(_on_progress)
	end_of_script.disconnect(_on_end_of_script)

	$StageNode.hide()
	$GUINode.hide()
	
	queue_free()
	

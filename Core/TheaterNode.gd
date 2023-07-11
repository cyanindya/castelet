# The core node of the engine.
# This node serves to read a story file, parse the script contents
# into commands understandable by Godot Engine, and display the cutscene according to
# the processed script.
# However, as this node is not a global node, this node has no control over
# configurations and things those may interrupt the theater flow (i.e. events) --
# they go to the relevant Autoload nodes instead.
#
# This node takes the following input(s) (AKA exports):
# - script_file : The script file containing the story to be presented.
#
# Excluding the _ready and _process, the functionality of this node is comprised of:
# _read_script -> open the supplied script file
# _parse_script -> convert the contents of the script file into an array of commands
# _unfold_play -> refresh the Stage Node or GUI Node once at a time based on the
#					current command to be read
# _process_command -> do the actual heavy lifting for updating the Stage and/or Node

extends Node
class_name TheaterNode

# The custom script file to display the cutscene from.
@export_file("*.tsc") var script_file

# Script-level variables to control the flow of the story presentation. Comprised of:
# - an array of parsed commands
# - current count of the parsed command list (required for end-of-script notif)
# - total command count
var _parsed_script_commands = []
var _current_command_index = -1 # start from -1 so we can start from 0
var _total_command_count = 0
var _currently_processed_command = {}

# Special signal to be called when end of script is reached
signal end_of_script


# The function that is first called when the game starts
func _ready():

	# Connect the game manager signals to relevant callback functions
	CasteletGameManager.progress.connect(_on_progress)
	
	# Read and parse the script
	_read_script()
	
	# await get_tree().create_timer(1).timeout
	
	# Go through the parsed commands
	_unfold_play()


# The function for opening the act script file
func _read_script() -> void:
	
	# First, check validity of the story script file, then properly open the file.
	assert(FileAccess.file_exists(script_file),
			"Cannot open the specified script file. Please check again the name" +
			" or the location of the script.")
	var f = FileAccess.open(script_file, FileAccess.READ)
	
	# Next, parse the contents of the script file into commands understandable
	# by Godot Engine.
	_parse_script(f.get_as_text())
	


# The function for parsing the contents of a script file. To be called from the
# _read_script
func _parse_script(script_file_contents : String) -> void:
	
	var parser = ScriptParser.new()
	_parsed_script_commands = parser.parse_script(script_file_contents)
	_total_command_count = len(_parsed_script_commands)
	


# The function to be called to process and display EACH parsed command.
# When end of script is reached
func _unfold_play() -> void:
	
	# At the beginning of each iteration, increase the number of the current index
	_current_command_index += 1
	
	# If this actually already reaches the end of script, do early termination
	# of this function and send end-of-script signal instead, then destroy this
	# object.
	if (_current_command_index >= _total_command_count):
		emit_signal("end_of_script")
		return
	
	# Grab the command to be processed from the array of parsed commands.
	_currently_processed_command = _parsed_script_commands[_current_command_index]
	print_debug(_currently_processed_command)
	_process_command(_currently_processed_command)
	


# The function to be called for proper processing of the command -- i.e.
# to tell the engine whether to display dialogue or update the stage.
func _process_command(command : Dictionary):
	
	if (command["type"] == "say"):
		$GUINode.update_dialogue(command)
		CasteletGameManager.append_dialogue(command)
	
	elif (command["type"] == "scene"):
		
#		var params = (command['data'] as String).split(".")
#
#		$StageNode.scene(params[0], params[1])

		# First, clear the stage node from props
		for nodes in $StageNode.get_children():
			if nodes is PropNode:
				$StageNode.remove_child(nodes)

		if command['data'] != "none":

			# Second, grab the relevant prop and change its appearance
			var prop_params = (command['data'] as String).split(".")

			var prop : PropNode = AssetsDb.props[prop_params[0]]
			prop.texture = prop.variants[prop_params[1]]

			# Place the prop on stage. If autoscale isn't defined, set to true.
			# Then if no position is defined, set it to (0.5, 1) by default
			prop.position.x = get_viewport().get_visible_rect().size.x * 0.5
			prop.position.y = get_viewport().get_visible_rect().size.y * 1.0

			$StageNode.add_child(prop)

		_unfold_play()


	elif (command["type"] == "show"):
		_unfold_play()
		pass
	
	elif (command["type"] == "hide"):
		_unfold_play()
		pass
	
	elif (command["type"] == "bgm" or command["type"] == "sfx"):
		if command['data'] == "stop":
			$StageNode.stop_audio((command["type"] as String).to_upper())
		elif command['data'] == "pause":
			$StageNode.pause_audio((command["type"] as String).to_upper())
		elif command['data'] == "resume":
			$StageNode.resume_audio((command["type"] as String).to_upper())
		elif command['data'] == "":
			$StageNode.refresh_audio(command['args'], (command["type"] as String).to_upper())
		else:
			$StageNode.play_audio(command["data"], command['args'], (command["type"] as String).to_upper())
	
	elif command["type"] == "window":
		if command["data"] == "show" or command["data"] == "on":
			$GUINode.show_window()
		elif command["data"] == "hide" or command["data"] == "off":
			$GUINode.hide_window()
	
	elif (command["type"] == "pause"):
		_unfold_play()
		pass
	
	elif (command["type"] == "transition"):
		_unfold_play()
		pass
		
	elif (command["type"] == "fade"):
		_unfold_play()
		pass


# Signal handling callbacks go here
func _on_end_of_script() -> void:
	$StageNode.hide()
	$GUINode.hide()
	queue_free()
	print_debug("End of script reached")


# FIXME: this is still somewhat bugged because this can potentially interfere with text in the middle of pausing.
func _on_progress():
	if (_current_command_index < _total_command_count):
		_unfold_play()

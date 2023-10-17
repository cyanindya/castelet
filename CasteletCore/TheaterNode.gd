# The main node of this framework.
# 
# This node serves to read a story file, parse the script contents into commands understandable by
# Godot Engine, and display the cutscene according to the processed script.
# However, since node is NOT a global node, this node has no control over game configurations and
# things those may interrupt the cutscene flow (i.e. context menu) -- see the relevant Autoload nodes
# instead.
#
# This node is dependent on the following singletons:
# - CasteletGameManager
# - CasteletAssetsManager
# - CasteletAudioManager
#
# In general, this node is comprised of the following:
# Variables:
# - script_file (export)                	- The .tsc script file containing cutscene data to be presented.
# - _parsed_script_commands (internal)		- An array of Dictionary data containing script commands to be
#										  	  executed in Godot Engine.
# - _current_command_index (internal)		- index of the currently processed command. Set to -1 at the
#										  	  beginning to handle how cycling through the commands work
#										  	  (so it would actually start from 0).
# - _total_command_count (internal)			- The number of extracted commands from the script. Necessary
#										      to tell the node when to stop trying to cycle through the cutscene.
# - _currently_processed_command (internal)	- Dictionary data containing the currently processed command.
#
# Signals:
# - end_of_script						- Fired when the end of the script has been reached and no more commands
#										  in the _parsed_script_commands can be processed.
#
# Functions:
# - _ready() 				            - Called when node has entered scene tree. Perform initialization
#                                         such as connecting necessary signals to relevant callbacks,
#                                         and do the first call to the cutscene script.
# - _read_script()			            - Open the supplied .tsc script file.
# - _parse_script()			            - convert the contents of the script file into an array of commands
# - _unfold_play()			            - Go to the next command extracted from the script.
# - _process_command()			        - Do the actual StageNode/GUINode redraw here based on the
#                                         command.
#
# Signal callbacks:
# - _on_end_of_script     				- Internal handling of end_of_script signal.
#										  By default, this hides all child nodes before destroying this
#										  particular node.
# - _on_progress                        - Handles CasteletGameManager's progress signal
#                                         By default, tell this node to go through the next part of the
#                                         script as long as end-of-script hasn't been reached.
#
extends Node


# The custom script file to display the cutscene from.
@export_file("*.tsc") var script_file
#@export var default_dialogue_box : StyleBoxTexture
#@export var default_speaker_box : StyleBoxTexture

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
#
#	if (default_dialogue_box != null):
#		$GUINode/DialogueNode/Dialogue.add_theme_stylebox_override("panel", default_dialogue_box)
#	if (default_speaker_box != null):
#		$GUINode/DialogueNode/Speaker.add_theme_stylebox_override("panel", default_speaker_box)
#

	# Connect the required signals to relevant callback functions
	end_of_script.connect(_on_end_of_script)
	CasteletGameManager.progress.connect(_on_progress)
	
	# Read and parse the script
	_read_script()
	
	await get_tree().create_timer(1).timeout
	
	# Go through the parsed commands
	_unfold_play()


# The function for opening the story script file
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
	
	print_debug(_parsed_script_commands)


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
	_process_command(_currently_processed_command)
	


# The function to be called for proper processing of the command -- i.e.
# to tell the engine whether to display dialogue or update the stage.
func _process_command(command : Dictionary):
	
	if (command["type"] == "say"):

		# If the speaker data starts with "id_", make sure to check the assets database
		# for the proper speaker name. This was moved from ScriptParser to decouple the parser
		# from asset manager.
		if (command['speaker'] as String).begins_with("id_"):
			# assert(CasteletAssetsManager.props[command['speaker'].trim_prefix("id_")], "Cannot find the associated prop data from assets manager. Please check the name of the prop and its associated ID again.")
			if not (CasteletAssetsManager.props.has(command['speaker'].trim_prefix("id_"))):
				print_debug("The defined prop does not actually exist. Temporarily assigning prop ID as speaker label.")
				command['speaker'] = command['speaker'].trim_prefix("id_")
			else:
				command['speaker'] = CasteletAssetsManager.props[command['speaker'].trim_prefix("id_")].prop_name
		
		$GUINode.update_dialogue(command)
		if command["speaker"] != "extend":
			CasteletGameManager.append_dialogue(command)
		else:
			CasteletGameManager.append_dialogue_extend(command)
	
	elif (command["type"] == "scene"):
		
		var params = (command['data'] as String).split(".")
		
		if len(params) > 1:
			$StageNode.scene(params[0], params[1], command["args"])
		else:
			$StageNode.scene(params[0], 'default', command["args"])
		

	elif (command["type"] == "show"):
		
		
		var params = (command['data'] as String).split(".")
		
		if len(params) > 1:
			$StageNode.show_prop(params[0], params[1], command["args"])
		else:
			$StageNode.show_prop(params[0], 'default', command["args"])
			
	
	elif (command["type"] == "hide"):
		
		var params = (command['data'] as String).split(".")
		
		$StageNode.hide_prop(params[0])
		
	
	elif (command["type"] == "bgm" or command["type"] == "sfx"):

		if command['data'] == "stop":
			CasteletAudioManager.stop_audio((command["type"] as String).to_upper())
		elif command['data'] == "pause":
			CasteletAudioManager.pause_audio((command["type"] as String).to_upper())
		elif command['data'] == "resume":
			CasteletAudioManager.resume_audio((command["type"] as String).to_upper())
		elif command['data'] == "":
			CasteletAudioManager.refresh_audio(command['args'], (command["type"] as String).to_upper())
		else:
			# print_debug(command["data"])
			if String(command["data"]).begins_with('['):
				CasteletAudioManager.queue_audio(command["data"].trim_prefix('[').trim_suffix(']').split(', '),
										command['args'], (command["type"] as String).to_upper())
			else:
				CasteletAudioManager.play_audio(command["data"], command['args'], (command["type"] as String).to_upper())
		
		CasteletGameManager.progress.emit()
	
	elif command["type"] == "window":
		if command["data"] == "show" or command["data"] == "on":
			$GUINode.show_window()
		elif command["data"] == "hide" or command["data"] == "off":
			$GUINode.hide_window()
		
		# CasteletGameManager.progress.emit()
	
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
	# Ensures the signal handler is disconnected before this node is destroyed, just in case.
	CasteletGameManager.progress.disconnect(_on_progress)
	
	# 
	$StageNode.hide()
	$GUINode.hide()
	
	queue_free()
	print_debug("End of script reached")


func _on_progress():
	if (_current_command_index < _total_command_count):
#		print_orphan_nodes()
		_unfold_play()

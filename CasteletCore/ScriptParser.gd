# A class containing parser to extract script lines and convert it into
# Godot-readable format, which will be processed in TheaterNode afterwards.
# 
# The general rule of thumb of how it works is as follows:
# - When a comment notation appears on the front (#), the line of the script
#   will be ignored.
# - When line break (\\) appears at the end, the currently processed line
#   will be merged with the following line.
# - When @word is detected at the start of the line, the word is treated
#   as keyword for manipulating the stage. The return value is a dictionary
#   containing operation type, the value for update, and additional arguments
#   related to the operation.
# - Dialogue has three possible formats
#   prop_id "Dialogue"
#   "Dialogue" (narrator)
#   "Speaker" "Dialogue"
# - Dialogue lines will be checked through parser for custom tags (e.g. for pausing
#   text)
# 
#  The script will throw error if the detected pattern strays from the rules.

extends RefCounted
class_name ScriptParser


# The function to be called by the main TheaterNode. Runs the extracted raw
# string to be split into lines and checked through the parser
func parse_script(raw_string : String) -> Array:
	var commands = []
	var splitted_script = _split_string_by_lines(raw_string)
	
	# Attempt to parse each extracted line and convert it into Godot-compatible
	# structure.
	for raw_command in splitted_script:
		
		# Ignore comment lines
		if (raw_command as String).begins_with("#"):
			continue
		
		commands.append(_parse(raw_command))
	
	return commands


# Function to split the raw extracted script into a bunch of string arrays before
# it can be processed further into commands understandable by the theater engine.
# It should be noted that there are some actions those take priority while cleaning
# up the script, namely:
# - Some commands (e.g. dialogues) may be split into several lines to improve
#   readability -- these are split using "\\" characters. Remove them first,
#   then convert the separated lines into one string.
# - Finally, the cleaned-up individual command strings are split based on the
#   line feed at the end of each line.
func _split_string_by_lines(raw_string : String) -> Array:
	var commands = []
	
	# Check if the script file ends with the carriage return + line feed instead
	# of only line feed. If it does, replace the line ending with LF first for
	# consistency.
	if raw_string.find("\\r\\n"):
		raw_string = raw_string.replace("\r\n", "\n")
	
	raw_string = raw_string.replace("\\\\\n", "").replace("    ", "")
	commands = raw_string.split("\n", false)
	
	return commands
	

# Function to check the type of the extracted command string using regular expression.
# Based on the results, perform stage refresh (update image/play BGM) or dialogue
# update.
func _parse(command_string : String) -> Dictionary:
	
	# Create new RegEx instance.
	var regex = RegEx.new()
	
	# First, check if the command is a keyword or not (preceded with @).
	# If it is, perform stage update (including show/hide window).
	# Otherwise, treat it as dialogue line (or return errors if the pattern is
	# unrecognized).
	regex.compile("(*UCP)^@\\b(\\w+)(?: )*(\\b[\\w\\d_\\.]+\\b(?!:)|(?:\")[\\w\\d\\._,/ ]+(?:\"))*")
	var result = regex.search(command_string)
	
	if result:
		
		# Get the type of the stage update to be done and the value first
		var action: String = result.get_string(1)
		var param: String = result.get_string(2).replace("\"", "")
		
		# Then, if optional arguments exist, extract the arguments and their values
		var args := {}
		regex.compile("(\\w+):([-_+\\w\\d\\.]+)")
		var arg_result = regex.search_all(command_string)
		
		for rs in arg_result:
			args[rs.get_string(1)] = rs.get_string(2)
		
#		print_debug(args)
		
		# Map the keyword type and the data to be processed.
		return {"type" : action, "data": param, "args": args}
	
	# Otherwise, check the pattern for dialogue-type command first
	# speaker "dialogue"
	# then return the match groups (second and third string).
	# If the second string is empty but the third string exists, it means the
	# dialogue is spoken by narrator.
	regex.clear()
	regex.compile("^(\".*\"|\\w*)(?: )*\"(.*)\"")
	result = regex.search(command_string)
	
	if result:
		# If the speaker label is not a one-off name, mark it with "id_"
		# prefix to be checked later in TheaterNode.
		# While we can just directly reference the asset manager, we want
		# to decouple it if possible -- parser should just stay as parser
		# and has no knowledge of other nodes.
		var speaker = result.get_string(1)
		if not speaker.is_empty():
			if speaker.begins_with("\"") and speaker.ends_with("\""):
				speaker = speaker.replace("\"", "")
			else:
				speaker = "_".join(["id", speaker])
			
		var dialogue = _pause_detector(result.get_string(2))
		
		# Perform script cleanup for back-slashed tags
		# TODO: Unicode and whitespace handling using regex
		dialogue["final_string"] = (dialogue["final_string"] as String).replace("\\n", "\n")
		
		return { "type" : "say", "speaker" : speaker, "dialogue" : dialogue["final_string"],
				"pause_locations": dialogue["pause_locations"],
				"pause_durations": dialogue["pause_durations"] }
	
	return {}
		

# The function to detect whether the dialogue has pauses or not.
# Returns the clean dialogue and the pause locations and their respective durations
# if applicable.
# TODO: convert to a more general parser for detecting more tags.
func _pause_detector(dialogue_string : String) -> Dictionary:
	
	var pause_regex = RegEx.new()
	pause_regex.compile("{(?:p|w)(?:=(\\d*\\.*\\d*))*}") # example format: {p=2.5}, {w}, {p=2}
	
	var temp_result = pause_regex.search_all(dialogue_string)
	
	if temp_result:
		
		var pause_locations = []
		var pause_durations = []
		
		# For each result, find the location and the duration
		for rs in temp_result:
			
			# If there are multiple pause tags, there will be offset from the removed
			# tags in the clean text.
			# Adjust the pause location based on availability of previous tags.
			# (Credits to World Eater Games here: https://worldeater-dev.itch.io/
			# bittersweet-birthday/devlog/224241/howto-a-simple-dialogue-system-in-godot)
			var left := rs.get_start() as int
			var previous_tags := pause_regex.search_all(dialogue_string.left(left))
			for prev in previous_tags:
				left -= prev.get_string().length()
			pause_locations.append(left)
			
			# Check the duration of the pause. If no duration is specified, set it
			# to 0, where it will wait for player input instead to continue.
			if rs.get_string(1) == "":
				pause_durations.append(0.0)
			else:
				pause_durations.append(rs.get_string(1) as float)
		
		return {"final_string" : pause_regex.sub(dialogue_string, "", true),
				"pause_locations": pause_locations, "pause_durations" : pause_durations}
	
	return {"final_string" : dialogue_string, "pause_locations": [], "pause_durations": []}
	

extends RefCounted

# The function to detect non-BBCode custom tags, mainly for dialogue pauses and auto-dismiss.
# Returns the clean dialogue and the pause locations and their respective durations
# if applicable.
func extract_custom_non_bbcode_tags(dialogue_string : String) -> Dictionary:

	# Regex for auto-dismiss tag
	var nowait_regex = RegEx.new()
	nowait_regex.compile("(\\[nw\\])$")

	var nowait_result = nowait_regex.search(dialogue_string)

	var auto_dismiss = false
	if nowait_result:
		auto_dismiss = true
		# print_debug("nowait tag detected")
		dialogue_string = nowait_regex.sub(dialogue_string, "", true)
	
	# Regular expressions for detecting pauses
	var pause_regex = RegEx.new()
	pause_regex.compile("\\[(?:w)(?:=(\\d*\\.*\\d*))*\\]") # example format: [w=2.5], [w], [w=2]
	
	var temp_result = pause_regex.search_all(dialogue_string)

	# Regular expressions for searching BBCodes (for correcting offsets)
	var bbcode_start_regex = RegEx.new()
	var bbcode_end_regex = RegEx.new()
	bbcode_start_regex.compile("\\[(?!\\/|\\bw\\b)(.*?)\\]") # search for everything except for custom wait
	bbcode_end_regex.compile("\\[\\/(.*?)\\]")
	
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
			var initial_left = left
			var previous_tags := pause_regex.search_all(dialogue_string.left(initial_left))
			for prev in previous_tags:
				left -= prev.get_string().length()
			
			# Calculate offset caused by BBCodes
			var bbcode_tags_start := bbcode_start_regex.search_all(dialogue_string.left(initial_left))
			for bbcode_tag_start in bbcode_tags_start:
				left -= bbcode_tag_start.get_string().length()
			var bbcode_tags_end := bbcode_end_regex.search_all(dialogue_string.left(initial_left))
			for bbcode_tag_end in bbcode_tags_end:
				left -= bbcode_tag_end.get_string().length()
			
			# Finally append the pause location
			pause_locations.append(left)
			
			# Check the duration of the pause. If no duration is specified, set it
			# to 0, where it will wait for player input instead to continue.
			if rs.get_string(1) == "":
				pause_durations.append(0.0)
			else:
				pause_durations.append(rs.get_string(1) as float)
		
		return {"dialogue" : pause_regex.sub(dialogue_string, "", true),
				"args" : { "pause_locations": pause_locations,
							"pause_durations" : pause_durations,
							"auto_dismiss" : auto_dismiss,
						}
				}
	
	return {"dialogue" : dialogue_string, "args" : { "pause_locations": [],
			"pause_durations" : [], "auto_dismiss" : auto_dismiss,}
			}

extends HBoxContainer

func load_dialogue(speaker: String, dialogue: String):
	$SpeakerLabel.text = speaker
	$DialogueLabel.text = dialogue

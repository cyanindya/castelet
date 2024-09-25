extends Node

@export var base_text_speed : float = 30
@export var base_automode_timeout : float = 3
@export var default_dialogue_box : StyleBoxTexture
@export var default_speaker_box : StyleBoxTexture

# A configuration that forces the player to stay on choice screen until
# a choice is made. Otherwise, "default" choice or previously-given choice
# is automatically selected.
@export var forcibly_stop_ffwd_on_choices := true

# After choice is made, configure whether the skipping mode will resume
# or will be stopped.
@export var continue_ffwd_after_choices := false

# TODO: Save/load with .cfg file

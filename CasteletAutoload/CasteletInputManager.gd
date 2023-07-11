# An autoload/singleton node intended to handle Castelet-specific inputs, then emit specific
# input-related signals for other nodes to listen to.
# 
# It should be noted that this singleton is built to handle input events, and ONLY input events.
# As such, it is discouraged to implement control of other singletons here.
#
# To prevent this node's signals from going through during certain circumstances (e.g. while
# game menu is active), use CasteletManager.set_block_signals(true) while said elements are active
extends Node

signal castelet_confirm
signal castelet_ffwd_hold(param: bool)
signal castelet_ffwd_toggle


# To prevent possible double-input when using certain keyboards, see the following link for implementation reference:
# https://stackoverflow.com/questions/69981662/godot-input-is-action-just-pressed-runs-twice
func _unhandled_input(event):

	var single_key_press : bool = not (event is InputEventKey and event.echo)
	
	if event.is_action("confirm") and event.pressed and single_key_press:
		castelet_confirm.emit()
	
	if event.is_action("hold_ffwd"):
		if event.pressed:
			castelet_ffwd_hold.emit(true)
		else:
			castelet_ffwd_hold.emit(false)
	
	if event.is_action("toggle_ffwd") and event.pressed and single_key_press:
		castelet_ffwd_toggle.emit()

	


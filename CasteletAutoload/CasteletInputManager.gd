# An autoload/singleton node example that showcases handling of Castelet-specific inputs according
# to the signals set up by the CasteletGameManager.
# It is discouraged to implement control of other Castelet autoloads here.
#
# To prevent the input going through during certain circumstances (e.g. while
# game menu is active), use CasteletGameManager.set_block_signals(true) while said elements are active
extends Node

# To prevent possible double-input when using certain keyboards, see the following link for implementation reference:
# https://stackoverflow.com/questions/69981662/godot-input-is-action-just-pressed-runs-twice
func _unhandled_input(event):

    var single_key_press : bool = not (event is InputEventKey and event.echo)
    
    if event.is_action("confirm") and event.pressed and single_key_press:
        CasteletGameManager.confirm.emit()
    
    if event.is_action("hold_ffwd"):
        if event.pressed:
            CasteletGameManager.ffwd_hold.emit(true)
        else:
            CasteletGameManager.ffwd_hold.emit(false)
    
    if event.is_action("toggle_ffwd") and event.pressed and single_key_press:
        CasteletGameManager.ffwd_toggle.emit()

    


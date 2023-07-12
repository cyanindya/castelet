# An autoload/singleton node intended to handle Castelet-specific inputs according to the signals
# set up by the CasteletGameManager.
# It is discouraged to implement control of other Castelet autoloads here.
#
# To prevent the input going through during certain circumstances (e.g. while
# game menu is active), use CasteletGameManager.set_block_signals(true) while said elements are active
extends Node

@export_node_path("CasteletGameManager") var game_manager


func _ready():
    if game_manager == null:
        game_manager = get_node("/root/CasteletGameManager")
        assert(game_manager != null, "Cannot find any valid instance of CasteletGameManager. Check whether the node has been included in the scene tree and try again.")


# To prevent possible double-input when using certain keyboards, see the following link for implementation reference:
# https://stackoverflow.com/questions/69981662/godot-input-is-action-just-pressed-runs-twice
func _unhandled_input(event):

    var single_key_press : bool = not (event is InputEventKey and event.echo)
    
    if event.is_action("confirm") and event.pressed and single_key_press:
        game_manager.confirm.emit()
    
    if event.is_action("hold_ffwd"):
        if event.pressed:
            game_manager.ffwd_hold.emit(true)
        else:
            game_manager.ffwd_hold.emit(false)
    
    if event.is_action("toggle_ffwd") and event.pressed and single_key_press:
        game_manager.ffwd_toggle.emit()

    


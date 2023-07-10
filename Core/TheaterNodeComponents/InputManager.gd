extends Node

signal castelet_confirm
signal castelet_skip(param: bool)

# Dirty input implementation
# To prevent possible double-input when using certain keyboards, see the following link for implementation reference:
# https://stackoverflow.com/questions/69981662/godot-input-is-action-just-pressed-runs-twice
func _unhandled_input(event):
    
    if event.is_action("ui_accept") and event.pressed and not event.echo:
        castelet_confirm.emit()
    
    if event.is_action("skip_dialogue"):
        if event.pressed:
            castelet_skip.emit(true)
        else:
            castelet_skip.emit(false)
    
    

extends Resource

class_name PropResource

@export var prop_id := ""
@export var prop_name := ""
@export var variants := { 'default' : null } # should've been typed as string/file pair. TYPED DICTIONARY WHEN????

@export_range(0.0, 1.0) var x_anchor = 0.5
@export_range(0.0, 1.0) var y_anchor = 0.5
@export var centered : bool = false

# Why is there no easy way to convert export dictionary keys to selectable enums????

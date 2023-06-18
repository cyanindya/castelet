extends Resource

class_name PropResource

@export var prop_id := ""
@export var prop_name := ""
@export var variants := { 'default' : null } # should've been typed as string/file pair. TYPED DICTIONARY WHEN????

# Why is there no easy way to convert export dictionary keys to selectable enums????

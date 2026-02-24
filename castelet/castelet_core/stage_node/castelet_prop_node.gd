extends Sprite2D
class_name CasteletPropNode


signal _viewport_scale_changed
signal _flip_toggled

var prop_name : String
var in_viewport_scale := 0.1:
	set(value):
		in_viewport_scale = value
		_viewport_scale_changed.emit()

var _variants := {}
var _flip_aliases := {}
var _active_variant = "default"

var _xanchor : float = 0.0
var _yanchor : float = 0.0
var _is_flipped = false:
	set(value):
		_is_flipped = value
		_flip_toggled.emit()


func _init(prop : CasteletPropResource, default_variant := "default"):
	
	name = prop.prop_id
	prop_name = prop.prop_name
	
	for variant in prop.variants.keys():
		if prop.variants[variant] != null:
			_variants[variant] = load(prop.variants[variant])
		else:
			_variants[variant] = null
	
	for flip_variant in prop.flip_aliases.keys():
		if prop.flip_aliases[flip_variant] != null:
			_flip_aliases[flip_variant] = load(prop.flip_aliases[flip_variant])
		else:
			pass
	
	
	texture = _variants[default_variant]
	centered = prop.centered

	_xanchor = prop.x_anchor
	_yanchor = prop.y_anchor
	

func _ready():
	
	_viewport_scale_changed.connect(_recalculate_scale)
	texture_changed.connect(_on_texture_changed)
	_flip_toggled.connect(_on_flip_toggled)
	
	in_viewport_scale = 1.0
	_recalculate_scale()


func _calculate_anchor():
	
	var xsize = get_rect().size.x
	var ysize = get_rect().size.y
	
	offset = Vector2(-xsize * _xanchor, -ysize * _yanchor)


func _recalculate_scale():
	_calculate_anchor()
	scale = Vector2(in_viewport_scale, in_viewport_scale)


func _on_texture_changed():
	# We need to recalculate the rect bounds and the positioning of the offset
	_recalculate_scale()


## Function to be called when _flip_toggled() signal is emitted.
## When _is_flipped is true, check if the same prop variant has different sprite
## for flipped display first. (e.g. different sprite due to asymmetrical hair)
## If not, simply flip the sprite.
func _on_flip_toggled():
	print_debug("flip state toggled to " + ("true" if _is_flipped else "false"))
	
	set_variant(_active_variant)
	
	if _is_flipped:
		if _flip_aliases.has(_active_variant):
			flip_h = false
		else:
			flip_h = true
	else: # Don't forget to reset the sprite flipping state!
		flip_h = false


func set_variant(variant: String):
	_active_variant = variant
	
	if (_variants.has(variant)):
		if _is_flipped and _flip_aliases.has(_active_variant):
			texture = _flip_aliases[_active_variant]
		else:
			texture = _variants[_active_variant]
	else:
		texture = null
		print_debug("The variant is not defined in the prop resource dictionary. Skipping.")


func get_active_variant():
	return _active_variant


func set_flip(flip_state := false):
	_is_flipped = flip_state


func get_flip():
	return _is_flipped

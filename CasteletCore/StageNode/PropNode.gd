extends Sprite2D
class_name PropNode

var prop_name : String
var variants := {}
var in_viewport_scale := 0.1:
	set(value):
		in_viewport_scale = value
		viewport_scale_changed.emit()
var _xanchor : float = 0.0
var _yanchor : float = 0.0

signal viewport_scale_changed


func _init(propResource : PropResource, default_variant := "default"):
	
	name = propResource.prop_id
	prop_name = propResource.prop_name
	
	for variant in propResource.variants.keys():
		if propResource.variants[variant] != null:
			variants[variant] = load(propResource.variants[variant])
		else:
			variants[variant] = null
	
	texture = variants[default_variant]
	centered = propResource.centered

	_xanchor = propResource.x_anchor
	_yanchor = propResource.y_anchor
	


func _ready():
	
	viewport_scale_changed.connect(_recalculate_scale)
	texture_changed.connect(_on_texture_changed)
	
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

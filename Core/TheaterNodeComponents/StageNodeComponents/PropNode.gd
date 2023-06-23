extends Sprite2D
class_name PropNode

var prop_name : String
var variants := {}
var default_viewport_scale := 1.0
var _xanchor : float = 0.0
var _yanchor : float = 0.0


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
	
	# Calculate the default scale too
	default_viewport_scale = CasteletConfig.base_scale_factor
	
	_calculate_anchor()
	scale = Vector2(default_viewport_scale, default_viewport_scale)


func _calculate_anchor():
	
	var xsize = get_rect().size.x
	var ysize = get_rect().size.y
	
	offset = Vector2(-xsize * _xanchor, -ysize * _yanchor)
	

func _on_texture_changed():
	# We need to recalculate the rect bounds and the positioning of the offset
	_calculate_anchor()

func _on_item_rect_changed():
	# We need to recalculate the rect bounds and the positioning of the offset
	_calculate_anchor()

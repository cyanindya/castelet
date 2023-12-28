extends CanvasLayer

var viewport_transition_functions = {
	"fade" = _fade,
	"crossfade" = _crossfade_screen,
	"pixelate" = _pixelate_screen,
	"dissolve" = _dissolve_screen,
}

var transition_types = {
	"fade" = [TransitionType.VIEWPORT],
	"crossfade" = [TransitionType.VIEWPORT, TransitionType.OBJECT],
	"pixelate" =  [TransitionType.VIEWPORT, TransitionType.OBJECT],
	"dissolve" =  [TransitionType.VIEWPORT, TransitionType.OBJECT],
}

var dissolve_transition_presets = {}

enum TransitionType {
	VIEWPORT,
	OBJECT,
}

var transitioning : bool = false
var _transition_tween : Tween
const TheaterNode = preload("res://CasteletCore/TheaterNode.gd")
var _theater_node : TheaterNode

signal transition_completed

func _ready():

	CasteletResourceLoader.load_all_resources_of_type("res://", self, "_load_dissolve_presets")

	transition_completed.connect(_on_transition_completed)
	
	if _transition_tween:
		_transition_tween.kill()


func _load_dissolve_presets(file_name : String):

	# If the file is a proper Godot resource file (.tres), load the resource,
	# then check if it is a PropResource-type data. If it is, generate
	# an instance of PropNode that can be used in the Theater node later.
	#
	# TODO: check if the loaded resource can potentially cause memory leak
	# if it is NOT of compatible type -- how do we handle it?
	if file_name.ends_with(".tres"):

		var res: Resource = load(file_name)
		
		if res is DissolveTransitionMaterialListResource:
			for item in (res.transitions as Dictionary):
				dissolve_transition_presets[item] = load(res.transitions[item])
		


func transition(transition_name, transition_type, args={}, callback : Callable = Callable()):
	
	transitioning = true

	if transition_type == TransitionType.VIEWPORT:
		viewport_transition(transition_name, args, callback)


func viewport_transition(transition_name, args={}, callback : Callable = Callable()):
	
	var pre_transition_vp_texture: Texture2D

	if callback != null:
		pre_transition_vp_texture = _take_viewport_texture()
	
	(viewport_transition_functions[transition_name] as Callable).bind(pre_transition_vp_texture, null, args, callback).call()

func _dissolve_screen(old_widget : Texture2D = null, new_widget : Texture2D = null,
	args={}, callback : Callable = Callable()):

	var shader_param = func _set_shader_param(value : float, mat : Material):
		mat.set_shader_parameter("cutoff", value)


	var time = 0.5
	var preset = "square_blinds"
	var smoothness = 0.5

	if args.has("time"): time = args["time"]
	if args.has("smoothness"): smoothness = args["smoothness"]
	if args.has("preset"): preset = args["preset"]

	var canvas = CanvasLayer.new()
	var sprite : Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = old_widget
	# var color_rect : ColorRect = ColorRect.new()
	# color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# color_rect.color.a = 0
	canvas.add_child(sprite)
	# canvas.add_child(color_rect)
	get_tree().root.add_child(canvas)

	var transitionMaterial : ShaderMaterial
	transitionMaterial = dissolve_transition_presets[preset]
	sprite.material = transitionMaterial
	sprite.material.set_shader_parameter("cutoff", 0.0)
	sprite.material.set_shader_parameter("smoothness", smoothness)
	sprite.material.set_shader_parameter("tex_a", old_widget)
	

	if _transition_tween:
		_transition_tween.kill()
	
	_transition_tween = create_tween()
	_transition_tween.tween_callback(callback)
	_transition_tween.tween_method(shader_param.bind(sprite.material), 0.0, 1.0, time)

	await _transition_tween.finished
	
	# color_rect.queue_free()
	# sprite.queue_free()
	# canvas.queue_free()

	transition_completed.emit()



func _pixelate_screen(old_widget : Texture2D = null, new_widget : Texture2D = null,
	args={}, callback : Callable = Callable()):

	
	var pixelate_shader_param = func _set_shader_param(value : float, alp :float, mat : Material):
		mat.set_shader_parameter("px_size", value)
		mat.set_shader_parameter("old_screen_alpha", alp)

	
	var in_time : float = 0.5
	var stay_time : float = 0.1
	var out_time : float = 0.5
	var px_size : float = 100.0
	var shape = "square"
	
	if args.has("in_time"): in_time = args["in_time"]
	if args.has("stay_time"): stay_time = args["stay_time"]
	if args.has("out_time"): out_time = args["out_time"]
	if args.has("px_size"): px_size = args["px_size"]
	if args.has("shape"): shape = args["shape"]
	
	if _transition_tween:
		_transition_tween.kill()

	var canvas = CanvasLayer.new()
	# var sprite : Sprite2D = Sprite2D.new()
	# sprite.centered = false
	# sprite.texture = old_widget
	var color_rect : ColorRect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# canvas.add_child(sprite)
	canvas.add_child(color_rect)
	get_tree().root.add_child(canvas)

	
	var pixellateMaterial : ShaderMaterial
	if shape == "hex":
		pixellateMaterial = load("res://CasteletCore/shaders/TwoTextureHexagonPixelateShader.tres")
	else:
		pixellateMaterial = load("res://CasteletCore/shaders/TwoTexturePixelateShader.tres")
	color_rect.material = pixellateMaterial
	color_rect.material.set_shader_parameter("px_size", 1.0)
	color_rect.material.set_shader_parameter("old_widget", old_widget)
	
	
	_transition_tween = create_tween()
	_transition_tween.tween_method(pixelate_shader_param.bind(1.0, color_rect.material), 1.0, px_size, in_time)
	_transition_tween.tween_callback(callback)
	_transition_tween.tween_interval(stay_time)
	_transition_tween.tween_method(pixelate_shader_param.bind(0.0, color_rect.material), px_size, 1.0, out_time)

	await _transition_tween.finished

	#color_rect.queue_free()
	## sprite.queue_free()
	#canvas.queue_free()

	transition_completed.emit()
	

func _crossfade_screen(old_widget : Texture2D = null, new_widget : Texture2D = null,
	args={}, callback : Callable = Callable()):
	
	var time = 0.5

	if args.has("time"): time = args["time"]

	if _transition_tween:
		_transition_tween.kill()

	var canvas = CanvasLayer.new()
	var sprite : Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = old_widget
	# var color_rect : ColorRect = ColorRect.new()
	# color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# color_rect.color.a = 0
	canvas.add_child(sprite)
	# canvas.add_child(color_rect)
	get_tree().root.add_child(canvas)
	
	sprite.texture = old_widget
	sprite.modulate.a = 1.0
	sprite.centered = false # the centered setting bonks the entire placement
	
	_transition_tween = create_tween()
	_transition_tween.tween_property(sprite, "modulate:a", 0.0, time)
	
	await _transition_tween.finished
	
	# color_rect.queue_free()
	sprite.queue_free()
	canvas.queue_free()

	transition_completed.emit()


func _fade(old_widget : Texture2D = null, new_widget : Texture2D = null,
	args={}, callback : Callable = Callable()):
	
	var in_time : float = 0.5
	var stay_time : float = 0.5
	var out_time : float = 0.5
	var color : Color = Color.BLACK

	if args.has("in_time"): in_time = args["in_time"]
	if args.has("stay_time"): stay_time = args["stay_time"]
	if args.has("out_time"): out_time = args["out_time"]
	if args.has("color"): color = args["color"]

	if _transition_tween:
		_transition_tween.kill()

	var canvas = CanvasLayer.new()
	var sprite : Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.texture = old_widget
	var color_rect : ColorRect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color.a = 0
	canvas.add_child(sprite)
	canvas.add_child(color_rect)
	get_tree().root.add_child(canvas)
	
	_transition_tween = create_tween()
	_transition_tween.tween_property(color_rect, "color", color, 0.0)
	_transition_tween.parallel().tween_property(color_rect, "color:a", 1.0, in_time)
	_transition_tween.tween_property(sprite, "modulate:a", 0.0, 0.0)
	_transition_tween.tween_callback(callback)
	_transition_tween.tween_interval(stay_time)
	_transition_tween.tween_property(color_rect, "color", color, 0.0)
	_transition_tween.parallel().tween_property(color_rect, "color:a", 0.0, out_time)

	await _transition_tween.finished

	color_rect.queue_free()
	sprite.queue_free()
	canvas.queue_free()

	transition_completed.emit()
	

func _take_viewport_texture(viewport : Viewport = get_viewport()) -> Texture2D:
	
	var img = viewport.get_texture().get_image()
	var vp_texture = ImageTexture.create_from_image(img)

	return vp_texture

func _on_transition_completed():
	transitioning = false


func set_theater_node(node : TheaterNode):
	_theater_node = node

# func transition(caller_node_name : String, transition_name, args={}):

# 	# _transition_rect = get_node(caller_node_name + "/TransitionCanvasLayer/Sprite2D")
# 	_transition_rect = get_node(caller_node_name + "/TransitionCanvasLayer/TransitionColorRect")

	
# 	var pre_transition_screenshot : Image = get_viewport().get_texture().get_image()
# 	var pre_transition_texture = ImageTexture.create_from_image(pre_transition_screenshot)
# 	pre_transition_screenshot.save_jpg("test.jpg")

# 	if transition_name == Transitions.CROSSFADE:
# 		var time = 0.5
# 		if "time" in args.keys():
# 			time = args["time"]
# 		_crossfade(time, pre_transition_texture)


# func _fade(in_time = 0.5, stay_time = 0.5, out_time = 0.5, color = Color.BLACK,
# 	old_widget : Texture = null, new_widget : Texture = null):

# 	if _transition_tween:
# 		_transition_tween.kill()
	

# func _crossfade(time = 0.5, old_widget : Texture = null, new_widget : Texture = null):

# 	var primitive2dMaterial : ShaderMaterial = load("res://CasteletCore/shaders/Primitive2D.tres")
# 	_transition_rect.material = primitive2dMaterial
# 	_transition_rect.material.set_shader_parameter("old", old_widget)
# 	_transition_rect.material.set_shader_parameter("old_new_mix", 0.0)
# 	_transition_rect.visible = true

# 	# _transition_rect.texture = old_widget
	
# 	if _transition_tween:
# 		_transition_tween.kill()
	
# 	_transition_tween = create_tween()
# 	_transition_tween.finished.connect(_await_completed)
# 	_transition_tween.tween_method(func(alpha): _transition_rect.material.set_shader_parameter("alpha", alpha), 1.0, 0.0, time)

# 	await _transition_tween.finished

# 	_transition_rect.visible = false

# 	# _transition_rect.texture = null
	

# func _await_completed():
# 	print("completed")


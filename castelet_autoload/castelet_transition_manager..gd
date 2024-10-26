extends CanvasLayer
## The singleton that handles transition requests from the TheaterNode.
##
## When TheaterNode requests for scene changes through transition,
## it will call the transition() function in this singleton, supplying
## the transition name, the transition range (viewport level or object
## level), and the transition properties (e.g. time). If viewport transition
## is requested, it will then call viewport_transition() function; otherwise,
## object_transition() function is called.
##
## In general, the viewport transition works as follows:
## - take a screenshot of the viewport shortly before the transition
## - convert the screenshot to 2D sprite, then add it as a child to this
##	 CanvasLayer instance
## - while the CanvasLayer is showing, update the viewport (i.e. show/hide
##   the props)
## - use tween to gradually make the sprite in the CanvasLayer (the old
##   screenshot) invisible
## - once the tween is completed, reset the sprite and/or color rect
## - emit the transition_completed signal
##
## Meanwhile, the object transition instead delegates the transition/
## tweening to StageNode. As such, the process instead is as follows:
## - save the intended transition data (e.g. move) in a local variable here
## - when calling the _update_stage() or _hide_stage() in TheaterNode,
##   supply the saved transition data
## - do the tweening in StageNode based on the transition data
## - have the StageNode emit transition_completed signal

## The signal to be emitted once a transition is completed.
## This is meant to control/block certain functions of Castelet so they won't
## be executed until this signal is emitted.
signal transition_completed
# signal viewport_redrawn

## Defines the scope of the transition. Viewport transition redraws the entire
## screen, while object transitions affects only the specified object.
enum TransitionScope {VIEWPORT, OBJECT}

#const TheaterNode = preload("res://castelet_core/theater_node.gd")

## The variable that will contains the names of predefined image-controlled
## dissolve transitions. This will be loaded on _ready() using the
## CasteletResourceLoaded singleton and _load_dissolve_presets function.
var dissolve_transition_presets = {}

## Variables containing standard transition types and the relevant functions
## to be executed, as well as the transition scope. Some transitions are
## applicable for viewport or object only, while others are applicable for both.
var viewport_transition_functions = {
	"fade" = _fade,
	"crossfade" = _crossfade_screen,
	"pixelate" = _pixelate_screen,
	"dissolve" = _dissolve_screen,
	"wipe" = _wipe_screen,
	"slide" = _slide_screen,
}
var transition_types = {
	"fade" = [TransitionScope.VIEWPORT],
	"crossfade" = [TransitionScope.VIEWPORT, TransitionScope.OBJECT],
	"pixelate" =  [TransitionScope.VIEWPORT, TransitionScope.OBJECT],
	"dissolve" =  [TransitionScope.VIEWPORT, TransitionScope.OBJECT],
	"wipe" =  [TransitionScope.VIEWPORT, TransitionScope.OBJECT],
	"slide" = [TransitionScope.VIEWPORT],
	"move" = [TransitionScope.OBJECT],
}
var _tween_transition_types = {
	"linear" = Tween.TRANS_LINEAR,
	"sine" = Tween.TRANS_SINE,
	"quint" = Tween.TRANS_QUINT,
	"quart" = Tween.TRANS_QUART,
	"quad" = Tween.TRANS_QUAD,
	"expo" = Tween.TRANS_EXPO,
	"elastic" = Tween.TRANS_ELASTIC,
	"cubic" = Tween.TRANS_CUBIC,
	"circ" = Tween.TRANS_CIRC,
	"bounce" = Tween.TRANS_BOUNCE,
	"back" = Tween.TRANS_BACK,
	"spring" = Tween.TRANS_SPRING,
}
var _tween_ease_types = {
	"in" = Tween.EASE_IN,
	"out" = Tween.EASE_OUT,
	"in_out" = Tween.EASE_IN_OUT,
	"out_in" = Tween.EASE_OUT_IN,
}

## Variable to control current transition state. While transition still in
## progress, certain functions may be blocked or ignored.
var transitioning : bool = false

## 
var vp : Viewport

## Tween object to animate the transition from old scene to new scene.
var _transition_tween : Tween

## Define shortcuts for the sprite and color-rect sub-nodes
var sprite : Sprite2D
var color_rect : ColorRect

## A dictionary to store data regarding impending object transition to
## be executed by StageNode.
var object_transition_data = {}


func _ready():
	# Command the resource loader singleton to load predefined image-dissolve
	# transitions and put them to the dissolve_transition_presets variable.
	var _res_loader : CasteletResourceLoader = CasteletResourceLoader.new()
	_res_loader.load_all_resources_of_type("res://", self,
			"_load_dissolve_presets")

	# Connect the "transition_completed" signal to _on_transition_completed()
	# function.
	transition_completed.connect(_on_transition_completed)
	
	# Always make sure to clear existing transition tween before reusing it.
	if _transition_tween:
		_transition_tween.kill()
	
	# Connect the shorthands to sub-nodes
	sprite = $Sprite2D
	color_rect = $ColorRect


## The main transition function to be called from the TheaterNode. This
## function accepts the following parameters:
## - transition_name	:	The name of the transition to be called.
## - transition_scope	:	The scope of the transition.
## - args (optional)	:	Various arguments to control the transition.
##							(e.g. time)
##
## Different transition functions will then be called depending on the name
## and scope of the transition.
func transition(transition_name, transition_scope, args={}):
	# Make sure to note that transition is currently active, so certain
	# functions will be blocked to ensure smooth transition.
	transitioning = true

	if transition_scope == TransitionScope.VIEWPORT:
		viewport_transition(transition_name, args)
	else:
		object_transition(transition_name, args)


## The main function to be called when viewport transition is requested.
## Based on the detected transition name, it will call upon different
## transition functions as listed under viewport_transition_functions.
func viewport_transition(transition_name, args={}):
	
	# Reset all sprite and color rect materials when transition is finished.
	sprite.texture = null
	sprite.material = null
	color_rect.material = null
	color_rect.modulate.a = 0.0

	# Take screenshot of the viewport's appearance shortly before the
	# transition, and convert it to 2D texture to be placed on CanvasLayer
	# later.
	var pre_transition_vp_texture: Texture2D
	pre_transition_vp_texture = _take_viewport_texture(vp)
	# pre_transition_vp_texture.get_image().save_jpg("pre.jpg")

	# Preemptively set old widget as visible
	sprite.texture = pre_transition_vp_texture
	sprite.modulate.a = 1.0

	# Wait until sub-viewport draws the new frame, then take screenshot of new frame
	# await viewport_redrawn
	await RenderingServer.frame_post_draw
	var post_transition_vp_texture: Texture2D
	post_transition_vp_texture = _take_viewport_texture(vp)
	# post_transition_vp_texture.get_image().save_jpg("post.jpg")

	# Retrieve specific function from the viewport_transition_functions dict,
	# then call it by supplying the old transition screenshot and the arguments.
	(viewport_transition_functions[transition_name] as Callable).bind(
			pre_transition_vp_texture, post_transition_vp_texture, args
			).call()
	
	await transition_completed
	
	# Reset all sprite and color rect materials when transition is finished.
	sprite.texture = null
	sprite.material = null
	color_rect.material = null
	color_rect.modulate.a = 0.0


## The main function to be called when object transition is requested.
## Based on the detected transition name, it will call upon different
## transition functions as listed under object_transition_functions.
func object_transition(transition_name, args={}):
	object_transition_data["transition_name"] = transition_name
	for key in args.keys():
		object_transition_data[key] = args[key]
	pass # TODO


#func set_theater_node(node : TheaterNode):
	#_theater_node = node


## The function to be called when "fade" transition is requested.
## This is a viewport-level transition that will replace the old scene
## with a new one after briefly showing a solid color in the entire
## screen.
##
## Fade transition is controlled with the following parameters,
## which are supplied through the args:
## - in_time	:	The interval between the old screen to the solid
##					color to be displayed. Default is 0.5 seconds.
## - stay_time	:	Duration of how long the solid color will be displayed.
##					Default is 0.5 seconds.
## - out_time	:	The interval between the solid color to the new screen.
##					Default is 0.5 seconds.
## - color		:	The color to be displayed between the old and new screens.
##					Default is black.
func _fade(_old_widget : Texture2D = null, _new_widget : Texture2D = null, args={}):
	
	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
	var in_time : float = 0.5
	var stay_time : float = 0.5
	var out_time : float = 0.5
	var color : Color = Color.BLACK

	if args.has("in_time"): in_time = args["in_time"]
	if args.has("stay_time"): stay_time = args["stay_time"]
	if args.has("out_time"): out_time = args["out_time"]
	if args.has("color"): color = args["color"]

	# Clear the transition tween before use.
	if _transition_tween:
		_transition_tween.kill()

	# Use the tween to animate between the old scene, the solid color,
	# then to the new scene.
	_transition_tween = create_tween()
	_transition_tween.tween_property(color_rect, "color", color, 0.0)
	_transition_tween.parallel().tween_property(color_rect, "color:a",
			1.0, in_time)
	_transition_tween.tween_property(sprite, "modulate:a", 0.0, 0.0)
	#_transition_tween.tween_callback(callback)
	_transition_tween.tween_interval(stay_time)
	_transition_tween.tween_property(color_rect, "color", color, 0.0)
	_transition_tween.parallel().tween_property(color_rect, "color:a",
			0.0, out_time)

	# Once the tween is completed, destroy the CanvasLayer, the old
	# screenshot, and the color rect.
	await _transition_tween.finished

	# Emit the signal to signify the transition is completed.
	transition_completed.emit()
	

## The function to be called when "crossfade" transition is requested.
## This is a viewport-level transition that will gradually replace the
## old scene with a new one. Also known as "dissolve" on Ren'Py.
##
## Crossfade transition is controlled with the following parameters,
## which are supplied through the args:
## - time	:	The interval between the old screen to the new screen.
##				Default is 0.5 seconds.
func _crossfade_screen(_old_widget : Texture2D = null, _new_widget : Texture2D = null, args={}):
	
	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
	var time = 0.5
	if args.has("time"): time = args["time"]

	# Clear the transition tween before use.
	if _transition_tween:
		_transition_tween.kill()

	# Use the tween to animate between the old scene, the solid color,
	# then to the new scene.
	_transition_tween = create_tween()
	_transition_tween.tween_property(sprite, "modulate:a", 0.0, time)
	
	# Once the tween is completed, destroy the CanvasLayer and the old
	# screenshot.
	await _transition_tween.finished
	
	transition_completed.emit()


## The function to be called when image-controlled dissolve transition is
## requested. The control image is a black-to-white image signifying the
## direction of the transition.
## This is a viewport-level transition that will replace the old scene
## with a new one based on the brightness of the control image, which is
## controlled using custom shader.
##
## Image-controlled dissolve is controlled with the following parameters,
## which are supplied through the args:
## - time		:	The interval between the old screen to the new screen.
##					Default is 0.5 seconds.
## - preset		:	The control image preset to be used. You should define
##					them using DissolveTransitionMaterialListResource resource.
##					Default is "square_blinds".
## - smoothness	:	The smoothness of the transition between the old image to
##					the new image. 0 is hard-edged, 1 is very smooth.
##					Default is 0.5.
func _dissolve_screen(old_widget : Texture2D = null, _new_widget : Texture2D = null, args={}):

	# As noted, image-controlled dissolve requires custom shader that can gradually
	# control the alpha value of the texture based on the control image's brightness
	# and the set cutoff value.
	# We will use the cutoff value to be changed gradually using tween.
	var shader_param = func _set_shader_param(value : float, mat : Material):
		mat.set_shader_parameter("cutoff", value)

	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
	var time = 0.5
	var preset = "square_blinds"
	var smoothness = 0.5

	if args.has("time"): time = args["time"]
	if args.has("smoothness"): smoothness = args["smoothness"]
	if args.has("preset"): preset = args["preset"]

	# Unlike previous basic transitions, we first need to
	# define a shader material and attach it to the screenshot texture.
	# The shader values will be tweened through the shader material
	# later.
	var transitionMaterial : ShaderMaterial
	transitionMaterial = dissolve_transition_presets[preset]
	sprite.material = transitionMaterial
	sprite.material.set_shader_parameter("cutoff", 0.0)
	sprite.material.set_shader_parameter("smoothness", smoothness)
	sprite.material.set_shader_parameter("tex_a", old_widget)
	
	# Tween the shader material to gradually hide the old screenshot.
	if _transition_tween:
		_transition_tween.kill()
	
	_transition_tween = create_tween()
	#_transition_tween.tween_callback(callback)
	_transition_tween.tween_method(shader_param.bind(sprite.material), 0.0, 1.0, time)

	# Once the tween is completed, destroy the CanvasLayer and the old
	# screenshot.
	await _transition_tween.finished
	
	transition_completed.emit()


## The function to be called when pixelate transition is requested.
## This is a viewport-level transition that will replace the old scene
## with a new one after pixelating the screen, which is controlled
## using custom shader.
##
## Pixelation is controlled with the following parameters,
## which are supplied through the args:
## - in_time	:	The interval between the old screen to the pixelated
##					version to be displayed. Default is 0.5 seconds.
## - stay_time	:	Duration of how long the pixelated version will be displayed.
##					Default is 0.1 seconds.
## - out_time	:	The interval between the pixelated screen to the new screen.
##					Default is 0.5 seconds.
## - px_size	:	The size of the simplified "pixel. Default is 100 px.
## - shape		:	The shape of the pixel chunks: either square or hex.
##					Default is "square".
func _pixelate_screen(old_widget : Texture2D = null, _new_widget : Texture2D = null, args={}):

	# As noted, pixelation requires custom shader that can distort the texture
	# into large chunks of pixels.
	# We will use the pixel size to be changed gradually using tween.
	var pixelate_shader_param = func _set_shader_param(value : float, alp : float, mat : Material):
		mat.set_shader_parameter("px_size", value)
		mat.set_shader_parameter("old_screen_alpha", alp)

	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
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

	# Define a shader material and attach it to the screenshot texture.
	# The shader values will be tweened through the shader material
	# later.
	var pixellateMaterial : ShaderMaterial
	if shape == "hex":
		pixellateMaterial = load("res://castelet_core/shaders/two_texture_hexagon_pixelate_shader.tres")
	else:
		pixellateMaterial = load("res://castelet_core/shaders/two_texture_pixelate_shader.tres")
	
	sprite.material = pixellateMaterial
	sprite.material.set_shader_parameter("px_size", 1.0)
	sprite.material.set_shader_parameter("old_widget", old_widget)
	# sprite.material.set_shader_parameter("new_widget", new_widget)
	
	# Tween the shader material to gradually hide the old screenshot.
	_transition_tween = create_tween()
	_transition_tween.tween_method(pixelate_shader_param.bind(1.0, sprite.material),
			1.0, px_size, in_time)
	#_transition_tween.tween_callback(callback)
	_transition_tween.tween_interval(stay_time)
	_transition_tween.tween_method(pixelate_shader_param.bind(0.0, sprite.material),
			px_size, 1.0, out_time)

	# Once the tween is completed, destroy the CanvasLayer and the old
	# screenshot.
	await _transition_tween.finished
	transition_completed.emit()


## The function to be called when wipe transition is requested.
## This is a viewport-level transition that will replace the old scene
## with a new one using linear wipe effect, which is controlled
## using custom shader.
##
## Wipe is controlled with the following parameters,
## which are supplied through the args:
## - time		:	The interval between the old screen to the new screen.
##					Default is 0.5 seconds.
## - direction	:	Direction of which the wipe effect will move to.
##					Default is "right".
## - smoothness	:	Determine whether the wipe effect will be sharp or smooth.
##					Default is 0 (sharp-edged)
func _wipe_screen(old_widget : Texture2D = null, new_widget : Texture2D = null, args={}):
	
	var wipe_shader_param = func _set_shader_param(value : float, mat : Material):
		mat.set_shader_parameter("cutoff", value)

	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
	var time : float = 0.5
	var direction : String = "right"
	var smoothness : float = 0
	
	if args.has("time"): time = args["time"]
	if args.has("dir"): direction = args["dir"]
	if args.has("direction"): direction = args["direction"]
	if args.has("smooth"): smoothness = args["smooth"]
	if args.has("smoothness"): smoothness = args["smoothness"]

	sprite.texture = old_widget
	sprite.modulate.a = 1.0
	
	if _transition_tween:
		_transition_tween.kill()

	# Define a shader material and attach it to the screenshot texture.
	# The shader values will be tweened through the shader material
	# later.
	var linearWipeMaterial : ShaderMaterial
	linearWipeMaterial = load("res://castelet_core/shaders/two_texture_linear_wipe_shader.tres")
	sprite.material = linearWipeMaterial
	sprite.material.set_shader_parameter("tex_a", old_widget)
	sprite.material.set_shader_parameter("tex_b", new_widget)
	sprite.material.set_shader_parameter("cutoff", -1.0)
	sprite.material.set_shader_parameter("smoothness", smoothness)
	if direction == "right":
		sprite.material.set_shader_parameter("direction", 0)
	elif direction == "left":
		sprite.material.set_shader_parameter("direction", 1)
	elif direction in ["up", "top"]:
		sprite.material.set_shader_parameter("direction", 2)
	elif direction in ["down", "bottom"]:
		sprite.material.set_shader_parameter("direction", 3)
	else:
		print_debug("Unidentified direction for linear wipe. " +
				"Reverting back to 'right' direction.")
		sprite.material.set_shader_parameter("direction", 0)
	
	var lower_cutoff := -1.0
	var upper_cutoff := 1.0

	if direction in ["left", "up", "top"]:
		upper_cutoff = 0.15
	else:
		lower_cutoff = -0.15

	# Tween the shader material to gradually hide the old screenshot.
	_transition_tween = create_tween()
	_transition_tween.tween_method(wipe_shader_param.bind(sprite.material),
			lower_cutoff, upper_cutoff, time)

	await _transition_tween.finished
	transition_completed.emit()


## The function to be called when slideshow transition is requested.
## This is a viewport-level transition that will replace the old scene
## with a new one using linear slideshow, which is controlled
## using custom shader.
##
## Slideshow effect is controlled with the following parameters,
## which are supplied through the args:
## - time		:	The interval between the old screen to the new screen.
##					Default is 0.5 seconds.
## - direction	:	Direction of which the wipe effect will move to:
##					- in_left (default)
##					  The new screen will slide in from left.
##					- in_right
##					  The new screen will slide in from right.
##					- in_top
##					  The new screen will slide in from above.
##					- in_bottom
##					  The new screen will slide in from below.
##					- out_left
##					  The old screen will slide out to left.
##					- out_right
##					  The old screen will slide out to right.
##					- out_top
##					  The old screen will slide out to top.
##					- out_bottom
##					  The old screen will slide out to bottom.
## - interpolation	:	The interpolation used to replace the new screen with
##						new one. Default is linear. See Godot's documentation on
##						TransitionType enum for details. # TODO
## - easing			:	The easing function used to replace the new screen with
##						new one. Default is in_out. See Godot's documentation on
##						EaseType enum for details. # TODO
func _slide_screen(old_widget : Texture2D = null, new_widget : Texture2D = null, args={}):

	# Using shader because I'm too lazy to simply add new sprite to the canvas layer (...)
	var shader_param = func _set_shader_param(value : float, mat : Material):
		mat.set_shader_parameter("cutoff", value)

	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
	var time : float = 0.5
	var direction : String = "in_left"
	var interpolation : String = "linear"
	var easing : String = "in_out"
	
	if args.has("time"): time = args["time"]
	if args.has("dir"): direction = args["dir"]
	if args.has("direction"): direction = args["direction"]
	if args.has("interpolation"): interpolation = args["interpolation"]
	if args.has("easing"): easing = args["easing"]
	if args.has("ease"): easing = args["ease"]
	
	if _transition_tween:
		_transition_tween.kill()


	# Define a shader material and attach it to the screenshot texture.
	# The shader values will be tweened through the shader material
	# later.
	var slideMaterial : ShaderMaterial
	slideMaterial = load("res://castelet_core/shaders/two_texture_slide_shader.tres")
	sprite.material = slideMaterial
	sprite.material.set_shader_parameter("old_tex", old_widget)
	sprite.material.set_shader_parameter("new_tex", new_widget)
	sprite.material.set_shader_parameter("cutoff", 0.0)

	if direction.begins_with("in_"):
		sprite.material.set_shader_parameter("transition_in", true)
	elif direction.begins_with("out_"):
		sprite.material.set_shader_parameter("transition_in", false)
	else:
		print_debug("Unidentified direction for slide transition. " +
				"Reverting back to 'in' direction.")
		sprite.material.set_shader_parameter("transition_in", true)
		
	if direction in ["in_right", "out_right"]:
		sprite.material.set_shader_parameter("direction", 0)
	elif direction in ["in_left", "out_left"]:
		sprite.material.set_shader_parameter("direction", 1)
	elif direction in ["in_top", "in_up", "out_top", "out_up"]:
		sprite.material.set_shader_parameter("direction", 2)
	elif direction in ["in_bottom", "in_down", "out_bottom", "out_down"]:
		sprite.material.set_shader_parameter("direction", 3)
	else:
		print_debug("Unidentified direction for slide transition. " +
				"Reverting back to 'in_right' direction.")
		sprite.material.set_shader_parameter("direction", 0)
	
	# Tween the shader material to gradually hide the old screenshot.
	_transition_tween = create_tween()
	_transition_tween.set_ease(_tween_ease_types[easing])
	_transition_tween.set_trans(_tween_transition_types[interpolation])
	_transition_tween.tween_method(shader_param.bind(sprite.material),
			0.0, 1.0, time)

	await _transition_tween.finished

	transition_completed.emit()


func move_object(prop : PropNode, to : Vector2 = Vector2(1.0, 0.0), from : Vector2 = Vector2(0.0, 0.0),
		args = {}):

	# Set up the default values of the controlling parameters.
	# If custom value defined through the arguments, use them.
	var time : float = 0.5
	var interpolation : String = "linear"
	var easing : String = "in_out"
	
	if args.has("time"): time = args["time"]
	if args.has("interpolation"): interpolation = args["interpolation"]
	if args.has("easing"): easing = args["easing"]
	if args.has("ease"): easing = args["ease"]
	
	if _transition_tween:
		_transition_tween.kill()
	
	_transition_tween = create_tween()
	_transition_tween.tween_property(prop, "position", to, time).from(from) \
			.set_trans(_tween_transition_types[interpolation]) \
			.set_ease(_tween_ease_types[easing])

	await _transition_tween.finished
	transition_completed.emit()


## This private function is to be called in the _ready() so it will
## automatically search for resources where the image dissolve presets
## are defined.
func _load_dissolve_presets(file_name : String):

	# If the file is a proper Godot resource file (.tres), load the resource,
	# then check if it is a DissolveTransitionMaterialListResource.
	#
	# TODO: check if the loaded resource can potentially cause memory leak
	# if it is NOT of compatible type -- how do we handle it?
	if file_name.ends_with(".tres"):

		var res: Resource = load(file_name)
		
		# Add the defined dissolve presets.
		if res is DissolveTransitionMaterialListResource:
			for item in (res.transitions as Dictionary):
				dissolve_transition_presets[item] = load(res.transitions[item])


## This private function gets the screenshot of the viewport and
## returns it as a 2D texture for later use.
func _take_viewport_texture(viewport : Viewport = get_viewport()) -> Texture2D:
	
	var img = viewport.get_texture().get_image()
	var vp_texture = ImageTexture.create_from_image(img)

	return vp_texture


## This function is to be linked and automatically executed when "transition_completed"
## signal is fired. In this case, set the "transitioning" variable to false
## so the previously blocked functions can finally resume.
func _on_transition_completed():
	transitioning = false
	object_transition_data = {}

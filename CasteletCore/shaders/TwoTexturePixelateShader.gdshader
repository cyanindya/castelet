shader_type canvas_item;
render_mode unshaded;

uniform float px_size : hint_range(1.0, 100.0, 5.0) = 20.0;
uniform float old_screen_alpha : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_nearest;
uniform sampler2D old_widget;
//uniform sampler2D new_widget;

// adapted from https://godotshaders.com/shader/pixelate-2/
void fragment() {
	ivec2 size = textureSize(old_widget, 0);

	int xRes = size.x;
	int yRes = size.y;

	float xFactor = float(xRes) / float(px_size);
	float yFactor = float(yRes) / float(px_size);

	vec2 uv = UV;

	float grid_uv_x = round(uv.x * xFactor) / xFactor;
	float grid_uv_y = round(uv.y * yFactor) / yFactor;
	//grid_uv_x += UV.x * 0.5;
	//grid_uv_y += UV.y * 0.5;
	//grid_uv_x *= 0.65;
	//grid_uv_y *= 0.65;

	vec4 old_text = texture(old_widget, vec2(grid_uv_x, grid_uv_y));
	vec4 new_text = texture(screen_texture, vec2(grid_uv_x, grid_uv_y));
	//vec4 new_text = texture(new_widget, vec2(grid_uv_x, grid_uv_y));

	COLOR = mix(new_text, old_text, old_screen_alpha);

}
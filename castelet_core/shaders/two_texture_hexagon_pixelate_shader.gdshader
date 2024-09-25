shader_type canvas_item;
render_mode unshaded;

uniform float px_size = 20;
uniform float old_screen_alpha : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_nearest;
uniform sampler2D old_widget;
//uniform sampler2D new_widget;

void fragment() {
	vec2 norm_size = vec2(px_size, px_size) * SCREEN_PIXEL_SIZE;
	bool half = mod(SCREEN_UV.y / 2.0, norm_size.y) / norm_size.y < 0.5;
	vec2 uv = SCREEN_UV + vec2(norm_size.x * 0.5 * float(half), 0.0);
	vec2 center_uv = floor(uv / norm_size) * norm_size;
	vec2 norm_uv = mod(uv, norm_size) / norm_size;
	center_uv += mix(vec2(0.0, 0.0),
				mix(mix(vec2(norm_size.x, -norm_size.y),
						vec2(0, -norm_size.y),
						float(norm_uv.x < 0.5)),
					mix(vec2(0.0, -norm_size.y),
						vec2(-norm_size.x, -norm_size.y),
						float(norm_uv.x < 0.5)),
					float(half)),
				float(norm_uv.y < 0.3333333333333) * float(norm_uv.y / 0.33333333333333 < (abs(norm_uv.x - 0.5) * 2.0)));
	vec4 old_scr = textureLod(old_widget, center_uv, 0.0);
	//vec4 new_scr = textureLod(new_widget, center_uv, 0.0);
	vec4 new_scr = textureLod(screen_texture, center_uv, 0.0);
	COLOR = mix(new_scr, old_scr, old_screen_alpha);
	
}
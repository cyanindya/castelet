shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tex_a : hint_default_transparent;
uniform sampler2D tex_b : hint_default_transparent;
uniform float tex_mix : hint_range(0.0, 1.0) = 1.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex_a_color = texture(tex_a, UV);
	vec4 tex_b_color = texture(tex_b, UV);
	COLOR.rgb = mix(tex_a_color, tex_b_color, tex_mix).rgb;
	COLOR.a = alpha;
}

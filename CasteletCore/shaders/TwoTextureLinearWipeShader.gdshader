shader_type canvas_item;
render_mode unshaded;

uniform sampler2D tex_a : hint_default_transparent;
uniform sampler2D tex_b : hint_default_transparent;
uniform float cutoff : hint_range(-1.0, 1.0) = 0.0;
uniform int direction : hint_range(0, 3, 1) = 0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_a_color = texture(tex_a, UV);
	vec4 tex_b_color = texture(tex_b, UV);
	float fac = 0.0;
	switch (direction) {
		case 0: // Right
			fac = smoothstep(cutoff, cutoff + smoothness, (smoothness + UV.x) / (1.0 + smoothness));
			break;
		case 1: // Left
			fac = smoothstep(cutoff, cutoff + smoothness, (smoothness - UV.x) / (1.0 + smoothness));
			break;
		case 2: // Top
			fac = smoothstep(cutoff, cutoff + smoothness, (smoothness - UV.y) / (1.0 + smoothness));
			break;
		case 3: // Bottom
			fac = smoothstep(cutoff, cutoff + smoothness, (smoothness + UV.y) / (1.0 + smoothness));
			break;
		default:
			break;
	}
	COLOR.rgb = mix(tex_b_color, tex_a_color, clamp(fac, 0.0, 1.0)).rgb;
	COLOR.a = mix(tex_b_color.a * (1.0 - fac), tex_a_color.a * (fac), clamp(fac, 0.0, 1.0));
			
}
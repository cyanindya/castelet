shader_type canvas_item;
render_mode unshaded;

uniform sampler2D old_tex;
uniform sampler2D new_tex;
uniform bool transition_in = true;
uniform float cutoff : hint_range(0.0, 1.0) = 0.0;
uniform int direction : hint_range(0, 3, 1) = 1;

void fragment() {
	
	vec2 old_tex_uv = UV;
	vec2 new_tex_uv = UV;
	
	switch (direction) {
		case 0: // Right
			if (transition_in) new_tex_uv.x = UV.x + 1.0 - cutoff;
			else old_tex_uv.x = UV.x - cutoff;
			break;
		case 1: // Left
			if (transition_in) new_tex_uv.x = UV.x - 1.0 + cutoff;
			else old_tex_uv.x = UV.x + cutoff;
			break;
		case 2: // Top
			if (transition_in) new_tex_uv.y = UV.y - 1.0 + cutoff;
			else old_tex_uv.y = UV.y + cutoff;
			break;
		case 3: // Bottom
			if (transition_in) new_tex_uv.y = UV.y + 1.0 - cutoff;
			else old_tex_uv.y = UV.y - cutoff;
			break;
		default:
			break;
	}
	
	vec4 old_tex_color = texture(old_tex, old_tex_uv);
	vec4 new_tex_color = texture(new_tex, new_tex_uv);
	
	COLOR = old_tex_color;
	
	if (new_tex_color.a >= old_tex_color.a) {
		switch (direction) {
			case 0:
				if (transition_in) {
					if (UV.x < cutoff) {COLOR = new_tex_color;}
				}
				else {
					if (UV.x < cutoff) {COLOR = new_tex_color;}
				}
				break;
			case 1:
				if (transition_in) {
					if (UV.x > 1.0 - cutoff) {COLOR = new_tex_color;}
				}
				else {
					if (UV.x > 1.0 - cutoff) {COLOR = new_tex_color;}
				}
				break;
			case 2:
				if (transition_in) {
					if (UV.y > 1.0 - cutoff) {COLOR = new_tex_color;}
				}
				else {
					if (UV.y > 1.0 - cutoff) {COLOR = new_tex_color;}
				}
				break;
			case 3:
				if (transition_in) {
					if (UV.y < cutoff) {COLOR = new_tex_color;}
				}
				else {
					if (UV.y < cutoff) {COLOR = new_tex_color;}
				}
				break;
			default:
				COLOR = old_tex_color;
				break;
		}
	}
}
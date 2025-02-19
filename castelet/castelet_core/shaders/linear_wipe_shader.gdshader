shader_type canvas_item;
render_mode unshaded;

uniform float cutoff : hint_range(-1.0, 1.0) = 0.0;
uniform int direction : hint_range(0, 3, 1) = 0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	switch (direction) {
		case 0: // Right
			//if (UV.x < cutoff) COLOR.a = 0.0;
			//else COLOR.a *= 1.0;
			COLOR.a *= smoothstep(cutoff, cutoff + smoothness, (smoothness + UV.x) / (1.0 + smoothness));
			break;
		case 1: // Left
			//if (1.0 - UV.x < cutoff) COLOR.a = 0.0;
			//else COLOR.a *= 1.0;
			COLOR.a *= smoothstep(cutoff, cutoff + smoothness, (smoothness - UV.x) / (1.0 + smoothness));
			break;
		case 2: // Top
			//if (1.0 - UV.y < cutoff) COLOR.a = 0.0;
			//else COLOR.a *= 1.0;
			COLOR.a *= smoothstep(cutoff, cutoff + smoothness, (smoothness - UV.y) / (1.0 + smoothness));
			break;
		case 3: // Bottom
			//if (UV.y < cutoff) COLOR.a = 0.0;
			//else COLOR.a *= 1.0;
			COLOR.a *= smoothstep(cutoff, cutoff + smoothness, (smoothness + UV.y) / (1.0 + smoothness));
			break;
		default:
			break;
	}
}
shader_type canvas_item;
render_mode unshaded;


// Taken from GDQuest tutorial
uniform sampler2D tex_a : hint_default_transparent;
uniform sampler2D tex_b : hint_default_transparent;

uniform float cutoff : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D maskTexture : filter_linear, repeat_enable;
uniform bool tiled = true;
uniform bool centerUV = true;
uniform bool invert = false;
uniform float tileAdjustFactor = 1.0;

void fragment() {
	vec2 uv = UV;
	if (centerUV) uv = (UV * 2.0 - 1.0) / 2.0;
	
	vec4 tex_a_color = texture(tex_a, UV);
	vec4 tex_b_color = texture(tex_b, UV);
	
	if (tiled) {
		uv = uv / (TEXTURE_PIXEL_SIZE) / vec2(textureSize(maskTexture, 0));
		uv /= tileAdjustFactor;
	}
	
	float value = 0.0;
	
	if (invert) {
		value = 1.0 - texture(maskTexture, uv).r;
	}
	else {
		value = texture(maskTexture, uv).r;
	}
	float alpha = smoothstep(cutoff, cutoff + smoothness, value * (1.0 - smoothness) + smoothness);
	COLOR = mix(tex_b_color, tex_a_color, alpha);
	COLOR.a = mix(tex_b_color.a, tex_a_color.a, alpha);
}
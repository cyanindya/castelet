shader_type canvas_item;
render_mode unshaded;


// Taken from GDQuest tutorial
uniform sampler2D tex_a : hint_default_transparent;
uniform sampler2D tex_b : hint_default_transparent;
uniform sampler2D screen_texture : hint_screen_texture, repeat_enable, filter_nearest;

uniform float cutoff : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D maskTexture : filter_linear, repeat_enable;
uniform bool tiled = true;
uniform bool centerUV = true;
uniform bool invert = false;
uniform float tileAdjustFactor = 1.0;
uniform bool useScreenTexture = true;

void fragment() {
	vec2 uv = UV;
	if (centerUV) uv = (UV * 2.0 - 1.0) / 2.0;
	
	vec4 tex_a_color = textureLod(tex_a, UV, 0.0);
	vec4 tex_b_color = vec4(0.0);
	if (useScreenTexture) tex_b_color = textureLod(screen_texture, UV, 0.0);
	else tex_b_color = textureLod(tex_b, UV, 0.0);
	
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
	float alpha = smoothstep(cutoff, cutoff + smoothness, (value + smoothness) / (1.0 + smoothness));
	COLOR.rgb = mix(tex_b_color.rgb, tex_a_color.rgb, alpha);
	COLOR.a = mix(tex_b_color.a, tex_a_color.a, alpha);
}
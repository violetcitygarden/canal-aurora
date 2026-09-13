shader_type canvas_item;
// Keep the hand-painted vertex colours intact. The glyph atlas is monochrome,
// so using its RGB channels here would turn the whole logo black and white.
uniform float strength = 0.24;
void fragment() {
	vec2 uv = UV;
	float wobble = sin(uv.y * 31.0 + TIME * 1.7) * 0.0010;
	uv.x += wobble * strength;
	float glyph_alpha = texture(TEXTURE, uv).a;
	float bleed_left = texture(TEXTURE, uv + vec2(0.0010 * strength, 0.0)).a;
	float bleed_right = texture(TEXTURE, uv - vec2(0.0010 * strength, 0.0)).a;
	float alpha = max(glyph_alpha, max(bleed_left, bleed_right) * 0.20);
	float grain = (fract(sin(dot(floor(uv * 480.0) + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.012;
	vec3 painted_color = COLOR.rgb + grain;
	COLOR = vec4(clamp(painted_color, vec3(0.0), vec3(1.0)), COLOR.a * alpha);
}

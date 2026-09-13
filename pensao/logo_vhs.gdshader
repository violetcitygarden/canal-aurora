shader_type canvas_item;
// A gentle tape wobble keeps the lettering readable while matching the VHS era.
uniform float strength = 0.65;
void fragment() {
	vec2 uv = UV;
	float wobble = sin(uv.y * 31.0 + TIME * 1.7) * 0.0015;
	uv.x += wobble * strength;
	vec4 base = texture(TEXTURE, UV);
	vec4 shifted = texture(TEXTURE, uv);
	shifted.r = texture(TEXTURE, uv + vec2(0.0008 * strength, 0.0)).r;
	shifted.b = texture(TEXTURE, uv - vec2(0.0008 * strength, 0.0)).b;
	float grain = (fract(sin(dot(floor(uv * 480.0) + TIME, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * 0.025;
	shifted.rgb += grain * shifted.a;
	COLOR = mix(base, shifted, strength);
}

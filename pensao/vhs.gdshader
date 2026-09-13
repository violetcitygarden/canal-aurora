shader_type canvas_item;
uniform bool enabled = true;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
    vec2 uv = UV;
    if (!enabled) { COLOR = texture(TEXTURE, uv); }
    else {
        float t = floor(TIME * 12.0);
        float displacement = sin(uv.y * 78.0 + TIME * 2.0) * 0.0009;
        float band = smoothstep(0.022, 0.0, abs(uv.y - fract(TIME * 0.065)));
        uv.x += displacement + band * 0.005;
        vec3 c = texture(TEXTURE, uv).rgb;
        c.r = texture(TEXTURE, uv + vec2(0.0022, 0.0)).r;
        c.b = texture(TEXTURE, uv - vec2(0.0022, 0.0)).b;
        float grain = (hash(vec2(floor(uv.x * 640.0), floor(uv.y * 480.0)) + t) - 0.5) * 0.06;
        c += grain;
        c *= 0.96 + 0.04 * sin(uv.y * 480.0 * 3.14159);
        c = floor(clamp(c, 0.0, 1.0) * 31.0) / 31.0;
        c *= 1.0 - 0.20 * pow(length((UV - 0.5) * 1.4), 2.0);
        COLOR = vec4(c, 1.0);
    }
}

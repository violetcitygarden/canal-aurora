shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform bool textured = false;
uniform vec2 repeat_uv = vec2(1.0);
void vertex() {
    vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec2 grid = vec2(320.0, 240.0);
    clip.xy = floor((clip.xy / clip.w) * grid + 0.5) / grid * clip.w;
    POSITION = clip;
}
void fragment() {
    ALBEDO = tint.rgb * (textured ? texture(albedo_tex, UV * repeat_uv).rgb : vec3(1.0));
    ROUGHNESS = 1.0;
}

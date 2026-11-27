shader_type spatial;
render_mode cull_front, unshaded, depth_draw_opaque;
uniform float thickness = 2.2;
uniform vec4 color : source_color = vec4(0.03, 0.03, 0.06, 1.0);
void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 off = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	float l = length(off);
	if (l > 0.0001) { off /= l; }
	clip.xy += off * thickness * clip.w * 2.0 / VIEWPORT_SIZE;
	POSITION = clip;
}
void fragment() {
	ALBEDO = color.rgb;
}

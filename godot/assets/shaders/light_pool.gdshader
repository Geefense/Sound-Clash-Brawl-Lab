shader_type spatial;
// Visible stage-light pool on the sand: a soft additive ellipse under the fighters that
// carries the afternoon / sunset / night rig. It sits on top of the real SpotLight3D
// illumination instead of replacing it, so the rim and toon bands still read.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 pool_colour : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.25;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = 1.0 - smoothstep(0.15, 1.0, d);
	ALBEDO = pool_colour.rgb * intensity * a;
	ALPHA = a * intensity;
}

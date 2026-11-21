shader_type spatial;
// Soft sun disc: high and white in the afternoon, low and orange at sunset, gone at night.
// Additive, unshaded and camera-facing; the arena's phase palette animates colour/alpha.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 disc_colour : source_color = vec4(1.0, 0.92, 0.72, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.7;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float core = 1.0 - smoothstep(0.0, 1.0, d);
	core = pow(core, 1.6);
	ALBEDO = disc_colour.rgb * core * intensity;
	ALPHA = core * intensity;
}

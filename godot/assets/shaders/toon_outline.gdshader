shader_type spatial;
// Inverted-hull comic ink outline. Assigned as the toon material's `next_pass`: the back
// faces are expanded in clip space and drawn dark while the front faces are culled, which
// gives a constant ~2 px ink edge at any camera distance or model scale.
//
// WebGL2 safe: unshaded, one pass, no screen reads, no loops.
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

uniform vec4 ink_colour : source_color = vec4(0.022, 0.016, 0.030, 1.0);
uniform float ink_width : hint_range(0.0, 0.02) = 0.0032;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 normal_view = normalize((PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	clip.xy += normal_view.xy * ink_width * clip.w * 2.0;
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink_colour.rgb;
}

shader_type spatial;
// Sky/backdrop gradient for the 3D yard. A single unshaded quad behind the crowd; the phase
// palette pushes three stops plus a horizon haze band into it, so afternoon / sunset / night
// are real scene colours rather than a tinted overlay.
//
// Bug 5 (2026-11-25): the middle stop is what gives the sunset its crimson band between the
// violet zenith and the orange horizon; two stops could only ever fade one hue into another.
// The haze band is a separate low-sky wash, so the horizon glows without flattening the zenith.
// WebGL2 safe: unshaded, one pass, no screen reads, no loops.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 top_colour : source_color = vec4(0.12, 0.44, 0.85, 1.0);
uniform vec4 mid_colour : source_color = vec4(0.42, 0.68, 0.96, 1.0);
uniform vec4 bottom_colour : source_color = vec4(1.0, 0.91, 0.69, 1.0);
uniform vec4 haze_colour : source_color = vec4(1.0, 0.94, 0.76, 1.0);
uniform float mid_point : hint_range(0.05, 0.95) = 0.52;
uniform float haze_height : hint_range(0.0, 1.0) = 0.20;
uniform float haze_strength : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	float y = clamp(1.0 - UV.y, 0.0, 1.0);
	float mid = clamp(mid_point, 0.05, 0.95);
	vec3 colour = mix(bottom_colour.rgb, mid_colour.rgb, smoothstep(0.0, mid, y));
	colour = mix(colour, top_colour.rgb, smoothstep(mid, 1.0, y));
	float haze = 1.0 - smoothstep(0.0, max(haze_height, 0.01), y);
	colour = mix(colour, haze_colour.rgb, haze * haze_strength);
	ALBEDO = colour;
}

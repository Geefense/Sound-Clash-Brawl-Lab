shader_type spatial;
// Sky/backdrop gradient for the 3D yard. A single unshaded quad behind the crowd; the phase
// palette pushes two colours into it, so afternoon / sunset / night are real scene colours
// rather than a tinted overlay.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 top_colour : source_color = vec4(0.33, 0.62, 0.92, 1.0);
uniform vec4 bottom_colour : source_color = vec4(1.0, 0.83, 0.58, 1.0);
uniform vec4 haze_colour : source_color = vec4(1.0, 0.90, 0.72, 1.0);
uniform float haze_height : hint_range(0.0, 1.0) = 0.10;

void fragment() {
	float y = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 colour = mix(bottom_colour.rgb, top_colour.rgb, smoothstep(0.0, 1.0, y));
	float haze = 1.0 - smoothstep(0.0, max(haze_height, 0.01), y);
	colour = mix(colour, haze_colour.rgb, haze * 0.35);
	ALBEDO = colour;
}

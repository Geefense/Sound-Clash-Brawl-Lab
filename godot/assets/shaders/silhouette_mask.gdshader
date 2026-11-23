shader_type spatial;
// Rim-lit 2.5D silhouette for the crowd and the DJ booth (owner playtest, 2026-11-23).
//
// The stand-in figures are no longer lathed capsules: each one is one camera-facing quad
// whose alpha mask is painted at start-up by `SilhouetteArt`. The mask texture packs two
// channels so a single cheap fragment pass draws the whole figure:
//   G — body coverage (the dark ink shape)
//   R — rim coverage (the same shape dilated by a few pixels)
// The thin R-only band is the rim light, so the palette (`rim_colour`) can repaint every
// silhouette in the yard without touching a texture.
//
// WebGL2 (gl_compatibility) safe: no screen or depth reads, no loops, no includes, one
// texture fetch, no lighting model. Unshaded with a small emissive rim so the figures keep
// reading at night when the stage goes cyan/magenta.

render_mode unshaded, cull_disabled, shadows_disabled, depth_draw_never, blend_mix, fog_disabled;

uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 body_colour : source_color = vec4(0.055, 0.05, 0.07, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.74, 0.34, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.9;
uniform float rim_power : hint_range(0.5, 6.0) = 1.7;
uniform float rim_energy : hint_range(0.0, 2.0) = 0.55;
uniform float alpha_mul : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 mask = texture(mask_tex, UV);
	float body = mask.g;
	float rim = max(mask.r - body, 0.0);
	float glow = clamp(pow(rim, rim_power) * rim_strength, 0.0, 1.0);
	// Inside the shape the face is the dark ink; the R-only band shows the lit rim, hottest
	// right at the contour and fading into the background.
	vec3 rim_tint = rim_colour.rgb * (0.70 + 0.45 * glow);
	ALBEDO = mix(rim_tint, body_colour.rgb, body);
	EMISSION = rim_colour.rgb * glow * rim_energy;
	ALPHA = max(body, mask.r) * alpha_mul;
}

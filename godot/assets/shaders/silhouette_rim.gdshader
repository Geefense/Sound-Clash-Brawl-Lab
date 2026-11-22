shader_type spatial;
// Dark-silhouette rim material for the 3D crowd and the DJ booth (2026-11-22).
//
// WebGL2 / GL Compatibility safe: one forward pass with the built-in `diffuse_toon` /
// `specular_toon` banding, no custom light(), no screen or depth reads, no includes and no
// loops. The body stays near-black so the crowd reads as silhouettes against the lit yard,
// and the fresnel band paints the stage rim along the edge of every shoulder, hat and arm.
// `accent` is the warm lift used by the lighter flames and DJ airhorn moments; it is a
// uniform on a shared material, not a per-instance parameter, because GL Compatibility
// does not support instance uniforms.
render_mode diffuse_toon, specular_toon, depth_draw_opaque, cull_back;

uniform vec4 body_colour : source_color = vec4(0.05, 0.045, 0.06, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.74, 0.34, 1.0);
uniform float rim_strength : hint_range(0.0, 3.0) = 0.85;
uniform float rim_power : hint_range(1.0, 8.0) = 2.6;
uniform vec4 accent_colour : source_color = vec4(1.0, 0.54, 0.18, 1.0);
uniform float accent : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	ALBEDO = body_colour.rgb;
	ROUGHNESS = 0.92;
	SPECULAR = 0.06;
	METALLIC = 0.0;
	// Directional rim band; VIEW and NORMAL are already in view space.
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = rim_colour.rgb * rim * rim_strength + accent_colour.rgb * accent;
}

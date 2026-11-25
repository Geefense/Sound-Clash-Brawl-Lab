shader_type spatial;
// Sound Clash Brawl — spatial cel / toon material for the 3D fighter models.
//
// WebGL2 / GL Compatibility safe: one forward pass, built-in `diffuse_toon` and
// `specular_toon` banding (no custom light() function, no screen texture, no includes,
// no loops). The ink outline is a separate `next_pass` (toon_outline.gdshader) so the
// silhouette is an inverted hull rather than a post-process.
//
// The albedo is the owner's painted character texture. `tint` and `hue_shift` distinguish
// the two placeholder roster slots without touching the source image on disk.
render_mode diffuse_toon, specular_toon, depth_draw_opaque, cull_back;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float hue_shift : hint_range(-0.5, 0.5) = 0.0;
uniform vec4 rim_colour : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform float rim_strength : hint_range(0.0, 2.5) = 0.55;
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform vec4 shadow_tint : source_color = vec4(0.30, 0.36, 0.58, 1.0);
uniform float shadow_tint_amount : hint_range(0.0, 1.0) = 0.20;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_colour : source_color = vec4(1.0, 0.93, 0.72, 1.0);
// Per-instance palette accent (Bug 4c, 2026-11-25). One shared material can dress twenty-two
// different crowd rigs because each GeometryInstance3D carries its own accent colour here.
// It is ADDED to the rim band only, never multiplied into ALBEDO: the delivered texture keeps
// its full brightness, and if a Web build ever fails to bind the instance buffer (Godot's
// known instance-uniform overflow on WebGL2) the body still renders its own albedo.
uniform float accent_strength : hint_range(0.0, 2.0) = 0.0;
instance uniform vec4 instance_accent : source_color = vec4(0.0, 0.0, 0.0, 1.0);

vec3 rotate_hue(vec3 colour, float shift) {
	float angle = shift * 6.28318530718;
	vec3 k = vec3(0.57735);
	float cosine = cos(angle);
	return colour * cosine + cross(k, colour) * sin(angle) + k * dot(k, colour) * (1.0 - cosine);
}

void fragment() {
	vec3 base = texture(albedo_texture, UV).rgb * tint.rgb;
	if (abs(hue_shift) > 0.0001) {
		base = rotate_hue(base, hue_shift);
	}
	// Cool shadow bias keeps the inked look without a second light pass.
	base = mix(base, base * shadow_tint.rgb, shadow_tint_amount);
	ALBEDO = mix(base, flash_colour.rgb, flash_amount);
	ROUGHNESS = 0.86;
	SPECULAR = 0.18;
	METALLIC = 0.0;

	// Directional rim band; constant and cheap. `VIEW`/`NORMAL` are already in view space.
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = rim_colour.rgb * rim * rim_strength
		+ instance_accent.rgb * rim * accent_strength;
}

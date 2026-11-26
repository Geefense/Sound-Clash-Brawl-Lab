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

// PART B commit 5: mipmap + 8× anisotropic sampling, so a 512 px crowd atlas or a 2048 px tower
// albedo stays crisp at grazing angles instead of shimmering as the camera dollies.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float hue_shift : hint_range(-0.5, 0.5) = 0.0;
uniform vec4 rim_colour : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform float rim_strength : hint_range(0.0, 2.5) = 0.55;
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform vec4 shadow_tint : source_color = vec4(0.30, 0.36, 0.58, 1.0);
uniform float shadow_tint_amount : hint_range(0.0, 1.0) = 0.20;
// PART B commit 5 — texture readability. The delivered albedo used to be multiplied straight by
// the light, so the Night rig's dark band crushed a jacket into flat black. The floor splits the
// material: ALBEDO keeps only (1 − albedo_floor) of the lit response and the rest is added
// unlit, so no surface — shadow band, back of a thigh, a crowd body behind the barrier — ever
// draws below 55 % of its own texture value while the bands still read.
uniform float albedo_floor : hint_range(0.0, 0.9) = 0.55;
// The toon band is the engine's: Godot 4.5's `DIFFUSE_TOON` BRDF is
// `smoothstep(-roughness, max(roughness, 0.01), NdotL)`, so ROUGHNESS *is* the band width and the
// transition is a smoothstep, not a hard edge. Exposed here instead of leaving a magic 0.86 in
// the fragment.
uniform float band_softness : hint_range(0.0, 1.0) = 0.86;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_colour : source_color = vec4(1.0, 0.93, 0.72, 1.0);
// Per-instance palette accent (Bug 4c, 2026-11-25). One shared material can dress twenty-two
// different crowd rigs because each GeometryInstance3D carries its own accent colour here.
// It is ADDED to the rim band only, never multiplied into ALBEDO: the delivered texture keeps
// its full brightness, and if a Web build ever fails to bind the instance buffer (Godot's
// known instance-uniform overflow on WebGL2) the body still renders its own albedo.
uniform float accent_strength : hint_range(0.0, 2.0) = 0.0;
instance uniform vec4 instance_accent : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// PART B commit 7 — the crowd's dancehall palette, worn without muddying the delivered
// character. The old multiplicative per-instance tint darkened and desaturated whatever it
// touched. This is a LUMINANCE-PRESERVING mix instead: the palette colour is rescaled to the
// texel's own luma before the mix, so mixing cannot change how bright the body is, only its
// hue. Strength is capped at 0.25 (the crowd ships 0.22) and the fighters leave it at 0.
uniform float crowd_tint_strength : hint_range(0.0, 0.3) = 0.0;
instance uniform vec4 instance_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

const vec3 LUMA_WEIGHTS = vec3(0.2126, 0.7152, 0.0722);

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
	// Cool shadow bias keeps the inked look without a second light pass. The delivered
	// character and crowd materials leave it at 0.0: the floor below is the shadow treatment.
	base = mix(base, base * shadow_tint.rgb, shadow_tint_amount);
	if (crowd_tint_strength > 0.0) {
		// Palette at the texel's own luma: the mix keeps detail and brightness, only the hue
		// moves toward the dancer's colour.
		float luma = dot(base, LUMA_WEIGHTS);
		float tint_luma = max(dot(instance_tint.rgb, LUMA_WEIGHTS), 0.001);
		vec3 palette = instance_tint.rgb * (luma / tint_luma);
		base = mix(base, palette, crowd_tint_strength);
	}
	vec3 face = mix(base, flash_colour.rgb, flash_amount);
	// Lit share of the material, then the unlit floor. The two always sum to `face`, so a fully
	// shadowed surface renders at exactly albedo_floor of the texture and a lit one never loses
	// brightness — the cel bands stay, the crush does not.
	ALBEDO = face * (1.0 - albedo_floor);
	ROUGHNESS = band_softness;
	SPECULAR = 0.18;
	METALLIC = 0.0;

	// Directional rim band; constant and cheap. `VIEW`/`NORMAL` are already in view space.
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = face * albedo_floor
		+ rim_colour.rgb * rim * rim_strength
		+ instance_accent.rgb * rim * accent_strength;
}

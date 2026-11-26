shader_type spatial;
// Sound Clash Brawl — double-sided cel material for delivered scenery props.
//
// Same family and same look as `toon_cel.gdshader`: built-in `diffuse_toon` banding, a cool
// shadow bias and the same additive view-space rim, one forward pass, no screen reads, no
// includes, no loops. The only difference is the culling mode.
//
// The delivered `jamaican_speaker.glb` is an open shell — 2 626 of its 5 240 edges are
// boundary edges and its glTF material is `doubleSided: true` — so its back faces are part of
// the model. Rendering it with the fighters' `cull_back` material would punch holes through
// the painted flag wall. `cull_disabled` keeps the culling the export arrived with, exactly as
// the placement brief requires: never override imported culling without verifying the mesh is
// closed, and this one is not.
//
// No `instance uniform`: a prop is one instance with one material, so there is no palette
// accent to carry.
render_mode diffuse_toon, specular_toon, depth_draw_opaque, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_colour : source_color = vec4(1.0, 0.88, 0.62, 1.0);
uniform float rim_strength : hint_range(0.0, 2.5) = 0.55;
uniform float rim_power : hint_range(1.0, 8.0) = 3.0;
uniform vec4 shadow_tint : source_color = vec4(0.30, 0.36, 0.58, 1.0);
uniform float shadow_tint_amount : hint_range(0.0, 1.0) = 0.20;
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_colour : source_color = vec4(1.0, 0.93, 0.72, 1.0);

void fragment() {
	// The delivered albedo, at full brightness. Nothing here repaints or recolours it.
	vec3 base = texture(albedo_texture, UV).rgb * tint.rgb;
	// Cool shadow bias: the same inked band the fighters and crowd wear.
	base = mix(base, base * shadow_tint.rgb, shadow_tint_amount);
	ALBEDO = mix(base, flash_colour.rgb, flash_amount);
	ROUGHNESS = 0.88;
	SPECULAR = 0.14;
	METALLIC = 0.0;

	// Directional rim band, identical to `toon_cel.gdshader`. Additive light only, so the
	// tower keeps an edge in the night rig without a new light or a raised ambient.
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), rim_power);
	EMISSION = rim_colour.rgb * rim * rim_strength;
}

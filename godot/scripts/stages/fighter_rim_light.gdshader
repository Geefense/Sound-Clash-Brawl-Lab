shader_type canvas_item;
render_mode unshaded;

// 2.5D fighter rim light (AGENTS.md §9 item 41, 2026-11-20).
//
// Wraps a directional rim along the sprite's own alpha edge so the flat cut-out reads as a
// body standing in the stage's light. Everything here is a single CanvasItem pass with nine
// texture taps and no screen/depth reads: it is WebGL2 (GL Compatibility) safe and costs the
// same on an Intel Chromebook UHD as a normal sprite draw.
//
// The rim is painted *inside* the silhouette (a CanvasItem cannot draw outside its quad), so
// it reads as the lit edge of a solid body rather than an outer halo. `light_uv` is the
// direction *toward* the light in texture UV space; `sprite_facing` flips the gradient back
// when AnimatedSprite2D mirrors the frame for a facing turn.

// Rim palette. Two colours blend across the silhouette, so Night can run cyan on one side
// and magenta on the other in a single pass.
uniform vec4 rim_colour : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform vec4 rim_colour_b : source_color = vec4(1.0, 0.74, 0.42, 1.0);
uniform float rim_strength : hint_range(0.0, 2.0) = 0.55;
// Probe distance in texels. The frames are 512–1536 px wide and render at ~0.31 scale, so a
// 1–2 texel probe would be sub-pixel on screen; 7 texels is about 2 screen px.
uniform float rim_width : hint_range(0.5, 16.0) = 7.0;

// Direction toward the light, in texture UV space (y is down).
uniform vec2 light_uv = vec2(0.86, -0.42);
// +1 when the frame draws unmirrored, −1 when AnimatedSprite2D has flip_h on.
uniform float sprite_facing = 1.0;

// Sand bounce: the warm light the yard throws back up onto the lower legs and Clarks.
uniform vec4 bounce_colour : source_color = vec4(1.0, 0.80, 0.50, 1.0);
uniform float bounce_strength : hint_range(0.0, 1.0) = 0.30;
uniform float bounce_top : hint_range(0.0, 1.0) = 0.72;

// Impact flash uniform (hit_flash): the white/gold contact flash, driven by BaseFighter.
uniform vec4 flash_colour : source_color = vec4(1.0, 0.96, 0.78, 1.0);
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a < 0.004) {
		// Fully transparent: never shade empty frame padding.
		discard;
	}

	vec2 px = TEXTURE_PIXEL_SIZE * rim_width;
	float a_l = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float a_r = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float a_u = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float a_d = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	float a_tl = texture(TEXTURE, UV + vec2(-px.x, -px.y)).a;
	float a_tr = texture(TEXTURE, UV + vec2(px.x, -px.y)).a;
	float a_bl = texture(TEXTURE, UV + vec2(-px.x, px.y)).a;
	float a_br = texture(TEXTURE, UV + vec2(px.x, px.y)).a;

	// Alpha gradient points inward from the silhouette edge; the cardinals and diagonals are
	// averaged so the rim follows curves instead of only the four axis-aligned edges.
	vec2 grad = vec2(a_r - a_l, a_d - a_u) * 0.5;
	grad += vec2((a_tr + a_br) - (a_tl + a_bl), (a_bl + a_br) - (a_tl + a_tr)) * 0.25;
	grad.x *= sprite_facing;

	float edge = clamp(length(grad) * 1.6, 0.0, 1.0);
	// Outward normal: the inward gradient reversed.
	vec2 n = normalize(grad + vec2(0.000001, 0.000001));
	vec2 l = normalize(light_uv + vec2(0.000001, 0.000001));
	float lit = smoothstep(0.10, 0.85, clamp(dot(-n, l), 0.0, 1.0));
	float rim = lit * edge * rim_strength;

	vec3 rim_rgb = mix(rim_colour.rgb, rim_colour_b.rgb, smoothstep(0.10, 0.90, UV.x));
	vec3 rgb = tex.rgb + rim_rgb * rim;

	// Warm yard bounce on the lower body, strongest at the soles.
	float band = smoothstep(bounce_top, 1.0, UV.y);
	rgb = mix(rgb, bounce_colour.rgb * (0.55 + tex.rgb * 0.75), band * bounce_strength);

	// Impact frame: white/gold, strongest right at the contact silhouette edge.
	rgb = mix(rgb, flash_colour.rgb, clamp(hit_flash, 0.0, 1.0) * (0.68 + 0.32 * edge));

	COLOR = vec4(rgb, tex.a) * COLOR;
}

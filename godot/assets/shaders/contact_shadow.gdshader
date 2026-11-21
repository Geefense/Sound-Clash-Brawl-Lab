shader_type spatial;
// Grounded contact shadow for the 3D fighting plane: a soft radial blob that follows each
// fighter's feet, shrinks and fades as the body rises. Cheaper and steadier than a real
// shadow map on Intel Chromebook GPUs, and it never catches the fighter's own limbs.
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 shadow_colour : source_color = vec4(0.05, 0.04, 0.07, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.55;
uniform float softness : hint_range(0.2, 1.0) = 0.65;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = 1.0 - smoothstep(1.0 - softness, 1.0, d);
	ALBEDO = shadow_colour.rgb;
	ALPHA = a * opacity;
}

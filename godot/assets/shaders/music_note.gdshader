shader_type spatial;
// Unshaded additive glyph material for the 3D music-note bursts and bass shockwave rings.
// Geometry is generated in code (eighth note, sixteenth note, treble clef, ring), so no
// texture atlas, font glyph coverage or MSDF dependency is needed on the Web build.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 glyph_colour : source_color = vec4(0.35, 0.95, 0.45, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	ALBEDO = glyph_colour.rgb * opacity;
	ALPHA = opacity;
}

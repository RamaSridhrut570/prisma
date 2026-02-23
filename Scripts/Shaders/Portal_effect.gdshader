shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled;

// ── Colour ────────────────────────────────────────────────────────────────────
uniform vec4  portal_color   : source_color = vec4(1.0, 0.6, 0.2, 1.0);

// Overall brightness multiplier (drive via set_shader_parameter for stage transitions)
uniform float energy         : hint_range(0.0, 3.0) = 1.0;
// ── Motion ────────────────────────────────────────────────────────────────────
uniform float spin_speed     : hint_range(0.0, 8.0)  = 1.8;
uniform float pulse_speed    : hint_range(0.0, 6.0)  = 2.0;

// ── Appearance ────────────────────────────────────────────────────────────────
uniform float glow_intensity  : hint_range(0.0, 5.0)  = 2.0;
uniform float swirl_strength  : hint_range(0.0, 8.0)  = 3.5;
uniform float chromatic_shift : hint_range(0.0, 0.15) = 0.04;
uniform float core_size       : hint_range(0.0, 0.5)  = 0.18;
uniform float rim_width       : hint_range(0.0, 1.0)  = 0.12;
uniform float arc_count       : hint_range(1.0, 12.0) = 6.0;

// ── Simple hash / value-noise helpers ────────────────────────────────────────
float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f); // smoothstep
	return mix(
		mix(hash(i),            hash(i + vec2(1,0)), f.x),
		mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
		f.y
	);
}

// ── Turbulence (3 octaves) ────────────────────────────────────────────────────
float turbulence(vec2 p) {
	return vnoise(p)      * 0.55
	     + vnoise(p * 2.1) * 0.28
	     + vnoise(p * 4.3) * 0.17;
}

// ── Per-channel radial sample helper ─────────────────────────────────────────
float radial_sample(vec2 uv_centered, float r, float a) {
	float radial  = 1.0 - smoothstep(0.15, 1.0, r);
	float spiral  = sin(r * 18.0 - a * arc_count + TIME * spin_speed * 2.5) * 0.5 + 0.5;
	float bands   = pow(spiral, 2.5);
	float turb    = turbulence(uv_centered * 3.0 + TIME * 0.18);
	return mix(radial, bands, 0.65) * (0.7 + 0.3 * turb);
}

void fragment() {
	// ── Centred UV ───────────────────────────────────────────────────────────
	vec2 uv = UV * 2.0 - 1.0;

	float radius = length(uv);
	float angle  = atan(uv.y, uv.x);

	// hard-discard outside the disc
	if (radius > 1.02) discard;

	// ── Spinning + swirl distortion ──────────────────────────────────────────
	float spin  = TIME * spin_speed;
	float swirl = sin(radius * 12.0 - spin * 2.0) * swirl_strength * 0.1;
	angle += spin + swirl;

	// turbulence offset on UV for chromatic spread
	vec2 turb_uv = uv + vec2(
		turbulence(uv * 2.5 + vec2(TIME * 0.12, 0.0)),
		turbulence(uv * 2.5 + vec2(0.0, TIME * 0.12))
	) * 0.08;
	float turb_r = length(turb_uv);
	float turb_a = atan(turb_uv.y, turb_uv.x) + spin + swirl;

	// ── Chromatic aberration (R shifted out, B shifted in) ───────────────────
	float cs = chromatic_shift;

	float r_ch = radial_sample(uv * (1.0 + cs), turb_r * (1.0 + cs), turb_a);
	float g_ch = radial_sample(uv,               turb_r,              turb_a);
	float b_ch = radial_sample(uv * (1.0 - cs), turb_r * (1.0 - cs), turb_a);

	// ── Pulse breathing ──────────────────────────────────────────────────────
	float pulse = 0.92 + 0.08 * sin(TIME * pulse_speed);

	// ── Inner core bright spot ───────────────────────────────────────────────
	float core = (1.0 - smoothstep(0.0, core_size, radius)) * 2.8 * pulse;

	// ── Outer rim glow ring ──────────────────────────────────────────────────
	float rim = 1.0 - abs(radius - (1.0 - rim_width * 0.5)) / (rim_width * 0.5);
	rim = clamp(rim, 0.0, 1.0);
	rim = pow(rim, 1.5) * 2.0 * pulse;

	// ── Energy arc bands (rotate with arc count) ─────────────────────────────
	float arc = pow(clamp(sin(angle * arc_count * 0.5 + spin * 1.5) * 0.5 + 0.5, 0.0, 1.0), 3.0);
	arc *= (1.0 - smoothstep(0.6, 1.0, radius)); // fade arcs near edge

	// ── Assemble colour ──────────────────────────────────────────────────────
	vec3 base_col = portal_color.rgb;

	// tint: core goes white-ish, rim is pure portal colour brightened
	vec3 col;
	col.r = base_col.r * r_ch * glow_intensity;
	col.g = base_col.g * g_ch * glow_intensity;
	col.b = base_col.b * b_ch * glow_intensity;

	// add core bloom
	col += mix(base_col, vec3(1.0), 0.7) * core;

	// add rim
	col += base_col * rim;

	// add arcs (slightly desaturated)
	col += mix(base_col, vec3(1.0), 0.4) * arc * 0.6 * pulse;

	// ── Alpha ────────────────────────────────────────────────────────────────
	float base_alpha = (r_ch + g_ch + b_ch) / 3.0 * 0.85 + rim * 0.4 + core * 0.3;
	base_alpha += arc * 0.25;
	float edge_fade  = 1.0 - smoothstep(0.88, 1.02, radius); // soft edge fade
	float alpha = clamp(base_alpha, 0.15, 1.0) * edge_fade;

	ALBEDO = col * energy;
	ALPHA  = alpha * clamp(energy, 0.0, 1.0);
}
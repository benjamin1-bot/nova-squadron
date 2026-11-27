shader_type sky;
uniform vec3 neb1 : source_color = vec3(0.30, 0.10, 0.55);
uniform vec3 neb2 : source_color = vec3(0.05, 0.30, 0.60);
uniform vec3 base : source_color = vec3(0.004, 0.006, 0.018);
uniform float neb_strength = 1.0;
uniform float planet = 0.0;
uniform float hole = 0.0;
uniform vec3 hole_dir = vec3(0.25, 0.18, -1.0);
uniform float bigsun = 0.0;
uniform vec3 zenith : source_color = vec3(0.05, 0.15, 0.35);
uniform vec3 horizon : source_color = vec3(0.6, 0.75, 0.9);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}
void sky() {
	vec3 d = EYEDIR;
	float n = fbm(d * 2.6);
	float n2 = fbm(d * 5.0 + vec3(5.2, 1.3, 7.7));
	float wisps = fbm(d * 11.0 + vec3(n * 2.0));
	vec3 col = base;
	col += neb1 * pow(n, 3.2) * 3.0 * neb_strength * (0.6 + wisps * 0.8);
	col += neb2 * pow(n2, 3.6) * 3.2 * neb_strength;
	float st = step(0.9982, hash(floor(d * 850.0)));
	float st2 = step(0.9995, hash(floor(d * 420.0 + 3.0)));
	col += vec3(st) * 1.2 + vec3(st2) * vec3(2.5, 2.3, 2.0);
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += LIGHT0_COLOR * (pow(sd, 900.0) * 14.0 + pow(sd, 40.0) * 0.35 + pow(sd, 6.0) * 0.06);
	if (hole > 0.5) {
		vec3 hd = normalize(hole_dir);
		float c = dot(d, hd);
		float ang = acos(clamp(c, -1.0, 1.0));
		float r0 = 0.2;
		vec3 up = normalize(vec3(0.2, 1.0, 0.25) - hd * dot(vec3(0.2, 1.0, 0.25), hd));
		float pl = abs(dot(d, up));
		float disk = smoothstep(0.06, 0.0, pl) * smoothstep(r0 * 0.95, r0 * 1.25, ang) * smoothstep(0.9, 0.3, ang);
		float swirl = fbm(vec3(ang * 18.0, dot(d, cross(hd, up)) * 9.0, 1.0));
		float photon = smoothstep(0.025, 0.0, abs(ang - r0 * 1.04));
		float lens = smoothstep(r0 * 2.2, r0, ang) * 0.6;
		col *= 1.0 - lens;
		col += vec3(1.0, 0.45, 0.15) * disk * (0.35 + swirl * 1.1) + vec3(1.0, 0.7, 0.4) * photon * 0.9;
		col *= smoothstep(r0 * 0.96, r0 * 1.0, ang) * 0.999 + 0.001;
	}
	if (bigsun > 0.5) {
		float sa2 = acos(clamp(dot(d, LIGHT0_DIRECTION), -1.0, 1.0));
		float gran = fbm(d * 40.0);
		float disc = smoothstep(0.30, 0.285, sa2);
		float limb = 1.0 - pow(clamp(sa2 / 0.3, 0.0, 1.0), 3.0) * 0.55;
		col = mix(col, vec3(1.25, 0.62, 0.2) * (0.55 + gran * 0.75) * limb, disc);
		col += vec3(1.0, 0.45, 0.1) * (exp(-(sa2 - 0.29) * 7.0) * 0.9) * (1.0 - disc) * (0.7 + fbm(d * 8.0 + vec3(3.0)) * 0.8);
	}
	if (planet > 0.5) {
		float h = clamp(d.y, -1.0, 1.0);
		vec3 g = mix(horizon, zenith, smoothstep(-0.02, 0.55, h));
		float cl = fbm(vec3(d.x / max(h + 0.15, 0.08), 0.0, d.z / max(h + 0.15, 0.08)) * 1.4);
		g = mix(g, horizon * 1.15 + vec3(0.04), smoothstep(0.5, 0.8, cl) * smoothstep(-0.02, 0.15, h) * 0.55);
		g += neb1 * pow(n, 3.0) * 0.6 * neb_strength * smoothstep(0.1, 0.6, h);
		g += LIGHT0_COLOR * (pow(sd, 700.0) * 10.0 + pow(sd, 30.0) * 0.4 + pow(sd, 4.0) * 0.12);
		col = g;
	}
	COLOR = col;
}

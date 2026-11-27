shader_type sky;
uniform vec3 neb1 : source_color = vec3(0.30, 0.10, 0.55);
uniform vec3 neb2 : source_color = vec3(0.05, 0.30, 0.60);
uniform vec3 base : source_color = vec3(0.004, 0.006, 0.018);
uniform float neb_strength = 1.0;

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
	COLOR = col;
}

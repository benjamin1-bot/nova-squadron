extends Node3D
## Prismwing – Godot-4-Version (Etappe 1)
## Bahn-Shooter: Flug entlang einer prozeduralen Bahn, Asteroidengürtel, Tunnel durch Riesen-Asteroiden,
## Gegner, Schüsse, HUD, Touch/Tastatur/Controller und ein automatischer Testpilot (--autotest).

const BX := 15.0
const BY := 10.0
const STEP := 4.0
const BULLET_SPEED := 170.0

var speed := 42.0
var s := 0.0
var t_game := 0.0

# --- Bahn ---
var rail_p := PackedVector3Array()
var rail_f := PackedVector3Array()
var rail_u := PackedVector3Array()

# --- Spieler ---
var ship: Node3D
var ship_x := 0.0
var ship_y := 0.0
var ship_vx := 0.0
var ship_vy := 0.0
var hull := 100.0
var shield := 100.0
var shield_delay := 0.0
var invul := 0.0
var score := 0
var fire_t := 0.0
var cam: Camera3D
var headlight: SpotLight3D

# --- Welt-Objekte (lokale Bahnkoordinaten: s, x, y) ---
var rocks: Array = []        # {node, s, x, y, r, rot}
var enemies: Array = []      # {node, s, x, y, hp, t, ph, fire}
var bullets: Array = []      # {node, s, x, y, vx, vy, life}
var ebullets: Array = []     # {node, s, x, y, vx, vy, vs}
var tunnels: Array = []      # {s0, s1, nodes}
var next_rock_s := 60.0
var next_enemy_s := 220.0
var next_tunnel_s := 520.0

var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()

# --- Materialien / Meshes ---
var outline_mat: ShaderMaterial
var rock_mat: StandardMaterial3D
var tunnel_mat: StandardMaterial3D
var ship_mat: StandardMaterial3D
var ship_dark: StandardMaterial3D
var enemy_mat: StandardMaterial3D
var glow_cyan: StandardMaterial3D
var glow_red: StandardMaterial3D
var glow_orange: StandardMaterial3D
var rock_meshes: Array = []
var bullet_mesh: CapsuleMesh
var ebullet_mesh: SphereMesh

# --- Eingabe ---
var touch_id := -1
var touch_start := Vector2.ZERO
var touch_now := Vector2.ZERO

# --- HUD ---
var hud_score: Label
var hud_hull: ProgressBar
var hud_shield: ProgressBar
var hud_info: Label
var hud_msg: Label
var msg_t := 0.0

# --- Testpilot ---
var autotest := false
var at_dir := ""
var at_shot_t := 0.0
var at_shots := 0
var at_log: Array = []
var at_frames := 0
var at_fps_sum := 0.0

func _ready() -> void:
	rng.seed = 1234
	noise.seed = 77
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.0
	for a in OS.get_cmdline_user_args():
		if a == "--autotest":
			autotest = true
		elif a.begins_with("--out="):
			at_dir = a.substr(6)
	if autotest and at_dir == "":
		at_dir = OS.get_user_data_dir() + "/autotest"
	if autotest:
		DirAccess.make_dir_recursive_absolute(at_dir)
		log_at("Autotest gestartet. Renderer: " + str(ProjectSettings.get_setting("rendering/renderer/rendering_method")))
	_extend_rail(800.0)
	_make_materials()
	_make_environment()
	_make_ship()
	_make_hud()
	if autotest:
		next_tunnel_s = 260.0
	show_msg("ASTEROIDENGÜRTEL KEPLER", 3.0)

# ======================= Bahn =======================
func _extend_rail(to_s: float) -> void:
	while float(rail_p.size()) * STEP < to_s + 60.0:
		var n := rail_p.size()
		var t := float(n) * STEP
		var yaw := sin(t * 0.0021) * 0.9 + sin(t * 0.0007 + 1.3) * 0.6
		var pitch := sin(t * 0.0013) * 0.10 + sin(t * 0.0031 + 2.0) * 0.05
		var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)).normalized()
		var p := Vector3.ZERO if n == 0 else rail_p[n - 1] + dir * STEP
		var r := dir.cross(Vector3.UP).normalized()
		var u := r.cross(dir).normalized()
		rail_p.append(p)
		rail_f.append(dir)
		rail_u.append(u)

func frame(sv: float) -> Transform3D:
	_extend_rail(sv)
	var f := maxf(sv, 0.0) / STEP
	var i := int(floor(f))
	i = clampi(i, 0, rail_p.size() - 2)
	var t := clampf(f - float(i), 0.0, 1.0)
	var p := rail_p[i].lerp(rail_p[i + 1], t)
	var fw := rail_f[i].lerp(rail_f[i + 1], t).normalized()
	var up := rail_u[i].lerp(rail_u[i + 1], t).normalized()
	var r := fw.cross(up).normalized()
	up = r.cross(fw).normalized()
	return Transform3D(Basis(r, up, -fw), p)

func l2w(sv: float, x: float, y: float) -> Vector3:
	var tr := frame(sv)
	return tr.origin + tr.basis.x * x + tr.basis.y * y

func place(n: Node3D, sv: float, x: float, y: float) -> void:
	var tr := frame(sv)
	tr.origin += tr.basis.x * x + tr.basis.y * y
	n.global_transform = tr

# ======================= Materialien =======================
func _toon(col: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.6
	m.next_pass = outline_mat
	return m

func _glow(col: Color, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m

func _make_materials() -> void:
	outline_mat = ShaderMaterial.new()
	outline_mat.shader = load("res://outline.gdshader")
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.as_normal_map = true
	nt.bump_strength = 6.0
	var fn := FastNoiseLite.new()
	fn.frequency = 0.03
	fn.fractal_octaves = 5
	nt.noise = fn
	var ct := NoiseTexture2D.new()
	ct.width = 256
	ct.height = 256
	ct.seamless = true
	var fn2 := FastNoiseLite.new()
	fn2.frequency = 0.012
	fn2.fractal_octaves = 4
	ct.noise = fn2
	var grad := Gradient.new()
	grad.set_color(0, Color(0.55, 0.5, 0.45))
	grad.set_color(1, Color(1.0, 0.97, 0.92))
	ct.color_ramp = grad
	rock_mat = _toon(Color(0.62, 0.56, 0.5), 0.92)
	rock_mat.vertex_color_use_as_albedo = true
	rock_mat.albedo_texture = ct
	rock_mat.normal_enabled = true
	rock_mat.normal_texture = nt
	rock_mat.normal_scale = 1.4
	rock_mat.uv1_triplanar = true
	rock_mat.uv1_scale = Vector3(0.12, 0.12, 0.12)
	tunnel_mat = rock_mat.duplicate() as StandardMaterial3D
	tunnel_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tunnel_mat.next_pass = null
	ship_mat = _toon(Color(0.86, 0.88, 0.92), 0.35, 0.6)
	ship_dark = _toon(Color(0.12, 0.13, 0.16), 0.5, 0.5)
	enemy_mat = _toon(Color(0.55, 0.12, 0.14), 0.4, 0.5)
	glow_cyan = _glow(Color(0.3, 0.9, 1.0), 4.0)
	glow_red = _glow(Color(1.0, 0.2, 0.25), 4.0)
	glow_orange = _glow(Color(1.0, 0.55, 0.15), 4.0)
	for i in 8:
		rock_meshes.append(_cut_rock(i * 31 + 7, 2))
	bullet_mesh = CapsuleMesh.new()
	bullet_mesh.radius = 0.14
	bullet_mesh.height = 2.2
	ebullet_mesh = SphereMesh.new()
	ebullet_mesh.radius = 0.38
	ebullet_mesh.height = 0.76

## Fels aus ebenen Bruchflächen (kantig, nicht oval) mit Vertex-Farbvariation
func _cut_rock(seed_v: int, detail: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var sm := SphereMesh.new()
	sm.radial_segments = 10 + detail * 4
	sm.rings = 6 + detail * 3
	var arr := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var sc := Vector3(r.randf_range(0.75, 1.5), r.randf_range(0.5, 1.05), r.randf_range(0.75, 1.4))
	for i in verts.size():
		verts[i] = verts[i] * 2.0 * sc
	var cuts := 9 + r.randi() % 7
	for c in cuts:
		var n := Vector3(r.randf() - 0.5, (r.randf() - 0.5) * 1.2, r.randf() - 0.5).normalized()
		var mx := -1e9
		for v in verts:
			mx = maxf(mx, v.dot(n))
		var d := mx * r.randf_range(0.55, 0.9)
		for i in verts.size():
			var k := verts[i].dot(n) - d
			if k > 0.0:
				verts[i] = verts[i] - n * k
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, idx.size(), 3):
		for j in 3:
			var v := verts[idx[i + j]]
			var nv := noise.get_noise_3d(v.x * 1.7 + seed_v, v.y * 1.7, v.z * 1.7)
			var g := 0.78 + nv * 0.22
			st.set_color(Color(g, g * 0.97, g * 0.93))
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()

# ======================= Umgebung =======================
func _make_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 40, 0)
	sun.light_color = Color(1.0, 0.94, 0.86)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 220.0
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30, -140, 0)
	fill.light_color = Color(0.45, 0.55, 1.0)
	fill.light_energy = 0.35
	add_child(fill)
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://space_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.1, 0.22)
	env.fog_density = 0.0028
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	cam = Camera3D.new()
	cam.fov = 70.0
	cam.near = 0.3
	cam.far = 3000.0
	add_child(cam)
	cam.current = true

# ======================= Schiff =======================
func _mi(mesh: Mesh, mat: Material, pos: Vector3, scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.scale = scl
	m.rotation = rot
	return m

func _make_ship() -> void:
	ship = Node3D.new()
	add_child(ship)
	var body := CapsuleMesh.new()
	body.radius = 0.55
	body.height = 4.2
	ship.add_child(_mi(body, ship_mat, Vector3(0, 0, 0), Vector3(1, 0.7, 1), Vector3(PI / 2, 0, 0)))
	var cockpit := SphereMesh.new()
	cockpit.radius = 0.42
	cockpit.height = 0.84
	ship.add_child(_mi(cockpit, ship_dark, Vector3(0, 0.38, -0.6), Vector3(1, 0.7, 1.6)))
	var wing := PrismMesh.new()
	wing.size = Vector3(2.4, 2.0, 0.14)
	for sx in [-1.0, 1.0]:
		ship.add_child(_mi(wing, ship_mat, Vector3(sx * 1.35, -0.08, 0.5), Vector3(1, 1, 1), Vector3(PI / 2, 0, -sx * PI / 2)))
		var eng := CylinderMesh.new()
		eng.top_radius = 0.28
		eng.bottom_radius = 0.34
		eng.height = 1.6
		ship.add_child(_mi(eng, ship_dark, Vector3(sx * 0.95, -0.05, 1.3), Vector3.ONE, Vector3(PI / 2, 0, 0)))
		var fl := SphereMesh.new()
		fl.radius = 0.24
		fl.height = 0.48
		ship.add_child(_mi(fl, glow_cyan, Vector3(sx * 0.95, -0.05, 2.15), Vector3(1, 1, 1.6)))
		var tip := BoxMesh.new()
		tip.size = Vector3(0.12, 0.12, 0.5)
		ship.add_child(_mi(tip, glow_red if sx < 0 else glow_cyan, Vector3(sx * 2.45, -0.08, 0.9)))
	var fin := PrismMesh.new()
	fin.size = Vector3(1.2, 1.0, 0.1)
	ship.add_child(_mi(fin, ship_mat, Vector3(0, 0.55, 1.1), Vector3.ONE, Vector3(0, PI / 2, 0)))
	headlight = SpotLight3D.new()
	headlight.spot_range = 70.0
	headlight.spot_angle = 28.0
	headlight.light_energy = 0.0
	headlight.light_color = Color(0.85, 0.92, 1.0)
	ship.add_child(headlight)
	headlight.position = Vector3(0, 0, -2)

# ======================= HUD =======================
func _make_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	hud_score = Label.new()
	hud_score.add_theme_font_size_override("font_size", 30)
	hud_score.position = Vector2(560, 14)
	cl.add_child(hud_score)
	hud_hull = ProgressBar.new()
	hud_hull.position = Vector2(20, 18)
	hud_hull.size = Vector2(260, 18)
	hud_hull.show_percentage = false
	hud_hull.modulate = Color(0.4, 1.0, 0.5)
	cl.add_child(hud_hull)
	hud_shield = ProgressBar.new()
	hud_shield.position = Vector2(20, 40)
	hud_shield.size = Vector2(260, 10)
	hud_shield.show_percentage = false
	hud_shield.modulate = Color(0.4, 0.8, 1.0)
	cl.add_child(hud_shield)
	hud_info = Label.new()
	hud_info.position = Vector2(20, 60)
	hud_info.add_theme_font_size_override("font_size", 14)
	hud_info.modulate = Color(1, 1, 1, 0.6)
	cl.add_child(hud_info)
	hud_msg = Label.new()
	hud_msg.add_theme_font_size_override("font_size", 34)
	hud_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_msg.position = Vector2(0, 220)
	hud_msg.size = Vector2(1280, 60)
	cl.add_child(hud_msg)

func show_msg(t: String, dur := 2.5) -> void:
	hud_msg.text = t
	msg_t = dur

# ======================= Eingabe =======================
func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		var vw := get_viewport().get_visible_rect().size.x
		if ev.pressed and ev.position.x < vw * 0.6 and touch_id == -1:
			touch_id = ev.index
			touch_start = ev.position
			touch_now = ev.position
		elif not ev.pressed and ev.index == touch_id:
			touch_id = -1
	elif ev is InputEventScreenDrag and ev.index == touch_id:
		touch_now = ev.position

func _input_vec() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y += 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y -= 1
	var jx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var jy := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if absf(jx) > 0.22: v.x += jx
	if absf(jy) > 0.22: v.y -= jy
	if touch_id != -1:
		var d := (touch_now - touch_start) / 90.0
		v += Vector2(clampf(d.x, -1, 1), clampf(-d.y, -1, 1))
	return v.limit_length(1.0)

# ======================= Spiel-Schleife =======================
func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 20.0)
	if autotest:
		dt = 1.0 / 20.0
	t_game += dt
	s += speed * dt
	_extend_rail(s + 700.0)
	_update_ship(dt)
	_spawn_world()
	_update_rocks(dt)
	_update_enemies(dt)
	_update_bullets(dt)
	_update_tunnels()
	_update_camera(dt)
	_update_hud(dt)
	if autotest:
		_autotest_step(dt)

func _in_tunnel(sv: float) -> Dictionary:
	for t in tunnels:
		if sv >= t.s0 - 2.0 and sv <= t.s1 + 2.0:
			return t
	return {}

func _update_ship(dt: float) -> void:
	var v := _input_vec()
	if autotest:
		var ty := sin(t_game * 0.7) * BY * 0.5
		var tx := sin(t_game * 0.45) * BX * 0.55
		var tn := _in_tunnel(s)
		if not tn.is_empty():
			tx *= 0.3
			ty *= 0.3
		v = Vector2(clampf((tx - ship_x) * 0.3, -1, 1), clampf((ty - ship_y) * 0.3, -1, 1))
	ship_vx = lerpf(ship_vx, v.x * 26.0, minf(1.0, dt * 7.0))
	ship_vy = lerpf(ship_vy, v.y * 20.0, minf(1.0, dt * 7.0))
	ship_x = clampf(ship_x + ship_vx * dt, -BX, BX)
	ship_y = clampf(ship_y + ship_vy * dt, -BY, BY)
	# Tunnelwand: im Tunnel innerhalb der Ellipse bleiben
	var tn2 := _in_tunnel(s)
	if not tn2.is_empty():
		var ex := (BX + 7.0) * 0.8
		var ey := (BY + 6.0) * 0.8
		var q := pow(ship_x / ex, 2) + pow(ship_y / ey, 2)
		if q > 1.0:
			var k := 1.0 / sqrt(q)
			ship_x *= k
			ship_y *= k
	place(ship, s, ship_x, ship_y)
	ship.rotate_object_local(Vector3.FORWARD, -ship_vx * 0.022)
	ship.rotate_object_local(Vector3.RIGHT, ship_vy * 0.012)
	invul = maxf(0.0, invul - dt)
	shield_delay -= dt
	if shield_delay <= 0.0:
		shield = minf(100.0, shield + 17.0 * dt)
	headlight.light_energy = lerpf(headlight.light_energy, 2.2 if not _in_tunnel(s + 20).is_empty() else 0.0, minf(1.0, dt * 3.0))
	fire_t -= dt
	if fire_t <= 0.0:
		fire_t = 0.11
		_fire()

func damage(d: float) -> void:
	if invul > 0.0 or autotest:
		return
	shield_delay = 3.0
	invul = 0.4
	var a := minf(shield, d)
	shield -= a
	hull -= (d - a)
	if hull <= 0.0:
		hull = 100.0
		shield = 100.0
		score = 0
		show_msg("SCHIFF ZERSTÖRT – NEUSTART", 2.5)

func _fire() -> void:
	# Ziel: nächster Gegner vor dem Schiff (Auto-Zielen light)
	var tx := ship_x
	var ty := ship_y
	var best := 1e9
	for e in enemies:
		var ds: float = e.s - s
		if ds > 8.0 and ds < 160.0:
			var dd := Vector2(e.x - ship_x, e.y - ship_y).length() + ds * 0.05
			if dd < best and Vector2(e.x - ship_x, e.y - ship_y).length() < 9.0 + ds * 0.06:
				best = dd
				tx = e.x
				ty = e.y
	for sx in [-0.95, 0.95]:
		var n := MeshInstance3D.new()
		n.mesh = bullet_mesh
		n.material_override = glow_cyan
		add_child(n)
		var bx: float = ship_x + sx
		var tt := 0.6
		bullets.append({"node": n, "s": s - 1.0, "x": bx, "y": ship_y, "vx": (tx - bx) / tt * 0.35, "vy": (ty - ship_y) / tt * 0.35, "life": 1.0})

# ======================= Welt erzeugen =======================
func _spawn_world() -> void:
	while next_rock_s < s + 520.0:
		var sv := next_rock_s
		next_rock_s += rng.randf_range(3.0, 7.0)
		if not _in_tunnel(sv).is_empty():
			continue
		var inside := rng.randf() < 0.12
		var x := 0.0
		var y := 0.0
		var r := 0.0
		if inside:
			x = rng.randf_range(-BX, BX)
			y = rng.randf_range(-BY, BY)
			r = rng.randf_range(1.6, 3.2)
		else:
			var a := rng.randf() * TAU
			var dist := rng.randf_range(BX + 8.0, 160.0)
			x = cos(a) * dist
			y = sin(a) * dist * 0.75
			r = rng.randf_range(2.0, 9.0) if dist < 60.0 else rng.randf_range(4.0, 22.0)
		_add_rock(sv, x, y, r, inside)
	while next_enemy_s < s + 260.0:
		var sv2 := next_enemy_s
		next_enemy_s += rng.randf_range(28.0, 55.0)
		if not _in_tunnel(sv2).is_empty():
			continue
		var n := 1 + rng.randi() % 3
		for i in n:
			_add_enemy(sv2 + i * 6.0)
	if next_tunnel_s < s + 600.0:
		var tl := rng.randf_range(220.0, 320.0)
		_add_tunnel(next_tunnel_s, tl)
		next_tunnel_s += tl + rng.randf_range(900.0, 1400.0)

func _near_tunnel(sv: float, m: float) -> bool:
	for t in tunnels:
		if sv > t.s0 - m and sv < t.s1 + m:
			return true
	return false

func _add_rock(sv: float, x: float, y: float, r: float, hard: bool) -> void:
	var m := MeshInstance3D.new()
	m.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
	m.material_override = rock_mat
	add_child(m)
	place(m, sv, x, y)
	m.rotate_object_local(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized(), rng.randf() * TAU)
	m.scale = Vector3.ONE * r * 0.5
	rocks.append({"node": m, "s": sv, "x": x, "y": y, "r": r, "hard": hard, "spin": Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4), 0)})

func _add_enemy(sv: float) -> void:
	var g := Node3D.new()
	var body := PrismMesh.new()
	body.size = Vector3(2.2, 3.0, 0.6)
	g.add_child(_mi(body, enemy_mat, Vector3.ZERO, Vector3.ONE, Vector3(-PI / 2, 0, 0)))
	var eye := SphereMesh.new()
	eye.radius = 0.35
	eye.height = 0.7
	g.add_child(_mi(eye, glow_red, Vector3(0, 0.25, 0.4)))
	var wing := BoxMesh.new()
	wing.size = Vector3(4.2, 0.12, 1.0)
	g.add_child(_mi(wing, ship_dark, Vector3(0, 0, 0.6)))
	add_child(g)
	enemies.append({"node": g, "s": sv, "x": rng.randf_range(-BX, BX), "y": rng.randf_range(-BY * 0.8, BY * 0.8), "hp": 3.0, "t": 0.0, "ph": rng.randf() * TAU, "fire": rng.randf_range(1.0, 2.5)})

# ======================= Tunnel durch Riesen-Asteroid (ein durchgehendes Netz) =======================
func tunnel_r(a: float, sv: float) -> float:
	var ca := cos(a)
	var sa := sin(a)
	var r := 1.0 + noise.get_noise_3d(ca * 1.6 + 5.0, sa * 1.6, sv * 0.035) * 0.33 + noise.get_noise_3d(ca * 5.0, sa * 5.0 + 3.0, sv * 0.12) * 0.18 + noise.get_noise_3d(ca * 10.0, sa * 10.0, sv * 0.3) * 0.07
	return maxf(0.86, r)

func _inner(a: float, sv: float) -> Vector2:
	var rr := tunnel_r(a, sv)
	return Vector2(cos(a) * (BX + 7.0) * rr, sin(a) * (BY + 6.0) * rr)

func _outer(a: float, sv: float, s0: float, s1: float, r0: float, sd: float) -> Vector2:
	var ca := cos(a)
	var sa := sin(a)
	var e := clampf(minf(sv - s0, s1 - sv) / 40.0, 0.0, 1.0)
	var tap := 0.5 + 0.5 * sin(e * PI / 2.0)
	var mid := 0.85 + 0.15 * sin(clampf((sv - s0) / (s1 - s0), 0.0, 1.0) * PI)
	var R := r0 * tap * mid * (1.0 + noise.get_noise_3d(ca * 2.0 + sd, sa * 2.0, sv * 0.02) * 0.3 + noise.get_noise_3d(ca * 6.0, sa * 6.0 + sd, sv * 0.06) * 0.08)
	return Vector2(ca * R, sa * R * 0.85)

func _col_in(a: float, sv: float) -> Color:
	var n := noise.get_noise_3d(cos(a) * 7.0, sin(a) * 7.0, sv * 0.2) * 0.5 + 0.5
	var c := Color(0.42, 0.34, 0.26).lerp(Color(0.2, 0.16, 0.12), n)
	return c

func _col_out(a: float, sv: float) -> Color:
	var n := noise.get_noise_3d(cos(a) * 3.0, sin(a) * 3.0, sv * 0.04) * 0.5 + 0.5
	return Color(0.5, 0.44, 0.36).lerp(Color(0.32, 0.27, 0.22), n)

func _add_tunnel(s0: float, tl: float) -> void:
	var s1 := s0 + tl
	var SEG := 40
	var STEPT := 2.6
	var nr := int(round(tl / STEPT))
	var r0 := rng.randf_range(58.0, 78.0)
	var sd := rng.randf() * 50.0
	var nodes: Array = []
	var ring_s := func(r: int) -> float: return s0 + tl * float(r) / float(nr)
	# Innenwand + Außenhülle in Stücken
	var r_start := 0
	while r_start < nr:
		var r_end := mini(nr, r_start + 22)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for r in range(r_start, r_end):
			var sa: float = ring_s.call(r)
			var sb: float = ring_s.call(r + 1)
			var fa := frame(sa)
			var fb := frame(sb)
			for k in SEG:
				var a1 := float(k) / SEG * TAU
				var a2 := float(k + 1) / SEG * TAU
				# innen
				var i1 := _inner(a1, sa); var i2 := _inner(a2, sa); var i3 := _inner(a1, sb); var i4 := _inner(a2, sb)
				_quad(st, fa, fb, i1, i2, i3, i4, _col_in(a1, sa), _col_in(a2, sa), _col_in(a1, sb), _col_in(a2, sb), false)
				# außen
				var o1 := _outer(a1, sa, s0, s1, r0, sd); var o2 := _outer(a2, sa, s0, s1, r0, sd); var o3 := _outer(a1, sb, s0, s1, r0, sd); var o4 := _outer(a2, sb, s0, s1, r0, sd)
				_quad(st, fa, fb, o1, o2, o3, o4, _col_out(a1, sa), _col_out(a2, sa), _col_out(a1, sb), _col_out(a2, sb), true)
		nodes.append(_commit(st))
		r_start = r_end
	# Mündungen: Lippe vom Innenrand zur Außenkante (exakt gleiche Randpunkte)
	for end in [[s0, 1.0], [s1, -1.0]]:
		var se: float = end[0]
		var dir: float = end[1]
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		var NL := 7
		for l in NL:
			var t0 := float(l) / NL
			var t1 := float(l + 1) / NL
			for k in SEG:
				var a1 := float(k) / SEG * TAU
				var a2 := float(k + 1) / SEG * TAU
				var p := [_lip(a1, se, t0, dir, s0, s1, r0, sd), _lip(a2, se, t0, dir, s0, s1, r0, sd), _lip(a1, se, t1, dir, s0, s1, r0, sd), _lip(a2, se, t1, dir, s0, s1, r0, sd)]
				var cs := [_col_in(a1, se).lerp(_col_out(a1, se), minf(1.0, t0 * 1.6)), _col_in(a2, se).lerp(_col_out(a2, se), minf(1.0, t0 * 1.6)), _col_in(a1, se).lerp(_col_out(a1, se), minf(1.0, t1 * 1.6)), _col_in(a2, se).lerp(_col_out(a2, se), minf(1.0, t1 * 1.6))]
				for tri in [[0, 2, 1], [1, 2, 3]]:
					for j in tri:
						st2.set_color(cs[j])
						st2.add_vertex(p[j])
		nodes.append(_commit(st2))
	tunnels.append({"s0": s0, "s1": s1, "nodes": nodes, "told": false})

func _lip(a: float, se: float, t: float, dir: float, s0: float, s1: float, r0: float, sd: float) -> Vector3:
	var i := _inner(a, se)
	var o := _outer(a, se, s0, s1, r0, sd)
	var xy := i.lerp(o, t)
	var bump := sin(t * PI) * (noise.get_noise_3d(cos(a) * 3.0, sin(a) * 3.0, t * 3.0) * 0.5 + 0.5) * 4.0
	var fr := frame(se + dir * bump)
	return fr.origin + fr.basis.x * xy.x + fr.basis.y * xy.y

func _quad(st: SurfaceTool, fa: Transform3D, fb: Transform3D, p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, c1: Color, c2: Color, c3: Color, c4: Color, flip: bool) -> void:
	var v1 := fa.origin + fa.basis.x * p1.x + fa.basis.y * p1.y
	var v2 := fa.origin + fa.basis.x * p2.x + fa.basis.y * p2.y
	var v3 := fb.origin + fb.basis.x * p3.x + fb.basis.y * p3.y
	var v4 := fb.origin + fb.basis.x * p4.x + fb.basis.y * p4.y
	var tris := [[v1, v3, v2, c1, c3, c2], [v2, v3, v4, c2, c3, c4]]
	for t in tris:
		if flip:
			st.set_color(t[3]); st.add_vertex(t[0])
			st.set_color(t[5]); st.add_vertex(t[2])
			st.set_color(t[4]); st.add_vertex(t[1])
		else:
			st.set_color(t[3]); st.add_vertex(t[0])
			st.set_color(t[4]); st.add_vertex(t[1])
			st.set_color(t[5]); st.add_vertex(t[2])

func _commit(st: SurfaceTool) -> MeshInstance3D:
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = tunnel_mat
	add_child(m)
	return m

func _update_tunnels() -> void:
	for i in range(tunnels.size() - 1, -1, -1):
		var t: Dictionary = tunnels[i]
		if not t.told and s > t.s0 - 60.0:
			t.told = true
			show_msg("ASTEROIDENTUNNEL", 2.0)
		if s > t.s1 + 80.0:
			for n in t.nodes:
				n.queue_free()
			tunnels.remove_at(i)

# ======================= Updates =======================
func _update_rocks(dt: float) -> void:
	for i in range(rocks.size() - 1, -1, -1):
		var r: Dictionary = rocks[i]
		if r.s < s - 30.0:
			r.node.queue_free()
			rocks.remove_at(i)
			continue
		r.node.rotate_object_local(Vector3(0.3, 1, 0.2).normalized(), dt * 0.3)
		if r.hard and absf(r.s - s) < r.r and Vector2(r.x - ship_x, r.y - ship_y).length() < r.r * 0.8 + 1.0:
			damage(18.0)
			_explode(l2w(r.s, r.x, r.y), Color(0.8, 0.7, 0.6), 1.2)
			r.node.queue_free()
			rocks.remove_at(i)

func _update_enemies(dt: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		e.t += dt
		e.s -= 12.0 * dt
		e.x = clampf(e.x + sin(e.t * 1.3 + e.ph) * 6.0 * dt, -BX, BX)
		e.y = clampf(e.y + cos(e.t * 1.1 + e.ph) * 4.0 * dt, -BY, BY)
		place(e.node, e.s, e.x, e.y)
		e.node.rotate_object_local(Vector3.UP, PI)
		e.node.rotate_object_local(Vector3.FORWARD, sin(e.t * 1.3 + e.ph) * 0.4)
		e.fire -= dt
		var ds: float = e.s - s
		if e.fire <= 0.0 and ds > 25.0 and ds < 150.0:
			e.fire = rng.randf_range(1.6, 3.0)
			var b := MeshInstance3D.new()
			b.mesh = ebullet_mesh
			b.material_override = glow_red
			add_child(b)
			var tt := ds / 70.0
			ebullets.append({"node": b, "s": e.s, "x": e.x, "y": e.y, "vx": (ship_x - e.x) / tt, "vy": (ship_y - e.y) / tt, "vs": -70.0 + speed})
		if ds < -12.0 or e.hp <= 0.0:
			if e.hp <= 0.0:
				score += 100
				_explode(l2w(e.s, e.x, e.y), Color(1.0, 0.5, 0.2), 1.6)
			e.node.queue_free()
			enemies.remove_at(i)
			continue
		if absf(ds) < 2.0 and Vector2(e.x - ship_x, e.y - ship_y).length() < 2.6:
			damage(25.0)
			e.hp = 0.0

func _update_bullets(dt: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var b: Dictionary = bullets[i]
		b.s += (speed + BULLET_SPEED) * dt
		b.x += b.vx * dt
		b.y += b.vy * dt
		b.life -= dt
		var tr := frame(b.s)
		b.node.global_transform = Transform3D(tr.basis * Basis(Vector3.RIGHT, PI / 2), tr.origin + tr.basis.x * b.x + tr.basis.y * b.y)
		var hit := false
		for e in enemies:
			if absf(e.s - b.s) < 3.0 and Vector2(e.x - b.x, e.y - b.y).length() < 2.2:
				e.hp -= 1.0
				hit = true
				break
		if not hit:
			for r in rocks:
				if r.hard and absf(r.s - b.s) < r.r and Vector2(r.x - b.x, r.y - b.y).length() < r.r:
					hit = true
					break
		if hit or b.life <= 0.0:
			b.node.queue_free()
			bullets.remove_at(i)
	for i in range(ebullets.size() - 1, -1, -1):
		var b: Dictionary = ebullets[i]
		b.s += b.vs * dt
		b.x += b.vx * dt
		b.y += b.vy * dt
		place(b.node, b.s, b.x, b.y)
		if absf(b.s - s) < 1.8 and Vector2(b.x - ship_x, b.y - ship_y).length() < 1.9:
			damage(12.0)
			b.node.queue_free()
			ebullets.remove_at(i)
			continue
		if b.s < s - 15.0:
			b.node.queue_free()
			ebullets.remove_at(i)

func _explode(pos: Vector3, col: Color, size: float) -> void:
	var p := CPUParticles3D.new()
	var m := SphereMesh.new()
	m.radius = 0.25 * size
	m.height = 0.5 * size
	p.mesh = m
	var mat := _glow(col, 3.5)
	p.material_override = mat
	p.amount = 32
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.8
	p.direction = Vector3(0, 0, 0)
	p.spread = 180.0
	p.initial_velocity_min = 6.0 * size
	p.initial_velocity_max = 16.0 * size
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

func _update_camera(dt: float) -> void:
	var tr := frame(s - 12.5)
	var target := tr.origin + tr.basis.x * ship_x * 0.85 + tr.basis.y * (ship_y * 0.85 + 2.2)
	cam.global_position = cam.global_position.lerp(target, minf(1.0, dt * 8.0)) if t_game > 0.2 else target
	var look := l2w(s + 25.0, ship_x * 0.6, ship_y * 0.6)
	cam.look_at(look, tr.basis.y)

func _update_hud(dt: float) -> void:
	hud_score.text = "%08d" % score
	hud_hull.value = hull
	hud_shield.value = shield
	hud_info.text = "FPS %d  ·  Objekte %d  ·  Gegner %d" % [int(Engine.get_frames_per_second()), rocks.size(), enemies.size()]
	if msg_t > 0.0:
		msg_t -= dt
		hud_msg.modulate.a = clampf(msg_t, 0.0, 1.0)

# ======================= Testpilot =======================
func log_at(t: String) -> void:
	at_log.append("[%6.2fs] %s" % [t_game, t])
	print("AUTOTEST: ", t)

func _autotest_step(dt: float) -> void:
	at_frames += 1
	at_fps_sum += Engine.get_frames_per_second()
	at_shot_t -= dt
	var near_tunnel := false
	for t in tunnels:
		if s > t.s0 - 110.0 and s < t.s0 - 95.0 and not t.has("shot_a"):
			t["shot_a"] = true
			near_tunnel = true
			_screenshot("tunnel_anflug")
		if s > t.s0 + 30.0 and not t.has("shot_b"):
			t["shot_b"] = true
			_screenshot("tunnel_innen")
		if s > t.s1 - 30.0 and not t.has("shot_c"):
			t["shot_c"] = true
			_screenshot("tunnel_ausgang")
	if at_shot_t <= 0.0:
		at_shot_t = 3.0
		_screenshot("flug")
	if t_game > 42.0:
		log_at("Fertig. Frames: %d, mittlere FPS: %.1f, Strecke: %.0f, Tunnel: %d" % [at_frames, at_fps_sum / maxf(1, at_frames), s, tunnels.size()])
		var f := FileAccess.open(at_dir + "/bericht.txt", FileAccess.WRITE)
		if f:
			f.store_string("\n".join(at_log))
			f.close()
		get_tree().quit()

func _screenshot(tag: String) -> void:
	at_shots += 1
	var path := "%s/%02d_%s_%04.0fm.png" % [at_dir, at_shots, tag, s]
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(path)
		log_at("Screenshot " + path.get_file())
	else:
		log_at("FEHLER: kein Bild für " + tag)

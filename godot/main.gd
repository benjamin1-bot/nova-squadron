extends Node3D
## Prismwing – Godot-4-Version (Etappe 1)
## Bahn-Shooter: Flug entlang einer prozeduralen Bahn, Asteroidengürtel, Tunnel durch Riesen-Asteroiden,
## Gegner, Schüsse, HUD, Touch/Tastatur/Controller und ein automatischer Testpilot (--autotest).

const BX := 15.0
const BY := 10.0
const STEP := 4.0
const BULLET_SPEED := 170.0

static var world_idx := 0
static var carry := {}
static var playing := false
var menu_mode := false
var audio
var menu
var hud_layer: CanvasLayer
var diff := 1

var ups := {}
func upl(k: String) -> int:
	return int(ups.get(k, 0))

func record_score(sc: int, wv: int) -> void:
	var sv := get_save()
	if sc > int(sv.get("hs", 0)):
		put_save("hs", sc)
	var hs: Array = sv.get("hst", [])
	hs.append([sc, wv])
	hs.sort_custom(func(a, b): return a[0] > b[0])
	put_save("hst", hs.slice(0, 10))

func start_game(idx: int) -> void:
	playing = true
	carry = {}
	world_idx = idx
	put_save("world", idx)
	get_tree().paused = false
	get_tree().reload_current_scene()

func to_menu() -> void:
	playing = false
	carry = {}
	get_tree().paused = false
	get_tree().reload_current_scene()

func get_carry() -> Dictionary:
	return carry

func set_carry(d: Dictionary) -> void:
	carry = d

func get_save() -> Dictionary:
	var cf := ConfigFile.new()
	var d := {}
	if cf.load("user://prismwing.cfg") == OK:
		for k in cf.get_section_keys("save"):
			d[k] = cf.get_value("save", k)
	return d

func put_save(k: String, v) -> void:
	var cf := ConfigFile.new()
	cf.load("user://prismwing.cfg")
	cf.set_value("save", k, v)
	cf.save("user://prismwing.cfg")

func save_crystals(n: int) -> void:
	put_save("cr", n)

func goto_next_world() -> void:
	world_idx = (world_idx + 1) % WORLDS.size()
	get_tree().reload_current_scene()
const WORLDS := [
	{"name": "ASTEROIDENGÜRTEL KEPLER", "planet": false, "neb1": Color(0.3, 0.1, 0.55), "neb2": Color(0.05, 0.3, 0.6), "base": Color(0.004, 0.006, 0.018),
	 "fog": Color(0.1, 0.1, 0.22), "fogd": 0.0028, "sun": Color(1.0, 0.94, 0.86), "rock": Color(0.62, 0.56, 0.5), "glow": Color(0.3, 0.9, 1.0),
	 "tin": [Color(0.42, 0.34, 0.26), Color(0.2, 0.16, 0.12)], "tout": [Color(0.5, 0.44, 0.36), Color(0.32, 0.27, 0.22)], "tname": "ASTEROIDENTUNNEL"},
	{"name": "GEFRORENER OZEAN NIFL", "planet": true, "zenith": Color(0.06, 0.2, 0.42), "horizon": Color(0.62, 0.8, 0.95), "neb1": Color(0.2, 0.9, 0.6),
	 "fog": Color(0.5, 0.68, 0.85), "fogd": 0.0032, "sun": Color(0.92, 0.97, 1.0), "rock": Color(0.75, 0.88, 0.97), "glow": Color(0.45, 0.9, 1.0),
	 "pal": {"base": Color("2a5a82"), "base2": Color("3a7aa6"), "mid": Color("7ab4d8"), "rock": Color("b8daf0"), "rock2": Color("94c2e2"), "snow": Color("f6faff"), "snow_on": true},
	 "liquid": Color(0.05, 0.22, 0.36), "liquid_glow": 0.0, "liquid_y": -1.0, "floor_off": -3.0, "tname": "EISHÖHLE"},
	{"name": "LAVAPLANET SURTR", "planet": true, "zenith": Color(0.07, 0.025, 0.02), "horizon": Color(0.5, 0.18, 0.08), "neb1": Color(0.6, 0.2, 0.1),
	 "fog": Color(0.28, 0.1, 0.05), "fogd": 0.0042, "sun": Color(1.0, 0.78, 0.6), "rock": Color(0.36, 0.29, 0.26), "glow": Color(1.0, 0.45, 0.1),
	 "pal": {"base": Color("1a1210"), "base2": Color("2a1a14"), "mid": Color("3a2a22"), "rock": Color("4a3a34"), "rock2": Color("5a3020"), "snow": Color("ff6a20"), "snow_on": false},
	 "liquid": Color(1.0, 0.38, 0.06), "liquid_glow": 2.6, "liquid_y": -1.6, "floor_off": 0.0, "tname": "LAVAHÖHLE"},
	{"name": "KRISTALLNEBEL", "planet": false, "neb": 0.45, "neb1": Color(0.55, 0.15, 0.6), "neb2": Color(0.8, 0.35, 0.85), "base": Color(0.02, 0.008, 0.05),
	 "fog": Color(0.18, 0.06, 0.27), "fogd": 0.0034, "sun": Color(1.0, 0.86, 1.0), "rock": Color(0.66, 0.6, 0.76), "glow": Color(1.0, 0.45, 1.0),
	 "tin": [Color(0.4, 0.32, 0.48), Color(0.18, 0.12, 0.26)], "tout": [Color(0.55, 0.48, 0.64), Color(0.34, 0.28, 0.42)], "tname": "KRISTALLTUNNEL", "crystals": 0.45},
	{"name": "OZEANWELT THALASSA", "planet": true, "zenith": Color(0.1, 0.35, 0.66), "horizon": Color(0.66, 0.84, 0.95), "neb1": Color(0.8, 0.9, 1.0),
	 "fog": Color(0.58, 0.74, 0.87), "fogd": 0.0028, "sun": Color(1.0, 0.97, 0.88), "rock": Color(0.56, 0.52, 0.46), "glow": Color(0.4, 1.0, 0.9),
	 "pal": {"base": Color("2a5a2a"), "base2": Color("3a6a30"), "mid": Color("6a7a40"), "rock": Color("7a7066"), "rock2": Color("5e5650"), "snow": Color("f0f4ff"), "snow_on": false},
	 "liquid": Color(0.05, 0.3, 0.5), "liquid_glow": 0.0, "liquid_y": 0.5, "floor_off": -6.0, "tname": "FELSGROTTE", "stacks": 0.35},
	{"name": "PILZWALD MYKOS", "planet": true, "zenith": Color(0.04, 0.015, 0.08), "horizon": Color(0.32, 0.12, 0.42), "neb1": Color(0.5, 0.2, 0.8),
	 "fog": Color(0.17, 0.06, 0.23), "fogd": 0.0045, "sun": Color(0.85, 0.75, 1.0), "rock": Color(0.32, 0.36, 0.34), "glow": Color(0.4, 1.0, 0.85),
	 "pal": {"base": Color("2a2434"), "base2": Color("3a3046"), "mid": Color("4a5a52"), "rock": Color("5a645e"), "rock2": Color("464e4a"), "snow": Color("7affd8"), "snow_on": false},
	 "liquid": Color(0.2, 0.95, 0.65), "liquid_glow": 1.3, "liquid_y": -2.2, "floor_off": 0.0, "tname": "SPORENHÖHLE", "mush": 0.55},
	{"name": "WÜSTENPLANET ARRAKON", "planet": true, "zenith": Color(0.17, 0.33, 0.58), "horizon": Color(0.88, 0.72, 0.52), "neb1": Color(1.0, 0.9, 0.7),
	 "fog": Color(0.72, 0.57, 0.4), "fogd": 0.0026, "sun": Color(1.0, 0.93, 0.8), "rock": Color(0.85, 0.7, 0.48), "glow": Color(1.0, 0.75, 0.3),
	 "pal": {"base": Color("7a4a26"), "base2": Color("8a5a30"), "mid": Color("a87040"), "rock": Color("c08a52"), "rock2": Color("9a6a3e"), "snow": Color("e8c890"), "snow_on": true},
	 "liquid": Color(0, 0, 0), "liquid_glow": 0.0, "liquid_y": -999.0, "floor_off": 0.0, "tname": "SANDSTEINSCHLUCHT", "stacks": 0.2},
	{"name": "SMARAGDGÜRTEL", "planet": false, "neb": 0.45, "neb1": Color(0.1, 0.55, 0.25), "neb2": Color(0.3, 0.75, 0.35), "base": Color(0.005, 0.02, 0.01),
	 "fog": Color(0.08, 0.25, 0.12), "fogd": 0.0032, "sun": Color(0.95, 1.0, 0.9), "rock": Color(0.42, 0.47, 0.42), "glow": Color(0.1, 1.0, 0.5),
	 "tin": [Color(0.26, 0.32, 0.27), Color(0.1, 0.14, 0.11)], "tout": [Color(0.4, 0.46, 0.4), Color(0.24, 0.3, 0.25)], "tname": "SMARAGDTUNNEL", "crystals": 0.3},
	{"name": "SCHIFFSFRIEDHOF", "planet": false, "neb": 0.45, "neb1": Color(0.5, 0.12, 0.08), "neb2": Color(0.25, 0.08, 0.1), "base": Color(0.012, 0.004, 0.004),
	 "fog": Color(0.12, 0.05, 0.05), "fogd": 0.004, "sun": Color(1.0, 0.75, 0.6), "rock": Color(0.42, 0.4, 0.38), "glow": Color(1.0, 0.25, 0.15),
	 "tin": [Color(0.3, 0.29, 0.28), Color(0.14, 0.13, 0.13)], "tout": [Color(0.4, 0.38, 0.36), Color(0.24, 0.22, 0.21)], "tname": "WRACKSCHACHT", "wrecks": 0.12},
	{"name": "ORBITALSTATION ORION", "planet": false, "neb": 0.45, "neb1": Color(0.1, 0.25, 0.6), "neb2": Color(0.2, 0.45, 0.8), "base": Color(0.004, 0.01, 0.03),
	 "fog": Color(0.06, 0.14, 0.3), "fogd": 0.0026, "sun": Color(1.0, 0.97, 0.92), "rock": Color(0.62, 0.62, 0.66), "glow": Color(0.3, 0.75, 1.0),
	 "tin": [Color(0.38, 0.38, 0.42), Color(0.18, 0.18, 0.22)], "tout": [Color(0.5, 0.5, 0.55), Color(0.3, 0.3, 0.34)], "tname": "VERSORGUNGSSCHACHT", "station": 0.1},
	{"name": "GEWITTERNEBEL", "planet": false, "neb": 0.45, "neb1": Color(0.12, 0.5, 0.4), "neb2": Color(0.25, 0.6, 0.5), "base": Color(0.004, 0.02, 0.015),
	 "fog": Color(0.09, 0.27, 0.22), "fogd": 0.0042, "sun": Color(0.85, 1.0, 0.95), "rock": Color(0.5, 0.56, 0.52), "glow": Color(0.6, 1.0, 0.9),
	 "tin": [Color(0.3, 0.36, 0.33), Color(0.12, 0.16, 0.14)], "tout": [Color(0.45, 0.5, 0.47), Color(0.27, 0.31, 0.29)], "tname": "GEWITTERSCHLUND", "storm": true},
	{"name": "NEONSTADT VEGA-9", "planet": true, "zenith": Color(0.01, 0.01, 0.05), "horizon": Color(0.22, 0.06, 0.3), "neb1": Color(0.4, 0.1, 0.6),
	 "fog": Color(0.06, 0.04, 0.14), "fogd": 0.0036, "sun": Color(0.7, 0.6, 1.0), "rock": Color(0.35, 0.35, 0.42), "glow": Color(1.0, 0.2, 0.75),
	 "pal": {"base": Color("10101c"), "base2": Color("181828"), "mid": Color("1a1a2a"), "rock": Color("22223a"), "rock2": Color("1c1c30"), "snow": Color("ff30c0"), "snow_on": false},
	 "liquid": Color(0, 0, 0), "liquid_glow": 0.0, "liquid_y": -999.0, "floor_off": 0.0, "tname": "CYBER-TUNNEL – GEGENVERKEHR!", "city": true},
	{"name": "EREIGNISHORIZONT", "planet": false, "neb1": Color(0.4, 0.15, 0.45), "neb2": Color(0.15, 0.08, 0.3), "base": Color(0.004, 0.002, 0.008),
	 "fog": Color(0.07, 0.04, 0.12), "fogd": 0.0026, "sun": Color(1.0, 0.75, 0.5), "rock": Color(0.55, 0.5, 0.47), "glow": Color(1.0, 0.6, 0.25),
	 "tin": [Color(0.34, 0.3, 0.28), Color(0.14, 0.12, 0.12)], "tout": [Color(0.46, 0.42, 0.39), Color(0.27, 0.24, 0.22)], "tname": "GRAVITATIONSSCHACHT", "hole": true},
	{"name": "SONNENKORONA HELIOS", "planet": false, "neb": 0.45, "neb1": Color(0.9, 0.35, 0.05), "neb2": Color(0.6, 0.15, 0.02), "base": Color(0.05, 0.012, 0.0),
	 "fog": Color(0.35, 0.1, 0.02), "fogd": 0.0036, "sun": Color(1.0, 0.72, 0.4), "rock": Color(0.24, 0.18, 0.14), "glow": Color(1.0, 0.55, 0.1),
	 "tin": [Color(0.24, 0.16, 0.12), Color(0.1, 0.06, 0.04)], "tout": [Color(0.3, 0.22, 0.17), Color(0.16, 0.11, 0.08)], "tname": "SCHLACKETUNNEL", "bigsun": true, "sun_rot": Vector3(-10, 180, 0)},
]
var W: Dictionary
var sun: DirectionalLight3D
var sun_energy := 1.6
var storm_t := 2.0
var flash := 0.0
var metal_mat: StandardMaterial3D
var panel_mat: StandardMaterial3D
var city_mat: StandardMaterial3D
var neon_mats: Array = []
var cars: Array = []
var next_car_s := 140.0
var car_mats: Array = []
var head_mat: StandardMaterial3D
var line_mat: StandardMaterial3D
var block_mat: StandardMaterial3D
const TIX := BX + 8.0
const TIY0 := -(BY + 5.0)
const TIY1 := BY + 7.0
var env: Environment
var amb_base := 0.7
var fog_base := 0.003
var crystal_mat: StandardMaterial3D
var crystal_mesh: CylinderMesh
var mush_stem: StandardMaterial3D
var mush_cap: StandardMaterial3D
const GY := -18.0
var ground_mat: StandardMaterial3D
var mount_mat: StandardMaterial3D
var liquid_mat: StandardMaterial3D
var chunks: Array = []       # {s1, nodes}
var next_chunk_s := -40.0
var next_mount_s := 0.0
const CHUNK := 120.0

var speed := 42.0
var s := 30.0
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
var game
var widx := 0
var start_wave := 1
var shield_fx := 0.0
var dmg_fx := 0.0
var flash_fx := 0.0
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
		elif a.begins_with("--boss="):
			set_meta("force_boss", int(a.substr(7)))
			start_wave = 4
		elif a == "--passage":
			set_meta("passage", true)
		elif a.begins_with("--wave="):
			start_wave = int(a.substr(7))
		elif a.begins_with("--world="):
			world_idx = int(a.substr(8))
	world_idx = clampi(world_idx, 0, WORLDS.size() - 1)
	W = WORLDS[world_idx]
	widx = world_idx
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
	var sv := get_save()
	diff = int(sv.get("diff", 1))
	ups = sv.get("up", {})
	menu_mode = not autotest and not playing and carry.is_empty()
	audio = load("res://audio.gd").new()
	add_child(audio)
	audio.music_on = sv.get("music", true)
	audio.sfx_on = sv.get("sound", true)
	menu = load("res://menu.gd").new()
	add_child(menu)
	menu.setup(self)
	if autotest:
		audio.music_on = false
		audio.sfx_on = false
	game = load("res://game_hz.gd").new()
	add_child(game)
	game.setup(self)
	if menu_mode:
		hud_layer.visible = false
		menu.show_main()
		audio.play_music("menu")
	else:
		audio.play_music("play")
	if autotest:
		next_tunnel_s = 260.0
	show_msg(W.name, 3.0)
	if autotest:
		log_at("Welt: " + W.name)

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
	fn.noise_type = FastNoiseLite.TYPE_CELLULAR
	fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	fn.frequency = 0.035
	fn.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn.fractal_octaves = 3
	nt.noise = fn
	var ct := NoiseTexture2D.new()
	ct.width = 256
	ct.height = 256
	ct.seamless = true
	var fn2 := FastNoiseLite.new()
	fn2.frequency = 0.04
	fn2.fractal_octaves = 5
	ct.noise = fn2
	var grad := Gradient.new()
	grad.set_color(0, Color(0.62, 0.58, 0.54))
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
	rock_mat.albedo_color = W.rock
	tunnel_mat = rock_mat.duplicate() as StandardMaterial3D
	tunnel_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tunnel_mat.next_pass = null
	tunnel_mat.albedo_color = Color.WHITE
	tunnel_mat.uv1_scale = Vector3(0.22, 0.22, 0.22)
	tunnel_mat.normal_scale = 0.9
	ground_mat = tunnel_mat.duplicate() as StandardMaterial3D
	ground_mat.cull_mode = BaseMaterial3D.CULL_BACK
	ground_mat.uv1_scale = Vector3(0.06, 0.06, 0.06)
	mount_mat = ground_mat.duplicate() as StandardMaterial3D
	mount_mat.uv1_scale = Vector3(0.035, 0.035, 0.035)
	mount_mat.next_pass = outline_mat
	metal_mat = _toon(Color(0.36, 0.35, 0.36), 0.45, 0.7)
	panel_mat = _toon(Color(0.12, 0.22, 0.5), 0.25, 0.6)
	panel_mat.emission_enabled = true
	panel_mat.emission = Color(0.1, 0.25, 0.6)
	panel_mat.emission_energy_multiplier = 0.4
	city_mat = _toon(Color(0.1, 0.1, 0.14), 0.35, 0.5)
	var win_mat := _glow(Color(1.0, 0.82, 0.55), 1.4)
	neon_mats.append(win_mat)
	for nc in [Color(1.0, 0.2, 0.75), Color(0.2, 0.9, 1.0), Color(1.0, 0.45, 0.1)]:
		neon_mats.append(_glow(nc, 3.0))
	for cc in [Color(0.75, 0.1, 0.15), Color(0.9, 0.85, 0.2), Color(0.15, 0.35, 0.8), Color(0.85, 0.86, 0.9), Color(0.1, 0.1, 0.12)]:
		car_mats.append(_toon(cc, 0.3, 0.6))
	head_mat = _glow(Color(1.0, 0.97, 0.85), 4.0)
	line_mat = StandardMaterial3D.new()
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.vertex_color_use_as_albedo = true
	line_mat.albedo_color = Color(1.35, 1.35, 1.35)
	line_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if W.has("city"):
		ground_mat.albedo_texture = null
		ground_mat.normal_enabled = false
		ground_mat.roughness = 0.45
		ground_mat.metallic = 0.1
		ground_mat.albedo_color = Color(0.55, 0.55, 0.6)
	block_mat = _toon(Color(0.12, 0.12, 0.17), 0.4, 0.55)
	block_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	block_mat.next_pass = null
	crystal_mat = StandardMaterial3D.new()
	crystal_mat.albedo_color = W.glow.lerp(Color.WHITE, 0.35)
	crystal_mat.emission_enabled = true
	crystal_mat.emission = W.glow
	crystal_mat.emission_energy_multiplier = 1.4
	crystal_mat.roughness = 0.15
	crystal_mat.metallic = 0.4
	crystal_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	crystal_mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	crystal_mat.next_pass = outline_mat
	crystal_mesh = CylinderMesh.new()
	crystal_mesh.radial_segments = 6
	crystal_mesh.rings = 1
	crystal_mesh.top_radius = 0.05
	crystal_mesh.bottom_radius = 0.7
	crystal_mesh.height = 5.0
	mush_stem = _toon(Color(0.82, 0.78, 0.86), 0.7)
	mush_cap = _toon(Color(0.55, 0.2, 0.7), 0.5)
	mush_cap.emission_enabled = true
	mush_cap.emission = W.glow
	mush_cap.emission_energy_multiplier = 0.5
	liquid_mat = StandardMaterial3D.new()
	if W.planet:
		liquid_mat.albedo_color = W.liquid
		if W.liquid_glow > 0.0:
			liquid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var lt := NoiseTexture2D.new()
			lt.seamless = true
			var lfn := FastNoiseLite.new()
			lfn.frequency = 0.02
			lfn.fractal_octaves = 4
			lt.noise = lfn
			var lg := Gradient.new()
			lg.set_color(0, W.liquid.darkened(0.5))
			lg.set_color(1, W.liquid.lightened(0.6))
			lg.add_point(0.55, W.liquid)
			lt.color_ramp = lg
			liquid_mat.albedo_texture = lt
			liquid_mat.albedo_color = Color.WHITE * (0.7 + W.liquid_glow * 0.35)
			liquid_mat.uv1_triplanar = true
			liquid_mat.uv1_scale = Vector3(0.03, 0.03, 0.03)
		else:
			liquid_mat.metallic = 0.15
			liquid_mat.roughness = 0.25
			liquid_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
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
	sm.radial_segments = 16 + detail * 6
	sm.rings = 10 + detail * 4
	var arr := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var sc := Vector3(r.randf_range(0.8, 1.5), r.randf_range(0.55, 1.05), r.randf_range(0.8, 1.4))
	for i in verts.size():
		var v := verts[i] * 2.0 * sc
		v += v.normalized() * noise.get_noise_3d(v.x * 0.9 + seed_v, v.y * 0.9, v.z * 0.9) * 0.18
		verts[i] = v
	# große Bruchflächen (Ebenen tangential an eine Kugel, wie beim Zuschneiden echter Steine)
	var passes := [[10 + r.randi() % 5, 0.55, 0.88], [12 + r.randi() % 8, 0.9, 0.97]]
	for pss in passes:
		for c in int(pss[0]):
			var n := Vector3(r.randf() - 0.5, (r.randf() - 0.5) * 1.3, r.randf() - 0.5).normalized()
			var mx := -1e9
			for v in verts:
				mx = maxf(mx, v.dot(n))
			var d := mx * r.randf_range(pss[1], pss[2])
			for i in verts.size():
				var k := verts[i].dot(n) - d
				if k > 0.0:
					verts[i] = verts[i] - n * k
	# Gesteinsschichten: leichte Stufen/Simse entlang der Höhe
	var ymin := 1e9
	var ymax := -1e9
	for v in verts:
		ymin = minf(ymin, v.y)
		ymax = maxf(ymax, v.y)
	var lay := r.randf_range(2.2, 3.4)
	var tilt := Vector3(r.randf_range(-0.25, 0.25), 1.0, r.randf_range(-0.25, 0.25)).normalized()
	for i in verts.size():
		var v := verts[i]
		var hh := v.dot(tilt) * lay + noise.get_noise_2d(v.x * 0.6, v.z * 0.6) * 0.35
		var f := hh - floor(hh)
		var step := _sm(0.78, 1.0, f) * 0.07
		verts[i] = Vector3(v.x * (1.0 - step), v.y, v.z * (1.0 - step))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, idx.size(), 3):
		for j in 3:
			var v := verts[idx[i + j]]
			var nv := noise.get_noise_3d(v.x * 1.7 + seed_v, v.y * 1.7, v.z * 1.7)
			var band := 0.9 + 0.1 * sin(v.dot(tilt) * lay * TAU + nv * 2.0)
			var ao := 0.62 + 0.38 * clampf((v.y - ymin) / maxf(0.01, ymax - ymin), 0.0, 1.0)
			var g := (0.8 + nv * 0.18) * band * ao
			st.set_color(Color(g * 1.02, g, g * 0.95))
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()

# ======================= Umgebung =======================
func _make_environment() -> void:
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = W.get("sun_rot", Vector3(-35, 40, 0))
	sun.light_color = W.sun
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
	sky_mat.set_shader_parameter("neb1", W.neb1)
	if W.planet:
		sky_mat.set_shader_parameter("planet", 1.0)
		sky_mat.set_shader_parameter("zenith", W.zenith)
		sky_mat.set_shader_parameter("horizon", W.horizon)
	else:
		sky_mat.set_shader_parameter("neb2", W.neb2)
		sky_mat.set_shader_parameter("hole", 1.0 if W.has("hole") else 0.0)
		sky_mat.set_shader_parameter("neb_strength", W.get("neb", 1.0))
		sky_mat.set_shader_parameter("bigsun", 1.0 if W.has("bigsun") else 0.0)
		sky_mat.set_shader_parameter("base", W.base)
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
	env.fog_light_color = W.fog
	env.fog_density = W.fogd
	env.fog_sky_affect = 0.0
	if W.planet:
		env.fog_aerial_perspective = 0.6
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.05
	amb_base = env.ambient_light_energy
	fog_base = env.fog_density
	self.env = env
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
	var wb := Button.new()
	wb.text = "II"
	wb.position = Vector2(1180, 14)
	wb.size = Vector2(80, 60)
	wb.add_theme_font_size_override("font_size", 28)
	wb.focus_mode = Control.FOCUS_NONE
	wb.pressed.connect(func():
		if game.state == "play":
			get_tree().paused = true
			menu.show_pause())
	cl.add_child(wb)
	hud_layer = cl
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
	game.update(dt)
	_update_tunnels()
	if W.has("city"):
		_update_cars(dt)
	_update_camera(dt)
	_update_hud(dt)
	if W.has("storm"):
		_update_storm(dt)
	if autotest:
		_autotest_step(dt)

func _in_tunnel(sv: float) -> Dictionary:
	for t in tunnels:
		if sv >= t.s0 - 2.0 and sv <= t.s1 + 2.0:
			return t
	return {}

func _update_ship(dt: float) -> void:
	var v := _input_vec()
	if game.state != "play":
		v = Vector2.ZERO
	if autotest or menu_mode:
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
	if not tn2.is_empty() and W.has("city"):
		ship_x = clampf(ship_x, -TIX + 2.5, TIX - 2.5)
		ship_y = clampf(ship_y, TIY0 + 2.0, TIY1 - 2.0)
	elif not tn2.is_empty():
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
		shield = minf(100.0, shield + 17.0 * (1.0 + upl("regen") * 0.25) * dt)
	var in_t := not _in_tunnel(s + 20).is_empty()
	headlight.light_energy = lerpf(headlight.light_energy, 2.2 if in_t else 0.0, minf(1.0, dt * 3.0))
	var k_in := 1.0 if not _in_tunnel(s + 4).is_empty() else 0.0
	env.ambient_light_energy = lerpf(env.ambient_light_energy, amb_base * (1.0 - 0.7 * k_in), minf(1.0, dt * 2.0))
	env.fog_density = lerpf(env.fog_density, fog_base * (1.0 - 0.75 * k_in), minf(1.0, dt * 2.0))
	if game.roll_t > 0.0:
		var k: float = 1.0 - game.roll_t / game.ROLL
		ship.rotate_object_local(Vector3.FORWARD, game.roll_dir * (k * k * (3.0 - 2.0 * k)) * TAU)
	shield_fx = maxf(0.0, shield_fx - dt * 2.5)
	dmg_fx = maxf(0.0, dmg_fx - dt * 2.0)

func damage(d: float) -> void:
	game.damage_player(d, true)

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
	if game != null and (game.boss != null or game.wave % 4 == 0 or game.passage != null):
		next_tunnel_s = maxf(next_tunnel_s, s + 900.0)
	if next_tunnel_s < s + 900.0:
		var tl := rng.randf_range(220.0, 320.0)
		_add_tunnel(next_tunnel_s, tl)
		next_tunnel_s += tl + rng.randf_range(900.0, 1400.0)
	if W.planet:
		while next_chunk_s < s + 720.0:
			_add_chunk(next_chunk_s)
			next_chunk_s += CHUNK
		while next_mount_s < s + 900.0:
			var sv := next_mount_s
			next_mount_s += rng.randf_range(35.0, 70.0)
			_add_mountain(sv)
		for i in range(chunks.size() - 1, -1, -1):
			if chunks[i].s1 < s - 40.0:
				for n in chunks[i].nodes:
					n.queue_free()
				chunks.remove_at(i)
	while next_rock_s < s + 520.0:
		var sv := next_rock_s
		next_rock_s += rng.randf_range(3.0, 7.0)
		if not _in_tunnel(sv).is_empty():
			continue
		if W.planet:
			_add_ground_rock(sv)
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
		if not inside and W.has("wrecks") and rng.randf() < W.wrecks and dist_ok(x, y) and absf(x) > 45.0:
			_add_wreck(sv, x, y)
			continue
		if not inside and W.has("station") and rng.randf() < W.station and dist_ok(x, y) and absf(x) > 40.0:
			_add_module(sv, x, y)
			continue
		if not inside and W.has("crystals") and rng.randf() < W.crystals and dist_ok(x, y):
			_add_crystal_cluster(sv, x, y, r)
		else:
			_add_rock(sv, x, y, r, inside)

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
	if W.planet:
		var e2 := clampf(minf(sv - s0, s1 - sv) / 55.0, 0.0, 1.0)
		var tap2 := 0.6 + 0.4 * sin(e2 * PI / 2.0)
		var mid2 := 0.75 + 0.25 * sin(clampf((sv - s0) / (s1 - s0), 0.0, 1.0) * PI)
		var R2 := r0 * tap2 * mid2 * (1.0 + noise.get_noise_3d(ca * 2.0 + sd, sa * 2.0, sv * 0.02) * 0.35 + noise.get_noise_3d(ca * 6.0, sa * 6.0 + sd, sv * 0.06) * 0.1)
		var y2 := sa * R2 * (1.25 if sa > 0.0 else 1.0)
		return Vector2(ca * R2 * 1.5, maxf(y2, GY - 9.0))
	var e := clampf(minf(sv - s0, s1 - sv) / 40.0, 0.0, 1.0)
	var tap := 0.5 + 0.5 * sin(e * PI / 2.0)
	var mid := 0.85 + 0.15 * sin(clampf((sv - s0) / (s1 - s0), 0.0, 1.0) * PI)
	var R := r0 * tap * mid * (1.0 + noise.get_noise_3d(ca * 2.0 + sd, sa * 2.0, sv * 0.02) * 0.3 + noise.get_noise_3d(ca * 6.0, sa * 6.0 + sd, sv * 0.06) * 0.08)
	return Vector2(ca * R, sa * R * 0.85)

func _sm(a: float, b: float, v: float) -> float:
	var q := clampf((v - a) / (b - a), 0.0, 1.0)
	return q * q * (3.0 - 2.0 * q)

func _pal_col(e: float, n1: float, n2: float) -> Color:
	var p: Dictionary = W.pal
	var c: Color = p.base.lerp(p.base2, n1 * 0.5 + 0.5)
	c = c.lerp(p.mid, _sm(0.22, 0.38, e) * 0.6)
	var rc: Color = p.rock.lerp(p.rock2, n2 * 0.5 + 0.5)
	c = c.lerp(rc, _sm(0.34, 0.6, e))
	if p.snow_on:
		c = c.lerp(p.snow, _sm(0.82, 0.97, e))
	return c

func _col_in(a: float, sv: float) -> Color:
	var n := noise.get_noise_3d(cos(a) * 7.0, sin(a) * 7.0, sv * 0.2) * 0.5 + 0.5
	if W.planet:
		var p: Dictionary = W.pal
		var band := 0.86 + 0.14 * sin(sin(a) * 9.0 + noise.get_noise_2d(sv * 0.05, cos(a) * 3.0) * 2.5)
		return p.rock2.lerp(p.base2, n * 0.8).darkened(0.25) * band
	var band2 := 0.88 + 0.12 * sin(sin(a) * 8.0 + noise.get_noise_2d(sv * 0.04, cos(a) * 3.0) * 2.5)
	return W.tin[0].lerp(W.tin[1], n) * band2

func _col_out(a: float, sv: float) -> Color:
	var n := noise.get_noise_3d(cos(a) * 3.0, sin(a) * 3.0, sv * 0.04) * 0.5 + 0.5
	if W.planet:
		var y := sin(a)
		return _pal_col(clampf(0.2 + y * 0.75, 0.0, 1.0), n * 2.0 - 1.0, noise.get_noise_3d(cos(a) * 9.0, sin(a) * 9.0, sv * 0.1))
	return W.tout[0].lerp(W.tout[1], n)

func _add_tunnel(s0: float, tl: float) -> void:
	if W.has("city"):
		_add_city_tunnel(s0, tl)
		return
	var s1 := s0 + tl
	var SEG := 40
	var STEPT := 2.6
	var nr := int(round(tl / STEPT))
	var r0 := rng.randf_range(58.0, 78.0) if not W.planet else rng.randf_range(70.0, 95.0)
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
	# leuchtende Kristalle an der Innenwand, dazu Lichter
	var gm := StandardMaterial3D.new()
	gm.albedo_color = W.glow.lerp(Color.WHITE, 0.3)
	gm.emission_enabled = true
	gm.emission = W.glow
	gm.emission_energy_multiplier = 1.6
	gm.roughness = 0.2
	gm.metallic = 0.3
	gm.next_pass = outline_mat
	var cm := crystal_mesh
	var cnt := 0
	var sv := s0 + 14.0
	while sv < s1 - 10.0:
		var a := rng.randf() * TAU
		if W.planet and sin(a) < -0.5:
			a = -a
		var ip := _inner(a, sv) * 0.97
		var fr := frame(sv)
		var base := fr.origin + fr.basis.x * ip.x + fr.basis.y * ip.y
		var inward := -(fr.basis.x * cos(a) + fr.basis.y * sin(a)).normalized()
		var grp := Node3D.new()
		add_child(grp)
		grp.global_position = base
		var nn := 2 + rng.randi() % 3
		for c in nn:
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = crystal_mat
			grp.add_child(mi)
			var d := (inward + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))).normalized()
			var up := d
			var side := up.cross(Vector3(0.3, 0.9, 0.1)).normalized()
			mi.basis = Basis(side, up, side.cross(up)).scaled(Vector3.ONE * rng.randf_range(0.6, 1.4))
			mi.position = d * 1.0
		nodes.append(grp)
		if cnt % 2 == 0:
			var ol := OmniLight3D.new()
			ol.light_color = W.glow
			ol.light_energy = 2.2
			ol.omni_range = 30.0
			ol.omni_attenuation = 1.4
			add_child(ol)
			ol.global_position = base + inward * 3.0
			nodes.append(ol)
		cnt += 1
		sv += rng.randf_range(16.0, 26.0)
	# Tropfsteine an Decke/Boden und Geröll an den Seiten (nur dort, wo nicht geflogen wird)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 7
	var stm := tunnel_mat.duplicate() as StandardMaterial3D
	stm.vertex_color_use_as_albedo = false
	stm.albedo_color = _col_in(PI / 2, s0)
	var rbm := rock_mat.duplicate() as StandardMaterial3D
	rbm.albedo_color = _col_in(PI * 1.5, s0) * 1.5
	var rubble := Node3D.new()
	add_child(rubble)
	nodes.append(rubble)
	var cr := s0 + 8.0
	var clamp_x := (BX + 7.0) * 0.8
	var clamp_y := (BY + 6.0) * 0.8
	while cr < s1 - 8.0:
		var top := rng.randf() < 0.6
		var a := rng.randf_range(PI * 0.3, PI * 0.7) if top else rng.randf_range(PI * 1.25, PI * 1.75)
		var ip := _inner(a, cr)
		var dir2 := Vector2(cos(a), sin(a))
		var wall := ip.length()
		var lim := Vector2(clamp_x * cos(a), clamp_y * sin(a)).length() + 1.5
		var ln := minf(rng.randf_range(2.0, 7.0), wall - lim)
		if ln > 0.8:
			var fr := frame(cr)
			var basep := fr.origin + fr.basis.x * ip.x * 1.02 + fr.basis.y * ip.y * 1.02
			var inward := -(fr.basis.x * dir2.x + fr.basis.y * dir2.y).normalized()
			var mi := MeshInstance3D.new()
			mi.mesh = cone
			mi.material_override = stm
			rubble.add_child(mi)
			var side := inward.cross(fr.basis.z).normalized()
			var rad := ln * rng.randf_range(0.18, 0.3)
			mi.global_transform = Transform3D(Basis(side * rad, -inward * ln, side.cross(-inward) * rad), basep + inward * ln * 0.5)
		if rng.randf() < 0.5:
			var a2 := rng.randf_range(PI * 1.1, PI * 1.35) if rng.randf() < 0.5 else rng.randf_range(PI * 1.65, PI * 1.9)
			var ip2 := _inner(a2, cr) * 0.96
			var fr2 := frame(cr)
			var rk := MeshInstance3D.new()
			rk.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
			rk.material_override = rbm
			rubble.add_child(rk)
			rk.global_position = fr2.origin + fr2.basis.x * ip2.x + fr2.basis.y * ip2.y
			rk.scale = Vector3.ONE * rng.randf_range(0.8, 1.6)
			rk.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)
		cr += rng.randf_range(5.0, 10.0)
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
			show_msg(W.tname, 2.0)
		if s > t.s1 + 80.0:
			for n in t.nodes:
				n.queue_free()
			tunnels.remove_at(i)

# ======================= Planetenoberfläche =======================
func _tunnel_sink(sv: float) -> float:
	var k := 0.0
	for t in tunnels:
		var e := minf(sv - (t.s0 + 6.0), (t.s1 - 6.0) - sv)
		k = maxf(k, clampf(e / 10.0, 0.0, 1.0))
	return k

func ground_h(x: float, sv: float) -> float:
	if W.has("city"):
		return 0.0
	var ax := absf(x)
	var side := _sm(BX + 14.0, BX + 90.0, ax)
	var n1 := noise.get_noise_2d(x * 0.025, sv * 0.025)
	var n2 := noise.get_noise_2d(x * 0.09 + 40.0, sv * 0.09)
	var h: float = 1.0 + n1 * 3.5 + n2 * 0.8 + W.floor_off * (1.0 - side)
	var rn := 1.0 - absf(noise.get_noise_2d(x * 0.016 - 7.0, sv * 0.016))
	h += side * (14.0 + noise.get_noise_2d(x * 0.011 + 9.0, sv * 0.011) * 26.0 + absf(n1) * 12.0 + rn * rn * rn * 26.0)
	var river := noise.get_noise_2d(x * 0.008 - 20.0, sv * 0.006)
	h -= _sm(0.1, 0.4, river) * 5.0 * (1.0 - side * 0.7)
	return h - _tunnel_sink(sv) * 34.0

func _add_chunk(sa: float) -> void:
	var nodes: Array = []
	var DS := 4.0
	var xs: Array = []
	var x := -300.0
	while x <= 300.0:
		xs.append(x)
		x += 4.0 if absf(x) < 60.0 else 9.0
	var rows := int(CHUNK / DS)
	var grid: Array = []
	for r in rows + 1:
		var sv := sa + r * DS
		var fr := frame(sv)
		var row: Array = []
		for xx in xs:
			var h := ground_h(xx, sv)
			var p: Vector3 = fr.origin + fr.basis.x * xx + fr.basis.y * (GY + h)
			var e := clampf((h + 4.0) / 70.0, 0.0, 1.2) + noise.get_noise_2d(xx * 0.05, sv * 0.05) * 0.12
			var c := _pal_col(e, noise.get_noise_2d(xx * 0.03, sv * 0.03), noise.get_noise_2d(xx * 0.12, sv * 0.12))
			if not W.has("city"):
				var slope := (absf(ground_h(xx + 3.0, sv) - h) + absf(ground_h(xx, sv + 3.0) - h)) / 3.0
				var rk := _sm(0.55, 1.3, slope)
				if rk > 0.0:
					var pal: Dictionary = W.pal
					var rc: Color = pal.rock.lerp(pal.rock2, noise.get_noise_2d(xx * 0.2, sv * 0.2) * 0.5 + 0.5)
					rc *= 0.86 + 0.14 * sin(h * 1.4 + noise.get_noise_2d(xx * 0.05, sv * 0.05) * 3.0)
					c = c.lerp(rc, rk * 0.85)
			row.append([p, c])
		grid.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in rows:
		for k in xs.size() - 1:
			var A = grid[r][k]
			var B = grid[r][k + 1]
			var C = grid[r + 1][k]
			var D = grid[r + 1][k + 1]
			for v in [A, C, B, B, C, D]:
				st.set_color(v[1])
				st.add_vertex(v[0])
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = ground_mat
	add_child(m)
	nodes.append(m)
	if W.has("city"):
		nodes.append(_street_lines(sa))
	# Flüssigkeit (Wasser / Lava) als Fläche, folgt der Bahn
	if W.liquid_y < -100.0:
		chunks.append({"s1": sa + CHUNK, "nodes": nodes})
		return
	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lx := [-300.0, -150.0, -60.0, 0.0, 60.0, 150.0, 300.0]
	var rows2 := int(CHUNK / 8.0)
	for r in rows2:
		if _tunnel_sink(sa + r * 8.0 + 4.0) > 0.0 and _tunnel_sink(sa + r * 8.0 - 4.0) > 0.0 and _tunnel_sink(sa + r * 8.0 + 12.0) > 0.0:
			continue
		var fa := frame(sa + r * 8.0)
		var fb := frame(sa + (r + 1) * 8.0)
		for k in lx.size() - 1:
			var ly: float = GY + W.liquid_y
			var p1: Vector3 = fa.origin + fa.basis.x * lx[k] + fa.basis.y * ly
			var p2: Vector3 = fa.origin + fa.basis.x * lx[k + 1] + fa.basis.y * ly
			var p3: Vector3 = fb.origin + fb.basis.x * lx[k] + fb.basis.y * ly
			var p4: Vector3 = fb.origin + fb.basis.x * lx[k + 1] + fb.basis.y * ly
			for v in [p1, p3, p2, p2, p3, p4]:
				st2.set_normal(fa.basis.y)
				st2.add_vertex(v)
	var lm := MeshInstance3D.new()
	lm.mesh = st2.commit()
	lm.material_override = liquid_mat
	add_child(lm)
	nodes.append(lm)
	chunks.append({"s1": sa + CHUNK, "nodes": nodes})

## Berg nach dem Vorbild aus Coin City (_mountain_mesh): Grat-Rauschen, Höhenstufen-Farben, Schnee
func _mountain_mesh(rad: float, hgt: float, sd: int) -> ArrayMesh:
	var rings := 24
	var segs := 40
	var grid: Array = []
	for r in rings + 1:
		var t := float(r) / rings
		var row: Array = []
		for k in segs:
			var a := float(k) / segs * TAU
			var spur := 1.0 - absf(noise.get_noise_3d(cos(a) * 1.6, sin(a) * 1.6, sd + 31))
			var ridge := 1.0 + 0.28 * noise.get_noise_3d(cos(a) * 0.72, sin(a) * 0.72, sd) + 0.22 * spur * spur * spur
			var radius := rad * pow(t, 0.92) * ridge
			var bx := cos(a) * radius
			var bz := sin(a) * radius
			var y := hgt * pow(1.0 - t, 1.25)
			y += noise.get_noise_3d(bx * 0.012, y * 0.012, bz * 0.012 + sd) * hgt * 0.14 * (1.0 - t * 0.5)
			var gully := 1.0 - absf(noise.get_noise_3d(bx * 0.045, y * 0.02, bz * 0.045 + sd + 5))
			y -= gully * gully * hgt * 0.035 * (1.0 - t)
			y += noise.get_noise_3d(bx * 0.06, y * 0.06, bz * 0.06 + sd + 13) * hgt * 0.025
			var terr := 9.0
			y += (round(y / terr) * terr - y) * 0.28
			var x := bx + noise.get_noise_3d(bz * 0.012, y * 0.012, sd) * rad * 0.05 * t
			var z := bz + noise.get_noise_3d(y * 0.012, bx * 0.012, sd + 3) * rad * 0.05 * t
			row.append(Vector3(x, y, z))
		grid.append(row)
	var cols: Array = []
	for r in rings + 1:
		var crow: Array = []
		for k in segs:
			var v: Vector3 = grid[r][k]
			var vn: Vector3 = grid[mini(r + 1, rings)][k]
			var dh := absf(v.y - vn.y)
			var dxz := Vector2(v.x - vn.x, v.z - vn.z).length() + 0.01
			var slope := dh / dxz
			var e := clampf(v.y / 150.0, 0.0, 1.2) + noise.get_noise_3d(v.x * 0.018, v.y * 0.027, v.z * 0.018 + sd + 7) * 0.2
			var c := _pal_col(e, noise.get_noise_3d(v.x * 0.036, v.z * 0.036, sd + 7), noise.get_noise_3d(v.x * 0.06, v.y * 0.06, v.z * 0.06 + sd + 13))
			var pal: Dictionary = W.pal
			var rk := _sm(0.9, 1.8, slope)
			var rc: Color = pal.rock.lerp(pal.rock2, noise.get_noise_3d(v.x * 0.08, v.y * 0.08, v.z * 0.08) * 0.5 + 0.5)
			rc *= 0.84 + 0.16 * sin(v.y * 0.7 + noise.get_noise_2d(v.x * 0.03, v.z * 0.03) * 2.0)
			c = c.lerp(rc, rk * 0.8)
			if pal.snow_on and e > 0.7:
				c = c.lerp(pal.snow, _sm(0.72, 0.9, e) * (1.0 - _sm(1.2, 2.2, slope)))
			crow.append(c)
		cols.append(crow)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in rings:
		for k in segs:
			var k2 := (k + 1) % segs
			for q in [[r, k], [r + 1, k], [r, k2], [r, k2], [r + 1, k], [r + 1, k2]]:
				st.set_color(cols[q[0]][q[1]])
				st.add_vertex(grid[q[0]][q[1]])
	st.generate_normals()
	return st.commit()

var mount_meshes: Array = []
func _add_mountain(sv: float) -> void:
	if W.has("city"):
		_add_building(sv)
		return
	if mount_meshes.is_empty():
		for i in 6:
			mount_meshes.append(_mountain_mesh(100.0, 120.0 + i * 12.0, i * 17 + 3))
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var rad := rng.randf_range(55.0, 140.0)
	var x := side * (BX + 30.0 + rad * 0.85 + rng.randf_range(0.0, 120.0))
	var m := MeshInstance3D.new()
	m.mesh = mount_meshes[rng.randi() % mount_meshes.size()]
	m.material_override = mount_mat
	add_child(m)
	place(m, sv, x, GY + ground_h(x, sv) - 6.0)
	m.rotate_object_local(Vector3.UP, rng.randf() * TAU)
	var hs := rng.randf_range(0.45, 1.2)
	m.scale = Vector3(rad / 100.0, hs * rad / 100.0 + 0.25, rad / 100.0)
	rocks.append({"node": m, "s": sv + rad, "x": x, "y": 0.0, "r": rad, "hard": false, "big": true})
	# Geröllhalde am Fuß des Berges
	for i in 5:
		var a := rng.randf() * TAU
		var bx := x + cos(a) * rad * rng.randf_range(0.75, 1.0)
		var bs := sv + sin(a) * rad * rng.randf_range(0.75, 1.0)
		if absf(bx) < BX + 10.0:
			continue
		var b := MeshInstance3D.new()
		b.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
		b.material_override = rock_mat
		add_child(b)
		var r2 := rng.randf_range(3.0, 9.0)
		place(b, bs, bx, GY + ground_h(bx, bs) + r2 * 0.2)
		b.rotate_object_local(Vector3.UP, rng.randf() * TAU)
		b.scale = Vector3(r2, r2 * rng.randf_range(0.6, 1.0), r2) * 0.5
		rocks.append({"node": b, "s": bs, "x": bx, "y": 0.0, "r": r2, "hard": false, "still": true})

func dist_ok(x: float, y: float) -> bool:
	return absf(x) > BX + 6.0 or absf(y) > BY + 6.0

func _add_crystal_cluster(sv: float, x: float, y: float, r: float) -> void:
	var g := Node3D.new()
	add_child(g)
	place(g, sv, x, y)
	g.rotate_object_local(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized(), rng.randf() * TAU)
	var base := MeshInstance3D.new()
	base.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
	base.material_override = rock_mat
	base.scale = Vector3.ONE * r * 0.35
	g.add_child(base)
	for i in 3 + rng.randi() % 4:
		var c := MeshInstance3D.new()
		c.mesh = crystal_mesh
		c.material_override = crystal_mat
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1), rng.randf_range(-1, 1)).normalized()
		var side := d.cross(Vector3(0.31, 0.2, 0.93)).normalized()
		c.basis = Basis(side, d, side.cross(d)).scaled(Vector3.ONE * r * rng.randf_range(0.18, 0.4))
		c.position = d * r * 0.35
		g.add_child(c)
	rocks.append({"node": g, "s": sv, "x": x, "y": y, "r": r, "hard": false, "still": true})

func _add_mushroom(sv: float, x: float, big: bool) -> void:
	var g := Node3D.new()
	add_child(g)
	var h := rng.randf_range(10.0, 26.0) if big else rng.randf_range(2.0, 6.0)
	var cr := h * rng.randf_range(0.35, 0.55)
	place(g, sv, x, GY + ground_h(x, sv) - 0.5)
	g.rotate_object_local(Vector3.FORWARD, rng.randf_range(-0.2, 0.2))
	var stem := CylinderMesh.new()
	stem.top_radius = cr * 0.16
	stem.bottom_radius = cr * 0.26
	stem.height = h
	stem.radial_segments = 10
	g.add_child(_mi(stem, mush_stem, Vector3(0, h * 0.5, 0)))
	var cap := SphereMesh.new()
	cap.radius = cr
	cap.height = cr * 2.0
	cap.radial_segments = 16
	cap.rings = 8
	cap.is_hemisphere = true
	g.add_child(_mi(cap, mush_cap, Vector3(0, h * 0.95, 0), Vector3(1, 0.55, 1)))
	rocks.append({"node": g, "s": sv, "x": x, "y": 0.0, "r": cr, "hard": false, "still": true})

func _add_ground_rock(sv: float) -> void:
	if W.has("city"):
		return
	if W.has("mush") and rng.randf() < W.mush:
		var big := rng.randf() < 0.35
		var mx := rng.randf_range(BX + 8.0, 140.0) if big else rng.randf_range(BX + 3.0, 90.0)
		_add_mushroom(sv, mx * (-1.0 if rng.randf() < 0.5 else 1.0), big)
		return
	if W.has("stacks") and rng.randf() < W.stacks * 0.25:
		_add_stack(sv)
		return
	var near := rng.randf() < 0.22
	var x := rng.randf_range(-BX - 4.0, BX + 4.0) if near else (rng.randf_range(BX + 6.0, 120.0) * (-1.0 if rng.randf() < 0.5 else 1.0))
	var r := rng.randf_range(1.6, 3.4) if near else rng.randf_range(2.5, 9.0)
	var m := MeshInstance3D.new()
	m.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
	m.material_override = rock_mat
	add_child(m)
	var gy := GY + ground_h(x, sv)
	var tall := 1.0
	if near:
		tall = rng.randf_range(2.2, 4.2)
	place(m, sv, x, gy + r * 0.35 * tall)
	m.rotate_object_local(Vector3.UP, rng.randf() * TAU)
	m.scale = Vector3(r * 0.5, r * 0.5 * tall, r * 0.5)
	var d := {"node": m, "s": sv, "x": x, "y": gy, "r": r, "hard": false, "still": true}
	if near:
		d["top"] = gy + r * 0.6 * tall + r * 0.3
	rocks.append(d)

func _add_stack(sv: float) -> void:
	var inside := rng.randf() < 0.3
	var x := rng.randf_range(-BX + 2.0, BX - 2.0) if inside else rng.randf_range(BX + 10.0, 150.0) * (-1.0 if rng.randf() < 0.5 else 1.0)
	var r := rng.randf_range(4.0, 7.0) if inside else rng.randf_range(8.0, 22.0)
	var tall := rng.randf_range(4.0, 7.0)
	var m := MeshInstance3D.new()
	m.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
	m.material_override = rock_mat
	add_child(m)
	var gy := GY + ground_h(x, sv) - 3.0
	place(m, sv, x, gy + r * 0.45 * tall)
	m.rotate_object_local(Vector3.UP, rng.randf() * TAU)
	m.scale = Vector3(r * 0.5, r * 0.5 * tall, r * 0.5)
	var d := {"node": m, "s": sv, "x": x, "y": gy, "r": r, "hard": false, "still": true}
	if inside:
		d["top"] = 99.0
	rocks.append(d)

# ======================= Sonderdeko der Welten =======================
func _box(sz: Vector3, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = sz
	return _mi(b, mat, pos, Vector3.ONE, rot)

func _add_wreck(sv: float, x: float, y: float) -> void:
	var g := Node3D.new()
	add_child(g)
	place(g, sv, x, y)
	g.rotate_object_local(Vector3(rng.randf(), rng.randf(), rng.randf()).normalized(), rng.randf() * TAU)
	var L := rng.randf_range(40.0, 110.0)
	var Wd := L * rng.randf_range(0.16, 0.24)
	# Rumpf mit abgerissenem Heck: vorderer Teil geschlossen, hinten nur Spanten
	g.add_child(_box(Vector3(Wd, Wd * 0.45, L * 0.55), metal_mat, Vector3(0, 0, -L * 0.2)))
	g.add_child(_box(Vector3(Wd * 0.6, Wd * 0.3, L * 0.25), metal_mat, Vector3(0, Wd * 0.3, -L * 0.35)))
	var pm := PrismMesh.new()
	pm.size = Vector3(Wd, L * 0.3, Wd * 0.45)
	g.add_child(_mi(pm, metal_mat, Vector3(0, 0, -L * 0.62), Vector3.ONE, Vector3(-PI / 2, 0, 0)))
	for i in 6:
		var z := L * 0.1 + i * L * 0.06
		g.add_child(_box(Vector3(Wd * 1.02, Wd * 0.06, Wd * 0.05), metal_mat, Vector3(0, Wd * 0.2, z), Vector3(0, 0, rng.randf_range(-0.2, 0.2))))
		g.add_child(_box(Vector3(Wd * 0.06, Wd * 0.45, Wd * 0.05), metal_mat, Vector3(-Wd * 0.48, 0, z)))
		if rng.randf() < 0.6:
			g.add_child(_box(Vector3(Wd * 0.06, Wd * 0.45, Wd * 0.05), metal_mat, Vector3(Wd * 0.48, 0, z)))
	g.add_child(_box(Vector3(Wd * 0.95, Wd * 0.04, L * 0.38), metal_mat, Vector3(0, -Wd * 0.21, L * 0.24)))
	for i in 4:
		var lm := _box(Vector3.ONE * 0.6, glow_red, Vector3(rng.randf_range(-0.5, 0.5) * Wd, Wd * 0.24, rng.randf_range(-0.45, 0.05) * L))
		g.add_child(lm)
	rocks.append({"node": g, "s": sv, "x": x, "y": y, "r": L, "hard": false, "big": true})

func _add_module(sv: float, x: float, y: float) -> void:
	var g := Node3D.new()
	add_child(g)
	place(g, sv, x, y)
	g.rotate_object_local(Vector3.UP, rng.randf_range(-0.4, 0.4))
	var n := 2 + rng.randi() % 3
	var rad := rng.randf_range(5.0, 9.0)
	for i in n:
		var c := CylinderMesh.new()
		c.top_radius = rad
		c.bottom_radius = rad
		c.height = rad * 3.5
		c.radial_segments = 16
		var z := (i - n * 0.5) * rad * 4.2
		g.add_child(_mi(c, metal_mat, Vector3(0, 0, z), Vector3.ONE, Vector3(PI / 2, 0, 0)))
		var ring := TorusMesh.new()
		ring.inner_radius = rad * 1.02
		ring.outer_radius = rad * 1.25
		g.add_child(_mi(ring, metal_mat, Vector3(0, 0, z + rad * 1.6), Vector3.ONE, Vector3(PI / 2, 0, 0)))
		g.add_child(_box(Vector3(rad * 0.15, rad * 0.15, rad * 0.8), neon_mats[2], Vector3(0, rad * 1.0, z)))
		if i < n - 1:
			g.add_child(_box(Vector3(rad * 0.8, rad * 0.8, rad * 1.4), metal_mat, Vector3(0, 0, z + rad * 2.1)))
	var sx := 1.0 if x > 0 else -1.0
	g.add_child(_box(Vector3(rad * 9.0, 0.4, rad * 2.6), panel_mat, Vector3(sx * rad * 5.5, 0, 0)))
	g.add_child(_box(Vector3(rad * 9.0, 0.4, rad * 2.6), panel_mat, Vector3(sx * rad * 5.5, 0, rad * 3.0)))
	g.add_child(_box(Vector3(rad * 10.0, 0.6, 0.6), metal_mat, Vector3(sx * rad * 5.5, 0, rad * 1.5)))
	rocks.append({"node": g, "s": sv, "x": x, "y": y, "r": rad * n * 4.0, "hard": false, "big": true})

func _add_building(sv: float) -> void:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var w := rng.randf_range(16.0, 40.0)
	var h := rng.randf_range(40.0, 190.0)
	var x := side * (BX + 16.0 + w * 0.5 + (rng.randf_range(0.0, 30.0) if rng.randf() < 0.55 else rng.randf_range(30.0, 200.0)))
	if _near_tunnel(sv, 40.0) and absf(x) < 110.0:
		return
	var g := Node3D.new()
	add_child(g)
	place(g, sv, x, GY + ground_h(x, sv) - 2.0)
	var dz0 := w
	g.add_child(_box(Vector3(w, h, dz0), city_mat, Vector3(0, h * 0.5, 0)))
	if rng.randf() < 0.6:
		g.add_child(_box(Vector3(w * 0.6, h * 0.25, w * 0.6), city_mat, Vector3(0, h * 1.12, 0)))
	var dz := dz0
	var floors := int(h / 4.5)
	var wm: Material = neon_mats[0]
	for f in floors:
		if rng.randf() < 0.45:
			var len_f := w * rng.randf_range(0.25, 0.9)
			var off := rng.randf_range(-(w - len_f) * 0.5, (w - len_f) * 0.5)
			var fy := 3.0 + f * 4.5
			g.add_child(_box(Vector3(len_f, 1.4, 0.3), wm, Vector3(off, fy, dz * 0.5 + 0.1)))
			if rng.randf() < 0.5:
				g.add_child(_box(Vector3(0.3, 1.4, len_f * dz / w), wm, Vector3(-signf(x) * (w * 0.5 + 0.1), fy, off * dz / w)))
	var nm: Material = neon_mats[1 + rng.randi() % (neon_mats.size() - 1)]
	for k in 1 + rng.randi() % 3:
		g.add_child(_box(Vector3(w * 1.02, 0.7, 0.7), nm, Vector3(0, h * rng.randf_range(0.3, 0.98), w * 0.5)))
	g.add_child(_box(Vector3(0.6, h * 0.12, 0.6), glow_red, Vector3(0, h + h * 0.06, 0)))
	rocks.append({"node": g, "s": sv, "x": x, "y": 0.0, "r": w, "hard": false, "big": true})

func _update_storm(dt: float) -> void:
	storm_t -= dt
	flash = maxf(0.0, flash - dt * 3.0)
	sun.light_energy = sun_energy + flash * 2.5
	if storm_t <= 0.0:
		storm_t = rng.randf_range(1.5, 4.5)
		flash = 1.0
		var sv := s + rng.randf_range(150.0, 400.0)
		var x := rng.randf_range(60.0, 220.0) * (-1.0 if rng.randf() < 0.5 else 1.0)
		var y := rng.randf_range(-40.0, 80.0)
		var p := l2w(sv, x, y + 90.0)
		var bolt := Node3D.new()
		add_child(bolt)
		var mat := _glow(Color(0.7, 1.0, 0.95), 5.0)
		var pts := [p]
		for i in 9:
			var q: Vector3 = pts[-1] + Vector3(rng.randf_range(-12, 12), -20.0, rng.randf_range(-12, 12))
			pts.append(q)
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var seg := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.9, 0.9, a.distance_to(b))
			seg.mesh = bm
			seg.material_override = mat
			bolt.add_child(seg)
			seg.look_at_from_position((a + b) * 0.5, b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
		get_tree().create_timer(0.22).timeout.connect(bolt.queue_free)

# ======================= Neonstadt: Straße, Megablock-Tunnel, Verkehr =======================
func _ribbon(st: SurfaceTool, sa: float, sb: float, x0: float, x1: float, y: float, col: Color, step := 4.0) -> void:
	var sv := sa
	while sv < sb - 0.01:
		var se := minf(sb, sv + step)
		var fa := frame(sv)
		var fb := frame(se)
		var p1 := fa.origin + fa.basis.x * x0 + fa.basis.y * y
		var p2 := fa.origin + fa.basis.x * x1 + fa.basis.y * y
		var p3 := fb.origin + fb.basis.x * x0 + fb.basis.y * y
		var p4 := fb.origin + fb.basis.x * x1 + fb.basis.y * y
		for v in [p1, p3, p2, p2, p3, p4]:
			st.set_color(col)
			st.add_vertex(v)
		sv = se

func _wall_ribbon(st: SurfaceTool, sa: float, sb: float, x: float, y0: float, y1: float, col: Color) -> void:
	var sv := sa
	while sv < sb - 0.01:
		var se := minf(sb, sv + 4.0)
		var fa := frame(sv)
		var fb := frame(se)
		var p1 := fa.origin + fa.basis.x * x + fa.basis.y * y0
		var p2 := fa.origin + fa.basis.x * x + fa.basis.y * y1
		var p3 := fb.origin + fb.basis.x * x + fb.basis.y * y0
		var p4 := fb.origin + fb.basis.x * x + fb.basis.y * y1
		for v in [p1, p3, p2, p2, p3, p4]:
			st.set_color(col)
			st.add_vertex(v)
		sv = se

func _street_lines(sa: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Neon-Gitter wie in der HTML-Version: Längslinien alle 14 m, Querlinien
	var y := GY + 0.08
	var gc := Color(1.0, 0.19, 0.75)
	for k in range(-6, 7):
		_ribbon(st, sa, sa + CHUNK, k * 14.0 - 0.09, k * 14.0 + 0.09, y, gc, 6.0)
	for q in [0.0, CHUNK * 0.5]:
		_ribbon(st, sa + q, sa + q + 0.18, -84.0, 84.0, y, gc, 0.18)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = line_mat
	add_child(m)
	return m

func _add_city_tunnel(s0: float, tl: float) -> void:
	var s1 := s0 + tl
	var nodes: Array = []
	var OX := rng.randf_range(80.0, 110.0)
	var OY1 := rng.randf_range(70.0, 130.0)
	var OY0 := GY - 3.0
	# Innenröhre (eckig), Außenblock und Fassaden – mit festen Normalen
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces_in := [[Vector2(-TIX, TIY0), Vector2(TIX, TIY0), Vector2.UP], [Vector2(TIX, TIY0), Vector2(TIX, TIY1), Vector2.LEFT],
		[Vector2(TIX, TIY1), Vector2(-TIX, TIY1), Vector2.DOWN], [Vector2(-TIX, TIY1), Vector2(-TIX, TIY0), Vector2.RIGHT]]
	var faces_out := [[Vector2(OX, OY0), Vector2(OX, OY1), Vector2.RIGHT], [Vector2(OX, OY1), Vector2(-OX, OY1), Vector2.UP], [Vector2(-OX, OY1), Vector2(-OX, OY0), Vector2.LEFT]]
	var sv := s0
	while sv < s1 - 0.01:
		var se := minf(s1, sv + 4.0)
		var fa := frame(sv)
		var fb := frame(se)
		for f in faces_in + faces_out:
			var a: Vector2 = f[0]
			var b: Vector2 = f[1]
			var n2: Vector2 = f[2]
			var nn := (fa.basis.x * n2.x + fa.basis.y * n2.y).normalized()
			var p1 := fa.origin + fa.basis.x * a.x + fa.basis.y * a.y
			var p2 := fa.origin + fa.basis.x * b.x + fa.basis.y * b.y
			var p3 := fb.origin + fb.basis.x * a.x + fb.basis.y * a.y
			var p4 := fb.origin + fb.basis.x * b.x + fb.basis.y * b.y
			for v in [p1, p3, p2, p2, p3, p4]:
				st.set_normal(nn)
				st.add_vertex(v)
		sv = se
	# Fassaden an beiden Enden: Ring zwischen Öffnung und Außenkante
	for end in [[s0, 1.0], [s1, -1.0]]:
		var fr := frame(end[0])
		var nf: Vector3 = fr.basis.z * end[1]
		var inner := [Vector2(-TIX, TIY0), Vector2(TIX, TIY0), Vector2(TIX, TIY1), Vector2(-TIX, TIY1)]
		var outer := [Vector2(-OX, OY0), Vector2(OX, OY0), Vector2(OX, OY1), Vector2(-OX, OY1)]
		for k in 4:
			var k2 := (k + 1) % 4
			var q := [inner[k], inner[k2], outer[k], outer[k2]]
			var pts: Array = []
			for v2 in q:
				pts.append(fr.origin + fr.basis.x * v2.x + fr.basis.y * v2.y)
			for idx in [0, 2, 1, 1, 2, 3]:
				st.set_normal(nf)
				st.add_vertex(pts[idx])
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = block_mat
	add_child(m)
	nodes.append(m)
	# Neonbänder innen + Fensterbänder außen
	var nl := SurfaceTool.new()
	nl.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pk := Color(1.0, 0.2, 0.75)
	var cy := Color(0.2, 0.9, 1.0)
	_wall_ribbon(nl, s0, s1, TIX - 0.05, TIY0 + 4.0, TIY0 + 4.5, cy)
	_wall_ribbon(nl, s0, s1, -TIX + 0.05, TIY0 + 4.0, TIY0 + 4.5, cy)
	_wall_ribbon(nl, s0, s1, TIX - 0.05, TIY1 - 2.0, TIY1 - 1.6, pk)
	_wall_ribbon(nl, s0, s1, -TIX + 0.05, TIY1 - 2.0, TIY1 - 1.6, pk)
	_ribbon(nl, s0, s1, -0.4, 0.4, TIY1 - 0.05, Color(0.9, 0.9, 1.0) * 0.7)
	var d := s0
	while d < s1:
		_ribbon(nl, d, d + 3.0, -0.25, 0.25, TIY0 + 0.05, Color(1.0, 0.8, 0.3) * 0.6)
		d += 9.0
	var fy := 8.0
	while fy < OY1 - 6.0:
		if rng.randf() < 0.55:
			var a0 := rng.randf_range(s0, s1 - 30.0)
			_wall_ribbon(nl, a0, minf(s1, a0 + rng.randf_range(15.0, 80.0)), OX + 0.1, GY + fy, GY + fy + 1.3, Color(1.0, 0.82, 0.55) * 0.55)
			var b0 := rng.randf_range(s0, s1 - 30.0)
			_wall_ribbon(nl, b0, minf(s1, b0 + rng.randf_range(15.0, 80.0)), -OX - 0.1, GY + fy, GY + fy + 1.3, Color(1.0, 0.82, 0.55) * 0.55)
		fy += 5.0
	var lm := MeshInstance3D.new()
	lm.mesh = nl.commit()
	lm.material_override = line_mat
	add_child(lm)
	nodes.append(lm)
	# Leuchtrahmen um die Einfahrt + Fassadenleuchtschrift-Balken
	var gx := TIX + 0.8
	var fr0 := Node3D.new()
	add_child(fr0)
	place(fr0, s0 - 0.3, 0, 0)
	fr0.add_child(_box(Vector3(gx * 2.0, 0.8, 0.4), neon_mats[1], Vector3(0, TIY1 + 0.6, 0)))
	fr0.add_child(_box(Vector3(0.8, TIY1 - TIY0, 0.4), neon_mats[1], Vector3(-gx, (TIY1 + TIY0) * 0.5, 0)))
	fr0.add_child(_box(Vector3(0.8, TIY1 - TIY0, 0.4), neon_mats[1], Vector3(gx, (TIY1 + TIY0) * 0.5, 0)))
	for i in 5:
		var bw := rng.randf_range(10.0, 34.0)
		fr0.add_child(_box(Vector3(bw, rng.randf_range(2.0, 5.0), 0.4), neon_mats[1 + rng.randi() % 3], Vector3(rng.randf_range(-OX + bw, OX - bw) * 0.9, rng.randf_range(TIY1 + 6.0, OY1 - 8.0), 0)))
	for i in 10:
		fr0.add_child(_box(Vector3(rng.randf_range(8.0, 30.0), 1.3, 0.3), neon_mats[0], Vector3(rng.randf_range(-OX + 15.0, OX - 15.0), rng.randf_range(TIY1 + 4.0, OY1 - 4.0), 0.1)))
	nodes.append(fr0)
	# Lichter im Tunnel
	var ls := s0 + 12.0
	var li := 0
	while ls < s1 - 6.0:
		var ol := OmniLight3D.new()
		ol.light_color = cy if li % 2 == 0 else pk
		ol.light_energy = 2.0
		ol.omni_range = 26.0
		add_child(ol)
		ol.global_position = l2w(ls, 0.0, TIY1 - 3.0)
		nodes.append(ol)
		ls += 26.0
		li += 1
	tunnels.append({"s0": s0, "s1": s1, "nodes": nodes, "told": false})

func _make_car(oncoming: bool) -> Node3D:
	var g := Node3D.new()
	var body: Material = car_mats[rng.randi() % car_mats.size()]
	g.add_child(_box(Vector3(3.0, 0.9, 6.2), body, Vector3.ZERO))
	g.add_child(_box(Vector3(2.5, 0.75, 3.0), ship_dark, Vector3(0, 0.78, 0.5)))
	g.add_child(_box(Vector3(3.3, 0.25, 1.2), body, Vector3(0, 0.05, 2.9)))
	for sx in [-1.0, 1.0]:
		g.add_child(_box(Vector3(0.7, 0.28, 0.12), head_mat, Vector3(sx * 1.0, 0.1, -3.12)))
		g.add_child(_box(Vector3(0.8, 0.22, 0.12), glow_red, Vector3(sx * 1.0, 0.15, 3.12)))
	g.add_child(_box(Vector3(2.6, 0.1, 5.4), neon_mats[1 + rng.randi() % 3], Vector3(0, -0.5, 0)))
	add_child(g)
	return g

func _update_cars(dt: float) -> void:
	while next_car_s < s + 300.0:
		var sv := next_car_s
		var in_t := not _in_tunnel(sv).is_empty()
		next_car_s += rng.randf_range(6.0, 11.0) if in_t else rng.randf_range(14.0, 26.0)
		if rng.randf() < (0.8 if in_t else 0.5):
			var lane := rng.randi() % 4
			var lx: float = [-10.5, -3.5, 3.5, 10.5][lane]
			var ly: float = [-8.5, -2.5, 3.5, 9.5][rng.randi() % 4] if in_t else rng.randf_range(-6.0, BY)
			var onc := lane < 2
			var n := _make_car(onc)
			cars.append({"node": n, "s": sv, "x": lx, "y": ly, "v": -26.0 if onc else 16.0, "onc": onc, "hp": 2.0, "bob": rng.randf() * TAU})
	for i in range(cars.size() - 1, -1, -1):
		var c: Dictionary = cars[i]
		c.s += c.v * dt
		c.bob += dt * 2.0
		place(c.node, c.s, c.x, c.y + sin(c.bob) * 0.15)
		if c.onc:
			c.node.rotate_object_local(Vector3.UP, PI)
		var ds: float = c.s - s
		var gone := ds < -20.0
		if absf(ds) < 3.4 and absf(c.x - ship_x) < 2.5 and absf(c.y - ship_y) < 1.6:
			damage(20.0)
			c.hp = 0.0
		if c.hp <= 0.0:
			_explode(l2w(c.s, c.x, c.y), Color(1.0, 0.5, 0.2), 1.4)
			score += 50
			gone = true
		if gone:
			c.node.queue_free()
			cars.remove_at(i)

# ======================= Updates =======================
func _update_rocks(dt: float) -> void:
	for i in range(rocks.size() - 1, -1, -1):
		var r: Dictionary = rocks[i]
		if r.s < s - 30.0 - (r.r if r.has("big") else 0.0):
			r.node.queue_free()
			rocks.remove_at(i)
			continue
		if not r.has("still") and not r.has("big"):
			r.node.rotate_object_local(Vector3(0.3, 1, 0.2).normalized(), dt * 0.3)
		var hit_ship := false
		if r.has("top"):
			hit_ship = absf(r.s - s) < r.r * 0.7 and absf(r.x - ship_x) < r.r * 0.75 + 0.8 and ship_y < r.top
		elif r.hard:
			hit_ship = absf(r.s - s) < r.r and Vector2(r.x - ship_x, r.y - ship_y).length() < r.r * 0.8 + 1.0
		if hit_ship:
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
			for c in cars:
				if absf(c.s - b.s) < 3.5 and absf(c.x - b.x) < 1.9 and absf(c.y - b.y) < 1.3:
					c.hp -= 1.0
					hit = true
					break
		if not hit:
			for r in rocks:
				if r.has("top"):
					if absf(r.s - b.s) < r.r * 0.7 and absf(r.x - b.x) < r.r * 0.75 and b.y < r.top:
						hit = true
						break
				elif r.hard and absf(r.s - b.s) < r.r and Vector2(r.x - b.x, r.y - b.y).length() < r.r:
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
		if b.s < s - 1.5:
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
	var sh: float = game.trauma * game.trauma
	if sh > 0.0:
		cam.global_position += tr.basis.y * rng.randf_range(-1, 1) * sh * 0.7
		cam.rotate_object_local(Vector3.FORWARD, rng.randf_range(-1, 1) * sh * 0.03)

func _update_hud(dt: float) -> void:
	hud_score.text = "%08d" % game.score
	hud_hull.value = hull
	hud_shield.value = shield
	hud_info.text = "FPS %d  ·  Objekte %d  ·  Gegner %d" % [int(Engine.get_frames_per_second()), rocks.size(), game.enemies.size()]
	if msg_t > 0.0:
		msg_t -= dt
		hud_msg.modulate.a = clampf(msg_t, 0.0, 1.0)

# ======================= Testpilot =======================
func log_at(t: String) -> void:
	at_log.append("[%6.2fs] %s" % [t_game, t])
	print("AUTOTEST: ", t)

func _autotest_step(dt: float) -> void:
	at_frames += 1
	if absf(t_game - 8.0) < dt * 0.5:
		game.fire_missiles()
		log_at("Raketen abgefeuert")
	if absf(t_game - 14.0) < dt * 0.5:
		game.do_roll()
	if absf(t_game - 20.0) < dt * 0.5:
		game.fire_nuke()
		log_at("Atombombe gezündet")
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
	if t_game > 26.0 or Time.get_ticks_msec() > 330000:
		log_at("Spiel: Welle %d, Punkte %d, Gegner aktiv %d, Schüsse %d" % [game.wave, game.score, game.enemies.size(), game.ebullets.size()])
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

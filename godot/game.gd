extends Node
## Kampfsystem – Port aus der HTML-Version (Gegner, Wellen, Waffen, Power-ups, Effekte)
## Koordinaten wie im HTML: x/y quer zur Bahn, z relativ zum Spieler (negativ = vor dir).

var M  # main.gd
const BX := 15.0
const BY := 10.0

var time := 0.0
var wave := 0
var wave_clock := 0.0
var queue: Array = []
var inter_wave := 0.0
var idle_t := 0.0
var stall_t := 0.0
var enemies: Array = []
var ebullets: Array = []
var pbullets: Array = []
var missiles: Array = []
var pickups: Array = []
var fxs: Array = []
var timers: Array = []
var seen := {}

var score := 0
var mult := 1
var chain := 0
var mult_t := 0.0
var wpn := ""
var wlv := 0
var wdmg := 0.0
var nmis := 6
var mis_regen := 0.0
var mis_cd := 0.0
var nukes := 1
var bubble := 0.0
var invul := 0.0
var roll_t := 0.0
var roll_cd := 0.0
var roll_dir := 0.0
var fire_t := 0.0
var gun := 0
var state := "play"
var trauma := 0.0
var lock = null
var boss = null
var boss_count := 0

const ROLL := 0.55
var rng := RandomNumberGenerator.new()

# ---------- Materialien / Formen ----------
var mats := {}
var shapes := {}
var glow_tex: Texture2D
var ring_tex: Texture2D
var glow_mats := {}

# ---------- HUD ----------
var hud: CanvasLayer
var l_wave: Label
var l_mult: Label
var l_banner: Label
var l_banner2: Label
var banner_t := 0.0
var l_toast: Label
var toast_t := 0.0
var b_mis: Button
var b_nuke: Button
var b_roll: Button
var lock_mk: Label
var over_panel: Panel

func setup(main) -> void:
	M = main
	rng.seed = 4711
	_make_assets()
	_make_hud()
	wave = M.start_wave - 1
	start_wave()

func rand(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func pick(arr: Array):
	return arr[rng.randi() % arr.size()]

func later(t: float, f: Callable) -> void:
	timers.append({"t": t, "f": f})

func diff() -> float:
	return 1.0 + wave * 0.07

func bullet_speed() -> float:
	return minf(80.0, 44.0 + wave * 2.2)

# ======================= Assets im ARC-Stil (glänzendes Metall, Leuchtteile) =======================
func pbr(col: Color, metal: float, rough: float, emis := Color.BLACK, ee := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	m.metallic_specular = 0.7
	# Cel-Shading beibehalten: Toon-Licht + Umrisslinie
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.3
	m.rim_tint = 0.5
	if M != null and M.outline_mat != null:
		m.next_pass = M.outline_mat
	if ee > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = ee
	return m

func bm(col: Color, e := 2.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = e
	return m

func _make_assets() -> void:
	mats.eHull = pbr(Color(0.28, 0.29, 0.32), 0.85, 0.3)
	mats.eDark = pbr(Color(0.08, 0.08, 0.1), 0.7, 0.45)
	mats.eRed = pbr(Color(0.75, 0.08, 0.1), 0.6, 0.3, Color(0.9, 0.1, 0.1), 0.6)
	mats.fGreen = pbr(Color(0.1, 0.7, 0.25), 0.6, 0.3, Color(0.1, 0.9, 0.3), 0.6)
	mats.glass = pbr(Color(0.05, 0.12, 0.2), 0.9, 0.05, Color(0.3, 0.6, 1.0), 0.3)
	mats.iHull = pbr(Color(0.42, 0.36, 0.3), 0.8, 0.3)
	mats.iOr = bm(Color(1.0, 0.55, 0.1), 2.0)
	mats.hHull = pbr(Color(0.3, 0.22, 0.4), 0.8, 0.3)
	mats.hGlow = bm(Color(0.76, 0.36, 1.0), 2.5)
	mats.flameO = bm(Color(1.0, 0.5, 0.15), 3.0)
	mats.flameG = bm(Color(0.3, 1.0, 0.45), 3.0)
	mats.missile = pbr(Color(0.85, 0.85, 0.88), 0.7, 0.25)
	mats.bossDark = pbr(Color(0.12, 0.12, 0.15), 0.8, 0.35)
	mats.bossLit = pbr(Color(0.2, 0.2, 0.24), 0.8, 0.3, Color(1.0, 0.8, 0.5), 0.8)
	mats.white = bm(Color(1, 1, 1), 2.0)
	mats.eb = bm(Color(1.0, 0.15, 0.3), 3.0)
	mats.ebFlak = bm(Color(1.0, 0.6, 0.2), 3.0)
	mats.ebOrb = bm(Color(1.0, 0.85, 0.25), 3.0)
	mats.ebSnip = bm(Color(1.0, 0.1, 0.2), 4.0)
	mats.mine = pbr(Color(0.2, 0.2, 0.22), 0.8, 0.35)
	var box := BoxMesh.new()
	shapes.box = box
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 20
	sph.rings = 12
	shapes.sphere = sph
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 14
	shapes.cyl = cyl
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 10
	shapes.cone = cone
	var cone4 := CylinderMesh.new()
	cone4.top_radius = 0.0
	cone4.bottom_radius = 0.5
	cone4.height = 1.0
	cone4.radial_segments = 4
	shapes.cone4 = cone4
	shapes.octa = _octa()
	var dod := SphereMesh.new()
	dod.radius = 1.0
	dod.height = 2.0
	dod.radial_segments = 6
	dod.rings = 4
	shapes.dodec = dod
	var tor := TorusMesh.new()
	tor.inner_radius = 0.9
	tor.outer_radius = 1.1
	tor.rings = 32
	tor.ring_segments = 8
	shapes.ring = tor
	var fl := CylinderMesh.new()
	fl.top_radius = 0.5
	fl.bottom_radius = 0.0
	fl.height = 1.0
	fl.radial_segments = 12
	shapes.flame = fl
	var eb := SphereMesh.new()
	eb.radius = 0.4
	eb.height = 0.8
	eb.radial_segments = 10
	eb.rings = 6
	shapes.ebullet = eb
	var pb := BoxMesh.new()
	pb.size = Vector3(0.16, 0.16, 3.4)
	shapes.pbullet = pb
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	shapes.quad = q
	# Leucht-Textur (radial) und Ring-Textur
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(1, 1, 1, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	glow_tex = gt
	var g2 := Gradient.new()
	g2.offsets = PackedFloat32Array([0.0, 0.72, 0.86, 1.0])
	g2.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var rt := GradientTexture2D.new()
	rt.gradient = g2
	rt.fill = GradientTexture2D.FILL_RADIAL
	rt.fill_from = Vector2(0.5, 0.5)
	rt.fill_to = Vector2(1.0, 0.5)
	rt.width = 128
	rt.height = 128
	ring_tex = rt

func _octa() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var p := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var f := [[0, 2, 4], [2, 1, 4], [1, 3, 4], [3, 0, 4], [2, 0, 5], [1, 2, 5], [3, 1, 5], [0, 3, 5]]
	for tri in f:
		for i in [0, 2, 1]:
			st.add_vertex(p[tri[i]])
	st.generate_normals()
	return st.commit()

func glow_mat(col: Color, op := 0.8, ring := false) -> StandardMaterial3D:
	var key := "%s_%.2f_%s" % [col.to_html(), op, ring]
	if glow_mats.has(key):
		return glow_mats[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = ring_tex if ring else glow_tex
	m.albedo_color = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6, op)
	m.no_depth_test = false
	m.disable_fog = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow_mats[key] = m
	return m

func glow(col: Color, size: float, op := 0.8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = shapes.quad
	mi.material_override = glow_mat(col, op)
	mi.scale = Vector3.ONE * size
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

func mk(shape: String, mat: Material, sx := 1.0, sy := 1.0, sz := 1.0, x := 0.0, y := 0.0, z := 0.0, rx := 0.0, ry := 0.0, rz := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = shapes[shape]
	mi.material_override = mat
	mi.rotation_order = EULER_ORDER_XYZ
	mi.position = Vector3(x, y, z)
	mi.rotation = Vector3(rx, ry, rz)
	mi.scale = Vector3(sx, sy, sz)
	return mi

## Triebwerksflamme: zeigt von der Nase weg (Modelle blicken nach +z zum Spieler)
func flame(mat: Material, r: float, ln: float, x: float, y: float, z: float) -> MeshInstance3D:
	return mk("flame", mat, r, absf(ln), r, x, y, z, PI / 2 if ln < 0 else -PI / 2)

# ======================= Platzierung =======================
func w_of(x: float, y: float, z: float) -> Vector3:
	return M.l2w(M.s - z, x, y)

func place(n: Node3D, x: float, y: float, z: float, rot := Vector3.ZERO, sc := 1.0) -> void:
	var tr: Transform3D = M.frame(M.s - z)
	var b: Basis = tr.basis * Basis.from_euler(rot, EULER_ORDER_XYZ)
	n.global_transform = Transform3D(b.scaled(Vector3.ONE * sc) if sc != 1.0 else b, tr.origin + tr.basis.x * x + tr.basis.y * y)

# ======================= HUD =======================
func _lab(sz: int, pos: Vector2, w := 1280.0, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.position = pos
	l.size = Vector2(w, sz + 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(l)
	return l

func _btn(txt: String, pos: Vector2, sz: Vector2, f: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.12, 0.2, 0.55)
	sb.border_color = Color(0.4, 0.9, 1.0, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	var sp := sb.duplicate() as StyleBoxFlat
	sp.bg_color = Color(0.2, 0.5, 0.7, 0.7)
	b.add_theme_stylebox_override("pressed", sp)
	b.pressed.connect(f)
	hud.add_child(b)
	return b

func _make_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 2
	add_child(hud)
	l_wave = _lab(18, Vector2(0, 52), 1280.0, Color(0.6, 0.9, 1.0))
	l_mult = _lab(26, Vector2(940, 60), 320.0, Color(1.0, 0.85, 0.3))
	l_banner = _lab(46, Vector2(0, 170), 1280.0, Color(1.0, 0.95, 0.8))
	l_banner2 = _lab(22, Vector2(0, 232), 1280.0, Color(1.0, 0.75, 0.45))
	l_toast = _lab(24, Vector2(0, 560), 1280.0, Color(1.0, 0.8, 0.5))
	lock_mk = _lab(40, Vector2.ZERO, 60.0, Color(0.3, 1.0, 0.4))
	lock_mk.text = "◎"
	b_mis = _btn("RAKETEN", Vector2(1080, 600), Vector2(180, 90), fire_missiles)
	b_nuke = _btn("☢", Vector2(1150, 500), Vector2(110, 80), fire_nuke)
	b_roll = _btn("ROLLE", Vector2(900, 620), Vector2(160, 70), do_roll)

func banner(a: String, b := "", _big := false) -> void:
	l_banner.text = a
	l_banner2.text = b
	banner_t = 2.6

func toast(t: String, col := Color(1.0, 0.8, 0.5)) -> void:
	l_toast.text = t
	l_toast.add_theme_color_override("font_color", col)
	toast_t = 2.2

func introduce(key: String, label: String) -> void:
	if seen.has(key):
		return
	seen[key] = true
	toast("NEU: " + label, Color(1.0, 0.82, 0.3))

# ======================= Gegner-Modelle =======================
func make_fighter(acc: Material) -> Node3D:
	var g := Node3D.new()
	var green: bool = acc == mats.fGreen
	g.add_child(mk("octa", mats.eHull, 0.9, 0.62, 1.6))
	g.add_child(mk("sphere", mats.glass, 0.32, 0.24, 0.45, 0, 0.42, 0.35))
	g.add_child(mk("box", mats.eDark, 0.5, 0.3, 1.2, 0, -0.35, -0.3))
	for s in [-1.0, 1.0]:
		g.add_child(mk("box", mats.eHull, 2.2, 0.1, 0.95, s * 1.4, 0, -0.25, 0, s * -0.35, s * 0.38))
		g.add_child(mk("box", mats.eDark, 1.2, 0.08, 0.6, s * 1.1, -0.25, -0.6, 0, 0, s * -0.2))
		g.add_child(mk("box", acc, 0.14, 0.55, 1.15, s * 2.35, 0.4, -0.55))
		g.add_child(mk("cyl", mats.eDark, 0.12, 1.2, 0.12, s * 0.55, -0.15, 1.1, PI / 2))
		g.add_child(mk("cyl", mats.eDark, 0.38, 0.7, 0.38, s * 0.38, 0, -1.35, PI / 2))
		g.add_child(flame(mats.flameG if green else mats.flameO, 0.32, -1.2, s * 0.38, 0, -2.0))
	g.add_child(mk("sphere", acc, 0.24, 0.2, 0.24, 0, 0.1, 1.3))
	var gl := glow(Color(0.35, 1.0, 0.48) if green else Color(1.0, 0.2, 0.33), 1.8, 0.8)
	gl.position = Vector3(0, 0.1, 1.35)
	g.add_child(gl)
	var eg := glow(Color(1.0, 0.42, 0.23), 1.6, 0.8)
	eg.position = Vector3(0, 0, -1.9)
	g.add_child(eg)
	return g

func make_interceptor() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("cone4", mats.iHull, 0.9, 3, 0.9, 0, 0, 0, PI / 2))
	g.add_child(mk("box", mats.eDark, 0.5, 0.5, 1.2, 0, 0, -1.1))
	for s in [-1.0, 1.0]:
		g.add_child(mk("box", mats.iHull, 1.5, 0.08, 0.9, s * 0.75, 0, -0.7, 0, s * 0.5))
		g.add_child(mk("box", mats.iOr, 0.1, 0.1, 0.7, s * 1.4, 0, -0.9))
		g.add_child(mk("box", mats.eDark, 0.06, 0.6, 0.7, 0, s * 0.4, -0.9))
	g.add_child(flame(mats.flameO, 0.5, -2.2, 0, 0, -2.6))
	var gl := glow(Color(1.0, 0.54, 0.12), 2.4, 0.9)
	gl.position = Vector3(0, 0, -1.8)
	g.add_child(gl)
	return g

func make_heavy() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("dodec", mats.hHull, 2.1, 2.1, 2.1))
	var r := mk("ring", mats.hGlow, 3.2, 3.2, 3.2)
	g.add_child(r)
	g.set_meta("ring", r)
	g.add_child(mk("ring", mats.eDark, 2.6, 2.6, 6, 0, 0, 0, PI / 2))
	for a in 4:
		var an := a * PI / 2 + 0.785
		g.add_child(mk("cone4", mats.hHull, 0.8, 2.4, 0.8, cos(an) * 2.5, sin(an) * 2.5, 0, 0, 0, an - PI / 2))
		g.add_child(mk("box", mats.eDark, 0.6, 0.6, 1.2, cos(an) * 1.6, sin(an) * 1.6, 1.6))
	g.add_child(mk("sphere", mats.hGlow, 0.6, 0.6, 0.6, 0, 0, 1.95))
	var gl := glow(Color(0.76, 0.36, 1.0), 4, 0.8)
	gl.position = Vector3(0, 0, 2.1)
	g.add_child(gl)
	return g

func make_bomber() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("box", mats.eHull, 4.4, 1.2, 3.4))
	g.add_child(mk("box", mats.eDark, 2.4, 0.9, 2.6, 0, 0.8, -0.3))
	g.add_child(mk("sphere", mats.glass, 0.5, 0.35, 0.7, 0, 1.2, 0.9))
	for s in [-1.0, 1.0]:
		g.add_child(mk("cyl", mats.eDark, 0.95, 2.8, 0.95, s * 2.7, -0.2, -0.3, PI / 2))
		g.add_child(flame(mats.flameO, 0.7, -1.8, s * 2.7, -0.2, -2.6))
		g.add_child(mk("box", mats.eHull, 1.8, 0.15, 2.2, s * 3.6, 0, 0.1))
		g.add_child(mk("box", mats.eRed, 0.12, 0.3, 1.8, s * 4.5, 0, 0.1))
	g.add_child(mk("sphere", bm(Color(1.0, 0.82, 0.25)), 0.55, 0.55, 0.55, 0, -0.8, 1.3))
	var gl := glow(Color(1.0, 0.82, 0.25), 2.4, 0.8)
	gl.position = Vector3(0, -0.8, 1.4)
	g.add_child(gl)
	return g

func make_sniper() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("box", mats.eHull, 0.9, 0.7, 5))
	g.add_child(mk("cyl", mats.eDark, 0.22, 4.2, 0.22, 0, 0, 4.4, PI / 2))
	for s in [-1.0, 1.0]:
		g.add_child(mk("box", mats.eDark, 2.4, 0.1, 1.2, s * 1.3, 0, -1.4, 0, s * -0.5))
	g.add_child(flame(mats.flameO, 0.4, -1.2, 0, 0, -3.2))
	var sc := glow(Color(1.0, 0.12, 0.2), 1.6, 1.0)
	sc.position = Vector3(0, 0.5, 1)
	g.add_child(sc)
	return g

func make_drone() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("octa", mats.eHull, 0.7, 0.45, 0.9))
	g.add_child(mk("box", mats.eDark, 1.8, 0.08, 0.4))
	var gl := glow(Color(0.48, 1.0, 0.75), 1.4, 0.9)
	gl.position.z = -0.6
	g.add_child(gl)
	return g

func make_brander() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("octa", mats.eDark, 1, 1, 1.7))
	for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var c := mk("cone", mats.eRed, 0.35, 1.4, 0.35, d.x, d.y, 0.3)
		var dir := Vector3(d.x, d.y, 0.4).normalized()
		var side := dir.cross(Vector3(0.3, 0.2, 1.0)).normalized()
		c.basis = Basis(side, dir, side.cross(dir)).scaled(Vector3(0.35, 1.4, 0.35))
		g.add_child(c)
	g.add_child(flame(mats.flameO, 0.8, -2.4, 0, 0, -2.8))
	var gl := glow(Color(1.0, 0.19, 0.06), 4, 0.8)
	g.add_child(gl)
	g.set_meta("gl", gl)
	return g

func make_shieldship() -> Node3D:
	var g := Node3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.8
	c.bottom_radius = 2.3
	c.height = 3.2
	c.radial_segments = 6
	var body := MeshInstance3D.new()
	body.mesh = c
	body.material_override = mats.eHull
	body.rotation.x = PI / 2
	g.add_child(body)
	g.add_child(mk("box", mats.eDark, 4.6, 0.5, 1.4, 0, 0, -0.6))
	g.add_child(mk("sphere", bm(Color(0.38, 0.85, 1.0)), 0.5, 0.5, 0.5, 0, 0, 1.7))
	var bubm := StandardMaterial3D.new()
	bubm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bubm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bubm.albedo_color = Color(0.25, 0.72, 1.0, 0.18)
	bubm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bub := mk("sphere", bubm, 3.4, 3.4, 3.4)
	g.add_child(bub)
	g.set_meta("bub", bub)
	g.add_child(flame(mats.flameO, 0.6, -1.4, 0, 0, -2.3))
	return g

func make_spinner() -> Node3D:
	var g := Node3D.new()
	var d := Node3D.new()
	d.add_child(mk("cyl", mats.eHull, 3.8, 0.6, 3.8, 0, 0, 0, PI / 2))
	d.add_child(mk("ring", bm(Color(1.0, 0.54, 0.16)), 1.95, 1.95, 3))
	for i in 4:
		var a := i * PI / 2
		d.add_child(mk("box", mats.eDark, 0.6, 0.6, 1, cos(a) * 1.9, sin(a) * 1.9, 0.3))
	g.add_child(d)
	g.set_meta("disc", d)
	g.add_child(mk("sphere", bm(Color(1.0, 0.54, 0.16)), 0.5, 0.5, 0.5, 0, 0, 0.4))
	g.add_child(glow(Color(1.0, 0.54, 0.16), 2.6, 0.7))
	return g

func make_mine() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("sphere", mats.mine, 0.9, 0.9, 0.9))
	for v in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]:
		var sp := mk("cone", mats.eDark, 0.3, 0.8, 0.3)
		var side := v.cross(Vector3(0.3, 0.5, 0.8)).normalized()
		sp.basis = Basis(side, v, side.cross(v)).scaled(Vector3(0.3, 0.8, 0.3))
		sp.position = v * 0.95
		g.add_child(sp)
	var l := glow(Color(1.0, 0.15, 0.1), 2.2, 1.0)
	g.add_child(l)
	g.set_meta("light", l)
	return g

func make_hmis() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("cyl", mats.missile, 0.3, 1.4, 0.3, 0, 0, 0, PI / 2))
	g.add_child(mk("cone", mats.eRed, 0.3, 0.5, 0.3, 0, 0, 0.9, PI / 2))
	g.add_child(glow(Color(1.0, 0.45, 0.15), 1.8, 0.9))
	return g

# ======================= Gegner anlegen =======================
func add_enemy(type: String, n: Node3D, props: Dictionary) -> Dictionary:
	var e := {"type": type, "node": n, "x": 0.0, "y": 0.0, "z": -340.0, "vx": 0.0, "vy": 0.0, "vz": 0.0, "rot": Vector3.ZERO,
		"hp": 1.0, "maxhp": 1.0, "radius": 1.5, "t": 0.0, "fire_t": rand(0.8, 2.0), "flash": 0.0, "alive": true, "score": 100,
		"collide": 20.0, "bs": 1.0, "env": false, "invul": false, "gone": false, "wp": Vector3.ZERO, "pwp": Vector3.ZERO, "wv": Vector3.ZERO, "state": "in"}
	for k in props:
		e[k] = props[k]
	M.add_child(n)
	enemies.append(e)
	return e

func spawn_fighter() -> Dictionary:
	var e := add_enemy("fighter", make_fighter(mats.eRed), {"hp": 3.0, "maxhp": 3.0, "radius": 1.9, "score": 100, "collide": 25.0})
	e.x0 = rand(-BX * 0.9, BX * 0.9)
	e.y0 = rand(-BY * 0.8, BY * 0.8)
	e.x = rand(-40, 40)
	e.y = rand(-25, 25)
	e.z = -340.0
	e.holdZ = rand(-26, -16) if rng.randf() < 0.45 else rand(-50, -28)
	e.holdTime = rand(5, 8)
	e.amp = rand(3, 7)
	e.freq = rand(0.5, 1.1)
	e.ph = rand(0, 6.28)
	return e

func spawn_flankers(n: int) -> void:
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var y := rand(-BY * 0.6, BY * 0.6)
	var z := rand(-34, -14)
	for i in n:
		var e := add_enemy("flanker", make_fighter(mats.eRed), {"hp": 2.0, "maxhp": 2.0, "radius": 1.8, "score": 120, "collide": 25.0})
		e.side = side
		e.x = side * (BX + 48 + i * 9)
		e.y = y + i * 2.5
		e.z = z - i * 4
		e.vx = -side * rand(26, 32)
		e.tz = z + rand(5, 15)
		e.shots = 2
		e.fire_t = rand(0.2, 0.6)
	toast("FEINDE VON RECHTS" if side > 0 else "FEINDE VON LINKS", Color(1.0, 0.6, 0.55))

func spawn_chasers(n: int) -> void:
	for i in n:
		var e := add_enemy("chaser", make_fighter(mats.fGreen), {"hp": 3.0, "maxhp": 3.0, "radius": 1.9, "score": 150, "collide": 25.0})
		var sx := -1.0 if rng.randf() < 0.5 else 1.0
		e.x = clampf(M.ship_x + sx * rand(5, 10), -BX, BX)
		e.y = clampf(M.ship_y + rand(-4, 6), -BY, BY)
		e.z = 40.0 + i * 14
		e.state = "pass"
		e.vs = rand(55, 70)
		e.rot = Vector3(0, PI, 0)
		e.ph = rand(0, 6)
		e.amp = rand(3, 6)
	toast("ACHTUNG – VON HINTEN!", Color(1.0, 0.42, 0.42))

func spawn_escorts(n: int) -> void:
	var side0 := -1.0 if rng.randf() < 0.5 else 1.0
	for i in n:
		var side := (1.0 if i % 2 else -1.0) if n > 1 else side0
		var m := make_fighter(mats.eRed)
		var warn := glow(Color(1.0, 0.12, 0.12), 5, 0.9)
		warn.visible = false
		m.add_child(warn)
		var e := add_enemy("escort", m, {"hp": 2.0, "maxhp": 2.0, "radius": 1.8, "score": 150, "collide": 25.0})
		e.warnS = warn
		e.side = side
		e.x = clampf(M.ship_x + side * rand(7, 10), -BX - 6, BX + 6)
		e.y = clampf(M.ship_y + rand(-2, 3), -BY, BY)
		e.z = 30.0 + i * 6
		e.state = "approach"
		e.mode = "ram" if rng.randf() < 0.5 else "ahead"
		e.rot = Vector3(0, PI, 0)
		e.vs = 0.0
		e.warn = false
	toast("JÄGER NEBEN DIR!", Color(1.0, 0.6, 0.55))

func spawn_interceptors(n: int) -> void:
	var cx := rand(-BX * 0.6, BX * 0.6)
	var cy := rand(-BY * 0.5, BY * 0.5)
	for i in n:
		var k := i - (n - 1) / 2.0
		var e := add_enemy("interceptor", make_interceptor(), {"hp": 1.0, "maxhp": 1.0, "radius": 1.5, "score": 75, "collide": 20.0})
		e.off = k * 3.2
		e.x = cx + k * 3.2
		e.y = cy - absf(k) * 1.1
		e.z = -340.0 - absf(k) * 10
		e.vz = 95.0 + wave * 3
		e.shot = wave < 2

func spawn_heavy() -> void:
	var hp := 12.0 + wave
	var e := add_enemy("heavy", make_heavy(), {"hp": hp, "maxhp": hp, "radius": 2.8, "score": 300, "collide": 40.0})
	e.x0 = rand(-BX * 0.6, BX * 0.6)
	e.y0 = rand(-BY * 0.5, BY * 0.6)
	e.x = e.x0
	e.y = e.y0
	e.z = -360.0
	e.holdZ = rand(-62, -45)
	e.fire_t = 2.0

func spawn_bomber() -> void:
	var e := add_enemy("bomber", make_bomber(), {"hp": 7.0, "maxhp": 7.0, "radius": 2.7, "score": 250, "collide": 35.0})
	_hold_init(e, 0.7, 0.5, rand(-44, -30))
	e.x = e.x0 * 1.5
	e.fire_t = 1.5
	introduce("bomber", "BOMBER – LANGSAME PLASMAKUGELN")

func _hold_init(e: Dictionary, kx: float, ky: float, hz: float) -> void:
	e.x0 = rand(-BX * kx, BX * kx)
	e.y0 = rand(-BY * ky, BY * 0.6)
	e.x = e.x0
	e.y = e.y0
	e.z = -340.0
	e.holdZ = hz

func spawn_sniper() -> void:
	var e := add_enemy("sniper", make_sniper(), {"hp": 3.0, "maxhp": 3.0, "radius": 1.7, "score": 200, "collide": 20.0})
	_hold_init(e, 0.8, 0.6, rand(-115, -92))
	e.cd = 2.0
	e.aim = 0.0
	e.T = Vector3.ZERO
	var line := MeshInstance3D.new()
	line.mesh = shapes.cyl
	line.material_override = glow_line_mat(Color(1.0, 0.12, 0.2))
	line.visible = false
	M.add_child(line)
	e.line = line
	introduce("sniper", "SCHARFSCHÜTZE – ACHTE AUF DEN ROTEN STRAHL")

func glow_line_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, 0.6)
	m.disable_fog = true
	return m

func spawn_swarm(n: int) -> void:
	var sw := {"t0": time, "ph": rand(0, 6)}
	for i in n:
		var e := add_enemy("drone", make_drone(), {"hp": 1.0, "maxhp": 1.0, "radius": 1.25, "score": 40, "collide": 15.0})
		e.sw = sw
		e.idx = i
	introduce("drone", "DROHNENSCHWARM")

func spawn_brander() -> void:
	var e := add_enemy("brander", make_brander(), {"hp": 2.0, "maxhp": 2.0, "radius": 1.8, "score": 120, "collide": 35.0})
	e.x = rand(-BX, BX) * 1.4
	e.y = rand(-BY, BY)
	e.z = -330.0
	e.vs = 40.0
	e.vz = 40.0
	introduce("brander", "BRANDER – STÜRZT SICH AUF DICH")

func spawn_shieldship() -> void:
	var e := add_enemy("shieldship", make_shieldship(), {"hp": 5.0, "maxhp": 5.0, "radius": 3.4, "score": 300, "collide": 35.0, "sh": 8.0})
	_hold_init(e, 0.7, 0.5, rand(-50, -38))
	e.fire_t = 2.0
	e.shFx = 0.0
	introduce("shield", "SCHILDTRÄGER – ERST DEN SCHILD ZERSCHIESSEN")

func spawn_spinner() -> void:
	var e := add_enemy("spinner", make_spinner(), {"hp": 5.0, "maxhp": 5.0, "radius": 2.1, "score": 220, "collide": 30.0})
	_hold_init(e, 0.7, 0.5, rand(-52, -36))
	e.cyc = 0.0
	e.ang = 0.0
	e.sT = 0.0
	introduce("spinner", "KREISEL – DREHENDE SCHUSSSTRÖME")

func spawn_formation() -> void:
	var sd := -1.0 if rng.randf() < 0.5 else 1.0
	var y := rand(-BY * 0.5, BY * 0.6)
	var z := rand(-70, -45)
	for i in 5:
		var e := add_enemy("form", make_fighter(mats.eRed), {"hp": 2.0, "maxhp": 2.0, "radius": 1.9, "score": 90, "collide": 25.0})
		var k := i - 2
		e.ox = -absf(k) * 4 * sd
		e.oy = k * 3.2
		e.sd = sd
		e.y0 = y
		e.z0 = z - absf(k) * 3
		e.x = -sd * (BX + 40) + e.ox
		e.y = y + e.oy
		e.z = e.z0
		e.fire_t = rand(1.5, 3)
	introduce("form", "FORMATION – ALLE AUF EINMAL ERWISCHEN!")

func spawn_cloaker() -> void:
	var e := add_enemy("cloak", make_fighter(mats.eRed), {"hp": 4.0, "maxhp": 4.0, "radius": 2.0, "score": 220, "collide": 25.0})
	e.x = rand(-BX * 0.7, BX * 0.7)
	e.y = rand(-BY * 0.6, BY * 0.6)
	e.z = -200.0
	e.holdZ = rand(-55, -35)
	e.cT = rand(1, 2)
	e.vis = 1.0
	e.hid = false
	introduce("cloak", "TARNKAPPE – NUR SICHTBAR VERWUNDBAR")

func spawn_overtaker() -> void:
	var e := add_enemy("over", make_fighter(mats.eRed), {"hp": 3.0, "maxhp": 3.0, "radius": 1.9, "score": 180, "collide": 25.0})
	e.x = M.ship_x + rand(-6, 6) + (-9.0 if rng.randf() < 0.5 else 9.0)
	e.y = M.ship_y + rand(-4, 6)
	e.z = 45.0
	e.holdZ = rand(-45, -30)
	e.x0 = rand(-BX * 0.7, BX * 0.7)
	e.y0 = rand(-BY * 0.5, BY * 0.5)
	introduce("over", "VON HINTEN – ÜBERHOLT DICH!")

func spawn_layer() -> void:
	var g := make_shieldship()
	g.get_meta("bub").queue_free()
	var e := add_enemy("layer", g, {"hp": 6.0, "maxhp": 6.0, "radius": 3.0, "score": 260, "collide": 30.0})
	var sd := -1.0 if rng.randf() < 0.5 else 1.0
	e.sd = sd
	e.x = -sd * (BX + 30)
	e.y = rand(-BY * 0.4, BY * 0.5)
	e.z = -60.0
	e.mT = 0.6
	introduce("layer", "MINENLEGER – MINEN ABSCHIESSEN")

func spawn_capital() -> void:
	var sd := -1.0 if rng.randf() < 0.5 else 1.0
	var g := Node3D.new()
	g.add_child(mk("box", mats.eHull, 14, 10, 120))
	g.add_child(mk("box", mats.bossDark, 10, 6, 90, 0, 7, -10))
	g.add_child(mk("box", mats.bossLit, 6, 8, 14, 0, 12, -30))
	g.add_child(mk("cone4", mats.eHull, 14, 30, 10, 0, 0, 74, PI / 2, PI / 4))
	for k in 4:
		var ex := 3.0 if k % 2 else -3.0
		var ey := 3.0 if k < 2 else -3.0
		g.add_child(mk("cyl", mats.bossDark, 4, 8, 4, ex, ey, -62, PI / 2))
		var fl := glow(Color(0.38, 0.78, 1.0), 12, 0.9)
		fl.position = Vector3(ex, ey, -68)
		g.add_child(fl)
	for k in 14:
		var l := glow(Color(1.0, 0.88, 0.63), 1.6, 0.9)
		l.position = Vector3(-sd * 7.2, rand(-3, 3), rand(-50, 50))
		g.add_child(l)
	var e := add_enemy("capital", g, {"hp": 9999.0, "maxhp": 9999.0, "radius": 1.0, "score": 0, "collide": 0.0, "env": true, "invul": true})
	e.sd = sd
	e.x = sd * (BX + 34)
	e.y = rand(-4, 8)
	e.z = -420.0
	e.fire_t = 1.0
	e.turrets = []
	for k in 4:
		var tg := Node3D.new()
		tg.add_child(mk("cyl", mats.bossDark, 2.4, 1.6, 2.4))
		tg.add_child(mk("cyl", mats.eDark, 0.5, 4, 0.5, 0, 0.6, 2, PI / 2))
		tg.add_child(glow(Color(1.0, 0.19, 0.12), 3, 0.9))
		var t := add_enemy("capturret", tg, {"hp": 6.0, "maxhp": 6.0, "radius": 2.6, "score": 300, "collide": 0.0})
		t.cap = e
		t.oz = -36.0 + k * 24
		t.fire_t = rand(1, 3)
		e.turrets.append(t)
	banner("GROSSKAMPFSCHIFF", "GESCHÜTZTÜRME ABSCHIESSEN!", true)

func spawn_miniboss() -> void:
	var g := make_shieldship()
	g.get_meta("bub").queue_free()
	g.add_child(glow(Color(0.9, 0.15, 0.15), 9, 0.7))
	var hp := roundf(46 * (1 + wave * 0.05))
	var e := add_enemy("mini", g, {"hp": hp, "maxhp": hp, "radius": 5.5, "score": 2500, "collide": 40.0, "bs": 2.4})
	e.x = 0.0
	e.y = 4.0
	e.z = -320.0
	e.holdZ = -55.0
	e.fire_t = 2.0
	e.pat = 0
	banner("MINI-BOSS", "ABFANGJÄGER " + pick(["ALPHA", "BRAVO", "DELTA", "SIGMA"]), true)

func spawn_world_enemy() -> void:
	var tbl := ["over", "form", "cloak", "brander", "layer", "form", "over", "cloak", "layer", "form", "cloak", "over", "brander", "layer"]
	var t: String = tbl[M.widx % 14]
	match t:
		"form": spawn_formation()
		"cloak": spawn_cloaker()
		"over": spawn_overtaker()
		"layer": spawn_layer()
		_:
			spawn_brander()
			spawn_brander()

func spawn_debris() -> void:
	var r := rand(1.2, 3.0)
	var mi := MeshInstance3D.new()
	mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
	mi.material_override = M.rock_mat
	var e := add_enemy("asteroid", mi, {"hp": ceilf(r * 2), "maxhp": ceilf(r * 2), "radius": r * 0.95, "score": 50, "collide": 25.0, "env": true, "bs": r * 0.5})
	e.x = rand(-BX, BX)
	e.y = rand(-BY, BY)
	e.z = -470.0
	e.vx = rand(-2, 2)
	e.vy = rand(-1.5, 1.5)
	e.spin = Vector3(rand(-1, 1), rand(-1, 1), rand(-1, 1))

func spawn_mine(x: float, y: float, z: float) -> Dictionary:
	var e := add_enemy("mine", make_mine(), {"hp": 1.0, "maxhp": 1.0, "radius": 1.4, "score": 30, "collide": 22.0})
	e.x = x
	e.y = y
	e.z = z
	e.vz = M.speed * 0.25
	return e

func spawn_homing(x: float, y: float, z: float, sd: float) -> void:
	var e := add_enemy("hmis", make_hmis(), {"hp": 1.0, "maxhp": 1.0, "radius": 1.0, "score": 20, "collide": 18.0})
	e.x = x
	e.y = y
	e.z = z
	e.vx = sd * 14.0
	e.vy = 8.0
	e.vz = 10.0
	e.life = 6.0

# ======================= Gegner-Schüsse =======================
func spawn_ebullet(x: float, y: float, z: float, v: Vector3, kind := "") -> Dictionary:
	var mat: Material = mats.eb
	var sc := 1.0
	var gcol := Color(1.0, 0.1, 0.23)
	var dmg := 10.0 + wave * 0.25
	match kind:
		"flak":
			mat = mats.ebFlak
			sc = 1.7
			gcol = Color(1.0, 0.63, 0.25)
			dmg = 14.0
		"orb":
			mat = mats.ebOrb
			sc = 2.1
			gcol = Color(1.0, 0.82, 0.25)
			dmg = 18.0
		"snip":
			mat = mats.ebSnip
			sc = 0.8
			gcol = Color(1.0, 0.12, 0.2)
			dmg = 16.0
	var n := Node3D.new()
	n.add_child(mk("ebullet", mat, sc, sc, sc))
	n.add_child(glow(gcol, 2.5 * sc, 0.8))
	M.add_child(n)
	var b := {"node": n, "p": Vector3(x, y, z), "prev": Vector3(x, y, z), "v": v, "dmg": dmg}
	ebullets.append(b)
	return b

func enemy_shoot(x: float, y: float, z: float, spd: float, count := 1, spread := 0.0) -> void:
	var from := Vector3(x, y, z)
	var sp := Vector3(M.ship_x, M.ship_y, 0)
	var dist := from.distance_to(sp)
	if state != "play" or dist < 10.0:
		return
	spd *= clampf(dist / 45.0, 0.6, 1.0)
	var tgt := Vector3(M.ship_x + M.ship_vx * 0.3, M.ship_y + M.ship_vy * 0.3, 0)
	var dir := (tgt - from).normalized()
	for i in count:
		var a := (i - (count - 1) / 2.0) * spread
		var d := dir.rotated(Vector3.UP, a) if a != 0.0 else dir
		spawn_ebullet(x, y, z, d * spd)

func ring_burst(x: float, y: float, z: float, n: int, spd: float, ph: float) -> void:
	for k in n:
		var a := ph + k * TAU / n
		spawn_ebullet(x, y, z, Vector3(cos(a) * 0.35, sin(a) * 0.35, 1).normalized() * spd)

# ======================= Gegner-Verhalten =======================
func update_enemy(e: Dictionary, dt: float) -> void:
	e.t += dt
	var sp: float = M.speed
	if e.flash > 0:
		e.flash -= dt * 5
	var px: float = e.x
	match e.type:
		"fighter":
			var ph: float = time * e.freq + e.ph
			if e.state == "in":
				e.z += clampf((e.holdZ - e.z) * 1.8, 15, 170) * dt
				e.x += (e.x0 + sin(ph) * e.amp - e.x) * minf(1, dt * 2)
				e.y += (e.y0 + cos(ph * 1.3) * e.amp * 0.4 - e.y) * minf(1, dt * 2)
				if e.z >= e.holdZ - 1:
					e.state = "hold"
					e.t = 0.0
			elif e.state == "hold":
				e.x += (e.x0 + sin(ph) * e.amp - e.x) * minf(1, dt * 3)
				e.y += (e.y0 + cos(ph * 1.3) * e.amp * 0.4 - e.y) * minf(1, dt * 3)
				e.z += (e.holdZ + sin(time * 0.9 + e.ph) * 7 - e.z) * minf(1, dt * 2)
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = rand(1.6, 2.8) / diff()
					enemy_shoot(e.x, e.y, e.z, bullet_speed())
				if e.t > e.holdTime:
					e.state = "out"
					e.outX = M.ship_x + (-1.0 if rng.randf() < 0.5 else 1.0) * rand(7, 11)
					e.outY = M.ship_y + rand(-2, 5)
					e.ov = 10.0
			else:
				e.ov += dt * 80
				e.z += e.ov * dt
				e.x += (e.outX - e.x) * minf(1, dt * 2.5)
				e.y += (e.outY - e.y) * minf(1, dt * 2.5)
			e.rot.z = clampf(-(e.x - px) / dt * 0.04, -0.9, 0.9)
		"flanker":
			e.x += e.vx * dt
			e.z += (e.tz - e.z) * dt * 0.6
			e.y += sin(e.t * 2) * 3 * dt
			e.rot = Vector3(0, -e.side * PI / 2, e.side * 0.5)
			if e.shots > 0 and absf(e.x - M.ship_x) < 24:
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = 0.75
					e.shots -= 1
					enemy_shoot(e.x, e.y, e.z, bullet_speed())
			if e.side * e.x < -(BX + 60):
				e.gone = true
		"chaser":
			if e.state == "pass":
				e.z -= e.vs * dt
				if e.z < -28:
					e.state = "brake"
			elif e.state == "brake":
				e.vs = maxf(0, e.vs - 70 * dt)
				e.z -= e.vs * dt
				e.rot.y += (0 - e.rot.y) * minf(1, dt * 3)
				if e.vs <= 0:
					e.state = "hold"
					e.t = 0.0
					e.holdZ = e.z
					e.x0 = clampf(e.x, -BX * 0.8, BX * 0.8)
					e.y0 = clampf(e.y, -BY * 0.8, BY * 0.8)
					e.fire_t = 0.6
			elif e.state == "hold":
				e.x += (e.x0 + sin(time * 0.9 + e.ph) * e.amp - e.x) * minf(1, dt * 3)
				e.y += (e.y0 + cos(time * 1.2 + e.ph) * 2 - e.y) * minf(1, dt * 3)
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = rand(1.4, 2.2) / diff()
					enemy_shoot(e.x, e.y, e.z, bullet_speed())
				if e.t > 5.5:
					e.state = "leave"
					e.vs = 0.0
			else:
				e.vs += 90 * dt
				e.z -= e.vs * dt
				e.rot.y += (PI - e.rot.y) * minf(1, dt * 3)
				if e.z < -400:
					e.gone = true
			e.rot.z = clampf(-(e.x - px) / dt * 0.04, -0.9, 0.9)
		"escort":
			var tx: float = M.ship_x + e.side * 7.5
			var ty: float = M.ship_y + 1
			if e.state == "approach":
				e.z += (-1 - e.z) * minf(1, dt * 1.3)
				e.x += (tx - e.x) * minf(1, dt * 2)
				e.y += (ty - e.y) * minf(1, dt * 2)
				if absf(e.z + 1) < 1.5:
					e.state = "side"
					e.t = 0.0
			elif e.state == "side":
				e.x += (tx - e.x) * minf(1, dt * 3)
				e.y += (ty - e.y) * minf(1, dt * 3)
				e.z += (-1 + sin(e.t * 3) * 1.2 - e.z) * minf(1, dt * 3)
				e.warn = e.mode == "ram" and e.t > 1.2
				if e.t > 2.3:
					e.state = e.mode
					e.t = 0.0
					e.warn = e.mode == "ram"
			elif e.state == "ram":
				e.x += -e.side * 26 * dt
				if signf(e.x - M.ship_x) == -e.side and absf(e.x - M.ship_x) > 12:
					e.state = "ahead"
					e.t = 0.0
					e.warn = false
			else:
				e.vs += 60 * dt
				e.z -= e.vs * dt
				e.rot.y += (0 - e.rot.y) * minf(1, dt * 3)
				if e.z < -24:
					e.type = "fighter"
					e.state = "hold"
					e.t = 0.0
					e.holdZ = rand(-30, -18)
					e.holdTime = rand(4, 6)
					e.x0 = clampf(e.x, -BX * 0.8, BX * 0.8)
					e.y0 = clampf(e.y, -BY * 0.7, BY * 0.7)
					e.amp = rand(3, 6)
					e.freq = rand(0.6, 1)
					e.ph = rand(0, 6)
					e.fire_t = 0.8
					e.warn = false
					e.rot.y = 0.0
			if e.state != "ahead" and e.type == "escort":
				e.rot.y += (PI - e.rot.y) * minf(1, dt * 3)
			e.rot.z = clampf(-(e.x - px) / dt * 0.04, -0.9, 0.9)
			e.warnS.visible = e.warn and sin(time * 28) > -0.2
		"interceptor":
			if e.z < -70:
				e.vx += ((M.ship_x + e.off * 0.6) - e.x) * 0.9 * dt
				e.vy += (M.ship_y - e.y) * 0.7 * dt
				e.vx *= 0.985
				e.vy *= 0.985
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.z += e.vz * dt
			if not e.shot and e.z > -130:
				e.shot = true
				enemy_shoot(e.x, e.y, e.z, bullet_speed() * 1.1)
			e.rot.z += dt * 4
		"heavy":
			if e.state == "in":
				e.z += clampf((e.holdZ - e.z) * 1.2, 8, 90) * dt
				if e.z >= e.holdZ - 1:
					e.state = "hold"
					e.t = 0.0
			elif e.state == "hold":
				e.x += (e.x0 + sin(time * 0.4) * 4 - e.x) * minf(1, dt * 2)
				e.y += (e.y0 + sin(time * 0.55) * 2 - e.y) * minf(1, dt * 2)
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = 2.5 / diff()
					enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.9, 5 if wave >= 6 else 3, 0.09)
				if e.t > 15:
					e.state = "out"
			else:
				e.z -= 50 * dt
				if e.z < -400:
					e.gone = true
			e.rot.z += dt * 0.6
			var ring: Node3D = e.node.get_meta("ring")
			ring.rotation.x += dt * 1.5
		"bomber", "shieldship", "spinner", "sniper":
			_update_holder(e, dt, px)
		"drone":
			var tt: float = time - e.sw.t0 - e.idx * 0.22
			var s2 := minf(1, maxf(0, tt) / 4)
			var ph2: float = e.sw.ph
			e.x = sin(tt * 1.3 + ph2) * BX * 0.85 * s2
			e.y = cos(tt * 0.9 + ph2) * BY * 0.6 * s2
			e.z = -330 + maxf(0, tt) * 60 if tt < 5.2 else (-18 + sin((tt - 5.2) * 0.8) * 5 if tt < 12 else -18 + (tt - 12) * 45)
			e.rot.y = atan2(e.x - px, 1) * 0.8
			e.rot.z = clampf(-(e.x - px) / dt * 0.05, -1, 1)
		"capital":
			e.z += sp * 0.55 * dt
			e.x += (e.sd * (BX + 34) - e.x) * minf(1, dt)
			for t in e.turrets:
				if t.alive:
					t.x = e.x - e.sd * 8
					t.y = e.y + 6
					t.z = e.z + t.oz
			if e.z > -40 and e.z < 20 and not e.has("passed"):
				e.passed = true
				trauma = minf(1, trauma + 0.4)
			if e.z > 160:
				for t in e.turrets:
					if t.alive:
						t.gone = true
				e.gone = true
		"capturret":
			if not e.cap.alive or e.cap.gone:
				e.gone = true
			else:
				e.rot.y = atan2(M.ship_x - e.x, -e.z)
				e.fire_t -= dt
				if e.fire_t <= 0 and e.z < -15 and e.z > -260:
					e.fire_t = rand(1.4, 2.2) / diff()
					enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.9)
		"mini":
			e.z += (e.holdZ - e.z) * minf(1, dt * 0.8)
			e.x = sin(e.t * 0.6) * BX * 0.6
			e.y = 4 + sin(e.t * 0.9) * BY * 0.35
			e.rot.z = sin(e.t * 0.6) * 0.4
			e.fire_t -= dt
			if e.fire_t <= 0 and e.z > -120:
				e.pat = (e.pat + 1) % 3
				e.fire_t = (3.0 if e.pat == 2 else 1.6) / diff()
				if e.pat == 0:
					ring_burst(e.x, e.y, e.z, 12, bullet_speed() * 0.7, e.t)
				elif e.pat == 1:
					enemy_shoot(e.x, e.y, e.z, bullet_speed(), 3, 0.12)
				else:
					spawn_homing(e.x, e.y, e.z, 1)
					spawn_homing(e.x, e.y, e.z, -1)
		"form":
			e.x += e.sd * 22 * dt
			e.y += (e.y0 + e.oy + sin(e.t * 2) * 1.5 - e.y) * minf(1, dt * 2)
			e.z += (e.z0 - e.z) * minf(1, dt * 2)
			e.rot = Vector3(0, -e.sd * 0.4, e.sd * 0.35)
			e.fire_t -= dt
			if e.fire_t <= 0 and absf(e.x) < BX:
				e.fire_t = rand(2, 3.2) / diff()
				enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.85)
			if absf(e.x) > BX + 60:
				e.gone = true
		"cloak":
			e.z += (e.holdZ - e.z) * minf(1, dt * 1.2)
			e.x += sin(e.t * 0.9) * 6 * dt
			e.y += cos(e.t * 0.7) * 4 * dt
			e.cT -= dt
			if e.cT <= 0:
				e.hid = not e.hid
				e.cT = rand(2, 3) if e.hid else rand(1.6, 2.4)
				if not e.hid:
					e.fire_t = 0.35
			e.vis += ((0.06 if e.hid else 1.0) - e.vis) * minf(1, dt * 5)
			e.invul = e.vis < 0.5
			e.node.visible = e.vis > 0.25 or sin(time * 30) > 0.6
			if not e.hid:
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = 0.9 / diff()
					enemy_shoot(e.x, e.y, e.z, bullet_speed(), 2, 0.06)
			if e.t > 22:
				e.gone = true
		"over":
			if e.z > e.holdZ + 2:
				e.z -= 95 * dt
				e.x += (e.x0 - e.x) * minf(1, dt * 0.8)
				e.y += (e.y0 - e.y) * minf(1, dt * 0.8)
				e.rot = Vector3(0, PI, 0)
			else:
				e.rot.y += (0 - e.rot.y) * minf(1, dt * 3)
				e.x += sin(e.t * 1.3) * 7 * dt
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = rand(1.2, 2) / diff()
					enemy_shoot(e.x, e.y, e.z, bullet_speed())
			if e.t > 16:
				e.z -= 40 * dt
				if e.z < -300:
					e.gone = true
		"layer":
			e.x += e.sd * 13 * dt
			e.y += sin(e.t) * 2 * dt
			e.rot = Vector3(0, e.sd * PI / 2, 0)
			e.mT -= dt
			if e.mT <= 0 and absf(e.x) < BX * 0.95:
				e.mT = rand(0.7, 1.1)
				spawn_mine(e.x, e.y, e.z)
			if absf(e.x) > BX + 40:
				e.gone = true
		"brander":
			e.vs = minf(95, e.vs + 28 * dt)
			if e.z < -22:
				var d := (Vector3(M.ship_x, M.ship_y, 0) - Vector3(e.x, e.y, e.z)).normalized() * e.vs
				var v := Vector3(e.vx, e.vy, e.vz).lerp(d, minf(1, dt * 1.6))
				e.vx = v.x
				e.vy = v.y
				e.vz = v.z
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.z += e.vz * dt
			e.rot = Vector3(-atan2(e.vy, Vector2(e.vx, e.vz).length()), atan2(e.vx, e.vz), e.t * 6)
			var gl: Node3D = e.node.get_meta("gl")
			gl.scale = Vector3.ONE * 4 * (1 + 0.4 * sin(time * 20))
		"hmis":
			var d2 := (Vector3(M.ship_x, M.ship_y, 0) - Vector3(e.x, e.y, e.z)).normalized() * (26 + wave * 0.4)
			var v2 := Vector3(e.vx, e.vy, e.vz).lerp(d2, minf(1, dt * 1.2))
			e.vx = v2.x
			e.vy = v2.y
			e.vz = v2.z
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.z += e.vz * dt
			e.rot = Vector3(-atan2(e.vy, Vector2(e.vx, e.vz).length()), atan2(e.vx, e.vz), 0)
			e.life -= dt
			if e.life <= 0:
				boom(e.wp, 0.6)
				e.gone = true
		"mine":
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.z += e.vz * dt
			e.vx += (M.ship_x - e.x) * 0.25 * dt
			e.vy += (M.ship_y - e.y) * 0.25 * dt
			e.rot.y += dt
			e.rot.x += dt * 0.7
			var l: Node3D = e.node.get_meta("light")
			l.visible = sin(time * 12) > 0
		"asteroid":
			e.z += sp * dt
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.rot += e.spin * dt
		"thrown":
			if e.has("grav"):
				e.vy -= e.grav * dt
			e.x += e.vx * dt
			e.y += e.vy * dt
			e.z += e.vz * dt
			e.rot += e.spin * dt
			if e.y < -BY - 30 or e.z > 60:
				e.gone = true
		_:
			if has_method("update_special"):
				call("update_special", e, dt, px)
	if not e.has("boss"):
		place(e.node, e.x, e.y, e.z, e.rot, e.bs * (1 + maxf(0, e.flash) * 0.18))
		if not e.has("haz") and (e.z > 75 or e.z < -490 or absf(e.x) > 160):
			e.gone = true
		if not e.env and e.hp < e.maxhp * 0.5 and e.maxhp > 1 and rng.randf() < dt * 10:
			smoke(e.wp, 0.9)
	if e.collide > 0 and absf(e.z) < e.radius + 1.2 and state == "play":
		if Vector2(e.x - M.ship_x, e.y - M.ship_y).length() < e.radius * 0.8 + 1 and invul <= 0:
			if bubble > 0 or (roll_t > 0 and e.type == "escort"):
				kill_enemy(e, false)
			else:
				damage_player(e.collide, true)
				kill_enemy(e, true)

func _update_holder(e: Dictionary, dt: float, px: float) -> void:
	if e.state == "in":
		e.z += clampf((e.holdZ - e.z) * 1.4, 10, 120) * dt
		e.x += (e.x0 - e.x) * minf(1, dt)
		e.y += (e.y0 - e.y) * minf(1, dt)
		if e.z >= e.holdZ - 1:
			e.state = "hold"
			e.t = 0.0
	elif e.state == "hold":
		var amp := 2.0 if e.type == "sniper" else 4.0
		e.x += (e.x0 + sin(time * 0.5 + e.x0) * amp - e.x) * minf(1, dt * 2)
		e.y += (e.y0 + cos(time * 0.6) * 1.5 - e.y) * minf(1, dt * 2)
		if e.t > (16.0 if e.type == "sniper" else 14.0):
			e.state = "out"
		var D := diff()
		var bs := bullet_speed()
		match e.type:
			"bomber":
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = 3.2 / D
					var d := (Vector3(M.ship_x, M.ship_y, 0) - Vector3(e.x, e.y, e.z)).normalized()
					for a in [-0.14, 0.14]:
						spawn_ebullet(e.x, e.y, e.z, d.rotated(Vector3.UP, a) * 26, "orb")
			"shieldship":
				e.fire_t -= dt
				if e.fire_t <= 0:
					e.fire_t = 2.6 / D
					enemy_shoot(e.x, e.y, e.z, bs * 0.9, 3, 0.1)
			"spinner":
				e.cyc += dt
				if fmod(e.cyc, 4.6) < 2.2:
					e.sT -= dt
					if e.sT <= 0:
						e.sT = 0.2
						e.ang += 0.4
						for k in 4:
							var a2: float = e.ang + k * PI / 2
							spawn_ebullet(e.x, e.y, e.z, Vector3(cos(a2) * 0.14, sin(a2) * 0.14, 1).normalized() * bs * 0.75)
			"sniper":
				e.cd -= dt
				if e.aim > 0:
					e.aim -= dt
					if e.aim > 0.3:
						e.T = Vector3(M.ship_x + M.ship_vx * 0.25, M.ship_y + M.ship_vy * 0.25, 8)
					var p := Vector3(e.x, e.y, e.z)
					var tip: Vector3 = (e.T - p) * 1.6 + p
					beam_between(e.line, p, tip, 0.05 + (0.3 - minf(0.3, e.aim)) * 0.2)
					e.line.visible = sin(time * 40) > -0.5 or e.aim < 0.3
					if e.aim <= 0:
						e.line.visible = false
						spawn_ebullet(e.x, e.y, e.z, (e.T - p).normalized() * 115, "snip")
						e.cd = 3.8 / D
				elif e.cd <= 0 and state == "play":
					e.aim = 1.15
	else:
		e.z -= 55 * dt
		if e.has("line"):
			e.line.visible = false
		if e.z < -420:
			e.gone = true
	if e.type == "spinner":
		var disc: Node3D = e.node.get_meta("disc")
		disc.rotation.z += dt * 6
	if e.type == "shieldship":
		var bub: Node3D = e.node.get_meta("bub")
		bub.visible = e.sh > 0
		e.shFx = maxf(0, e.shFx - dt * 3)
		e.radius = 3.4 if e.sh > 0 else 2.4
	e.rot.z = clampf(-(e.x - px) / dt * 0.03, -0.6, 0.6)

## Strahl (Zylinder) zwischen zwei Punkten in Relativkoordinaten
func beam_between(n: MeshInstance3D, a: Vector3, b: Vector3, r: float) -> void:
	var wa := w_of(a.x, a.y, a.z)
	var wb := w_of(b.x, b.y, b.z)
	var mid := (wa + wb) * 0.5
	var d := wb - wa
	var ln := d.length()
	if ln < 0.01:
		return
	var up := d / ln
	var side := up.cross(Vector3(0.31, 0.5, 0.81)).normalized()
	n.global_transform = Transform3D(Basis(side * r * 2, up * ln, side.cross(up) * r * 2), mid)

# ======================= Treffer / Abschüsse =======================
func hit_enemy(e: Dictionary, dmg: float, at: Vector3) -> void:
	if not e.alive or e.invul:
		sparks(at, Color(0.6, 0.9, 1.0), 4)
		return
	if e.type == "shieldship" and e.sh > 0:
		e.sh -= dmg
		e.shFx = 1.0
		sparks(at, Color(0.4, 0.8, 1.0), 5)
		return
	e.hp -= dmg
	e.flash = 1.0
	sparks(at, Color(1.0, 0.75, 0.4), 5)
	if has_method("on_boss_hit") and e.has("boss"):
		call("on_boss_hit", e, dmg)
	if e.hp <= 0:
		kill_enemy(e, false)

func kill_enemy(e: Dictionary, by_ram: bool) -> void:
	if not e.alive:
		return
	e.alive = false
	var big: float = clampf(e.radius / 2.0, 0.6, 3.0)
	boom(e.wp, big)
	if not by_ram and not e.env or e.type == "asteroid":
		chain += 1
		mult_t = 3.0
		mult = mini(8, 1 + chain / 5)
		add_score(int(e.score) * mult)
	if not e.env and rng.randf() < (0.5 if e.maxhp >= 5 else 0.09):
		spawn_pickup(e.x, e.y, e.z, roll_pickup())
	if e.has("line"):
		e.line.queue_free()
	if e.has("on_kill"):
		var f: Callable = e.on_kill
		f.call()

func add_score(n: int) -> void:
	score += n

# ======================= Effekte (ARC-Stil) =======================
func boom(pos: Vector3, size: float) -> void:
	# Feuerball aus mehreren Leuchtkugeln
	for i in 5:
		var gl := glow(Color(1.0, 0.55 + rng.randf() * 0.3, 0.2), 1.0, 0.95)
		M.add_child(gl)
		gl.global_position = pos + Vector3(rand(-1, 1), rand(-1, 1), rand(-1, 1)) * size * 0.8
		fxs.append({"n": gl, "t": 0.0, "life": rand(0.45, 0.75), "k": "ball", "s0": size * 2.0, "s1": size * rand(6, 9)})
	var core := glow(Color(1, 1, 1), size * 5, 1.0)
	M.add_child(core)
	core.global_position = pos
	fxs.append({"n": core, "t": 0.0, "life": 0.18, "k": "ball", "s0": size * 5, "s1": size * 9})
	# Druckwelle
	var ring := MeshInstance3D.new()
	ring.mesh = shapes.quad
	ring.material_override = glow_mat(Color(1.0, 0.7, 0.4), 0.9, true)
	M.add_child(ring)
	ring.global_position = pos
	fxs.append({"n": ring, "t": 0.0, "life": 0.5, "k": "ring", "s0": size * 2, "s1": size * 16})
	# Trümmer
	for i in int(4 + size * 4):
		var d := mk("box", mats.eDark, rand(0.2, 0.6) * size, rand(0.1, 0.3) * size, rand(0.2, 0.7) * size)
		M.add_child(d)
		d.global_position = pos
		var v := Vector3(rand(-1, 1), rand(-1, 1), rand(-1, 1)).normalized() * rand(8, 22) * sqrt(size)
		fxs.append({"n": d, "t": 0.0, "life": rand(0.8, 1.4), "k": "deb", "v": v, "spin": Vector3(rand(-8, 8), rand(-8, 8), rand(-8, 8))})
	sparks(pos, Color(1.0, 0.8, 0.4), int(10 + size * 8))
	trauma = minf(1, trauma + 0.08 * size)

func sparks(pos: Vector3, col: Color, n: int) -> void:
	var p := CPUParticles3D.new()
	p.mesh = shapes.box
	var m := bm(col, 4.0)
	p.material_override = m
	p.amount = maxi(2, n)
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.45
	p.spread = 180.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 30.0
	p.gravity = Vector3.ZERO
	p.particle_flag_align_y = true
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.14
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	M.add_child(p)
	p.global_position = pos
	p.emitting = true
	fxs.append({"n": p, "t": 0.0, "life": 0.8, "k": "free"})

func smoke(pos: Vector3, size: float) -> void:
	var gl := glow(Color(0.18, 0.16, 0.15), size, 0.5)
	gl.material_override = glow_smoke_mat()
	M.add_child(gl)
	gl.global_position = pos
	fxs.append({"n": gl, "t": 0.0, "life": 1.0, "k": "smoke", "s0": size, "s1": size * 3})

var _smoke_mat: StandardMaterial3D
func glow_smoke_mat() -> StandardMaterial3D:
	if _smoke_mat == null:
		_smoke_mat = StandardMaterial3D.new()
		_smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_smoke_mat.albedo_texture = glow_tex
		_smoke_mat.albedo_color = Color(0.2, 0.18, 0.17, 0.45)
	return _smoke_mat

func _update_fx(dt: float) -> void:
	for i in range(fxs.size() - 1, -1, -1):
		var f: Dictionary = fxs[i]
		f.t += dt
		var k: float = f.t / f.life
		var n = f.n
		if k >= 1.0:
			n.queue_free()
			fxs.remove_at(i)
			continue
		match f.k:
			"ball", "smoke":
				n.scale = Vector3.ONE * lerpf(f.s0, f.s1, 1.0 - pow(1.0 - k, 2.0))
				n.transparency = k
			"ring":
				n.scale = Vector3.ONE * lerpf(f.s0, f.s1, k)
				n.transparency = k
			"deb":
				n.global_position += f.v * dt
				n.rotation += f.spin * dt
				if k > 0.7:
					n.scale *= 0.92

# ======================= Power-ups =======================
const PU := {
	"R": {"col": Color(0.0, 1.0, 0.61), "label": "REPARATUR", "msg": "+35 HÜLLE"},
	"M": {"col": Color(1.0, 0.54, 0.0), "label": "+3 RAKETEN", "msg": "+3 RAKETEN"},
	"P": {"col": Color(0.16, 0.55, 1.0), "label": "LASER +", "wpn": true},
	"X": {"col": Color(0.22, 1.0, 0.08), "label": "STREUFEUER +", "wpn": true},
	"Z": {"col": Color(1.0, 0.12, 0.82), "label": "PLASMA +", "wpn": true},
	"S": {"col": Color(0.0, 0.94, 1.0), "label": "SCHUTZSCHILD", "msg": "SCHUTZSCHILD 8 s"},
	"N": {"col": Color(1.0, 0.88, 0.12), "label": "ATOMBOMBE +1", "msg": "ATOMBOMBE +1"},
}

func roll_pickup() -> String:
	if M.hull < 35 and rng.randf() < 0.18:
		return "R"
	var t := rng.randf()
	if t < 0.08: return "R"
	if t < 0.33: return "M"
	if t < 0.5: return "P"
	if t < 0.66: return "X"
	if t < 0.8: return "Z"
	if t < 0.96: return "S"
	return "N"

func spawn_pickup(x: float, y: float, z: float, kind: String) -> void:
	var d: Dictionary = PU[kind]
	var col: Color = d.col
	var g := Node3D.new()
	var model := Node3D.new()
	var mat := pbr(col, 0.2, 0.4, col, 1.8)
	match kind:
		"R":
			model.add_child(mk("box", mat, 1.6, 0.55, 0.55))
			model.add_child(mk("box", mat, 0.55, 1.6, 0.55))
		"M":
			for i in [-1, 0, 1]:
				model.add_child(mk("cyl", mats.missile, 0.3, 1.3, 0.3, i * 0.45, -0.1, 0))
				model.add_child(mk("cone", mat, 0.3, 0.45, 0.3, i * 0.45, 0.77, 0))
		"P":
			for a in [-0.38, 0.0, 0.38]:
				model.add_child(mk("cyl", mat, 0.16, 2, 0.16, sin(a) * 0.8, 0.2, 0, 0, 0, -a))
			model.add_child(mk("box", mat, 1, 0.4, 0.5, 0, -0.85, 0))
		"X":
			for a in [-0.7, -0.35, 0.0, 0.35, 0.7]:
				model.add_child(mk("cyl", mat, 0.14, 1.7, 0.14, sin(a) * 0.7, cos(a) * 0.7 - 0.2, 0, 0, 0, -a))
			model.add_child(mk("sphere", mat, 0.45, 0.45, 0.45, 0, -0.35, 0))
		"Z":
			model.add_child(mk("sphere", mat, 0.8, 0.8, 0.8))
			for a in [0.0, 1.05, 2.1]:
				model.add_child(mk("ring", mats.white, 1.15, 1.15, 1.5, a, a * 0.7, 0))
		"S":
			model.add_child(mk("ring", mat, 1.05, 1.05, 2))
			model.add_child(mk("ring", mat, 1.05, 1.05, 2, PI / 2))
			model.add_child(mk("sphere", mats.white, 0.25, 0.25, 0.25))
		_:
			for a in [0.0, PI / 3, 2 * PI / 3]:
				model.add_child(mk("octa", mat, 0.3, 1.5, 0.3, 0, 0, 0, 0, 0, a))
			model.add_child(mk("sphere", mats.white, 0.45, 0.45, 0.45))
	model.scale = Vector3.ONE * 2.3
	g.add_child(model)
	g.add_child(glow(col, 9, 0.75))
	var halo := MeshInstance3D.new()
	halo.mesh = shapes.quad
	halo.material_override = glow_mat(col, 0.9, true)
	halo.scale = Vector3.ONE * 7.5
	g.add_child(halo)
	var lab := Label3D.new()
	lab.text = d.label
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 64
	lab.outline_size = 14
	lab.modulate = col.lightened(0.3)
	lab.pixel_size = 0.012
	lab.position = Vector3(0, 3.6, 0)
	lab.no_depth_test = true
	lab.fixed_size = false
	g.add_child(lab)
	M.add_child(g)
	pickups.append({"node": g, "model": model, "halo": halo, "x": x, "y": y, "z": z, "kind": kind, "t": 0.0})

func collect(p: Dictionary) -> void:
	var d: Dictionary = PU[p.kind]
	var msg := ""
	match p.kind:
		"R":
			M.hull = minf(100, M.hull + 35)
			msg = d.msg
		"M":
			nmis = mini(9, nmis + 3)
			msg = d.msg
		"S":
			bubble = 8.0
			M.shield = 100.0
			msg = d.msg
		"N":
			nukes = mini(3, nukes + 1)
			msg = d.msg
		_:
			wpn = p.kind
			wlv = mini(5, wlv + 1)
			wdmg = 0.0
			msg = String(d.label).replace(" +", "") + " STUFE " + str(wlv)
	toast(msg, d.col)
	sparks(w_of(M.ship_x, M.ship_y, 0), d.col, 16)

# ======================= Spieler =======================
func damage_player(d: float, force := false) -> void:
	if state != "play" or invul > 0 or M.autotest:
		return
	if bubble > 0:
		M.shield_fx = 1.0
		return
	if roll_t > 0 and not force:
		return
	if force:
		d *= 1.5
	M.shield_delay = 3.0
	var rem := d
	if M.shield > 0:
		var s := minf(M.shield, rem)
		M.shield -= s
		rem -= s
		M.shield_fx = 1.0
	if rem > 0:
		M.hull -= rem
		M.dmg_fx = 1.0
		invul = maxf(invul, 0.4)
		if mult > 1:
			toast("KOMBO VERLOREN", Color(1.0, 0.54, 0.42))
		chain = 0
		mult = 1
		if wlv > 0:
			wdmg += rem
			if wdmg >= 22:
				wdmg = 0.0
				wlv -= 1
				if wlv <= 0:
					wpn = ""
					toast("WAFFE AUF GRUNDSTUFE", Color(1.0, 0.48, 0.42))
				else:
					toast("WAFFE STUFE " + str(wlv), Color(1.0, 0.48, 0.42))
	trauma = minf(1, trauma + 0.45)
	invul = maxf(invul, 0.35)
	if M.hull <= 0:
		M.hull = 0.0
		player_death()

func player_death() -> void:
	state = "dying"
	var p := w_of(M.ship_x, M.ship_y, 0)
	boom(p, 2.6)
	later(0.25, func(): boom(p + Vector3(1, 0, -2), 1.6))
	M.ship.visible = false
	trauma = 1.0
	later(1.8, show_over)

func show_over() -> void:
	state = "over"
	over_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.1, 0.85)
	sb.border_color = Color(0.4, 0.9, 1.0, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(18)
	over_panel.add_theme_stylebox_override("panel", sb)
	over_panel.position = Vector2(340, 150)
	over_panel.size = Vector2(600, 400)
	hud.add_child(over_panel)
	var t := Label.new()
	t.text = "SCHIFF ZERSTÖRT\n\nPUNKTE  %d\nWELLE  %d" % [score, wave]
	t.add_theme_font_size_override("font_size", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 40)
	t.size = Vector2(600, 220)
	over_panel.add_child(t)
	var b := Button.new()
	b.text = "NOCHMAL"
	b.add_theme_font_size_override("font_size", 30)
	b.position = Vector2(180, 290)
	b.size = Vector2(240, 70)
	b.pressed.connect(func(): get_tree().reload_current_scene())
	over_panel.add_child(b)

func do_roll() -> void:
	if state != "play" or roll_cd > 0:
		return
	roll_t = ROLL
	roll_cd = 1.15
	var dir := 1.0 if M.ship_vx > 1.5 else (-1.0 if M.ship_vx < -1.5 else (-1.0 if M.ship_x > 0 else 1.0))
	roll_dir = -dir
	M.ship_x = clampf(M.ship_x + dir * 4, -BX, BX)

func fire_missiles() -> void:
	if state != "play" or mis_cd > 0:
		return
	if nmis <= 0:
		toast("KEINE RAKETEN", Color(1.0, 0.48, 0.42))
		return
	var cand: Array = []
	for e in enemies:
		if e.alive and not e.invul and not e.env and e.z < -8 and e.z > -300:
			cand.append(e)
	cand.sort_custom(func(a, b): return a.maxhp > b.maxhp)
	var n := mini(3, nmis)
	for i in n:
		var s := 1.0 if i % 2 else -1.0
		var g := Node3D.new()
		g.add_child(mk("cyl", mats.missile, 0.22, 1.1, 0.22, 0, 0, 0, PI / 2))
		g.add_child(mk("cone", mats.eRed, 0.22, 0.35, 0.22, 0, 0, -0.7, -PI / 2))
		g.add_child(glow(Color(1.0, 0.65, 0.24), 1.8, 1.0))
		M.add_child(g)
		missiles.append({"node": g, "p": Vector3(M.ship_x + s * 1.2, M.ship_y - 0.3, 0), "v": Vector3(s * rand(10, 18), rand(5, 11), -12),
			"target": cand[i % cand.size()] if cand.size() > 0 else null, "life": 5.0, "speed": 45.0})
	nmis -= n
	mis_cd = 0.55

func fire_nuke() -> void:
	if state != "play":
		return
	if nukes <= 0:
		toast("KEINE ATOMBOMBE", Color(1.0, 0.48, 0.42))
		return
	nukes -= 1
	trauma = 1.0
	M.flash_fx = 1.2
	for k in 3:
		var p := w_of(M.ship_x, M.ship_y, -20 - k * 25)
		later(k * 0.12, func(): boom(p, 4.0 + k))
	for e in enemies:
		if not e.alive:
			continue
		if e.has("boss"):
			if not e.invul:
				hit_enemy(e, 12, e.wp)
			continue
		if e.z < -330 or e.z > 45:
			continue
		kill_enemy(e, false)
	for b in ebullets:
		b.node.queue_free()
	ebullets.clear()
	banner("☢")

# ======================= Zielen + Schießen =======================
func find_lock():
	var best = null
	var bs := 1.0
	for e in enemies:
		if not e.alive or e.invul or e.env:
			continue
		var dz: float = -e.z
		if dz < 12 or dz > 260:
			continue
		var ang: float = Vector2(e.x - M.ship_x, e.y - M.ship_y).length() / dz
		var sticky: bool = lock is Dictionary and is_same(e, lock)
		var lim: float = (0.62 if sticky else 0.44) + e.radius * 1.5 / dz
		if ang > lim:
			continue
		var sc := ang / lim * (0.55 if sticky else 1.0)
		if sc < bs:
			bs = sc
			best = e
	return best

func _fire(dt: float) -> void:
	fire_t -= dt
	if fire_t > 0:
		return
	fire_t = (0.15 - wlv * 0.006) if wpn == "Z" else (0.12 - wlv * 0.005)
	var shots: Array = []
	if wpn == "P":
		var n: int = [1, 2, 2, 3, 3, 4][wlv]
		for i in n:
			shots.append([(1.0 if gun else -1.0) * 1.88 if n == 1 else (float(i) / (n - 1) * 2 - 1) * (1.2 + n * 0.35), 0.0])
	elif wpn == "X":
		var n2: int = [1, 3, 3, 5, 5, 7][wlv]
		var spr := 0.05 + wlv * 0.012
		for i in n2:
			shots.append([0.0, (i - (n2 - 1) / 2.0) * spr])
	elif wpn == "Z":
		var n3 := 2 if wlv >= 4 else 1
		for i in n3:
			shots.append([0.0 if n3 == 1 else (1.0 if i else -1.0) * 1.6, 0.0])
	else:
		shots.append([(1.0 if gun else -1.0) * 1.88, 0.0])
	gun ^= 1
	var col: Color = PU[wpn].col if wpn != "" else Color(0.54, 0.96, 1.0)
	var dmg := (2 + wlv * 0.6) if wpn == "Z" else (1 + wlv * 0.15)
	var big := (1.8 + wlv * 0.25) if wpn == "Z" else (1 + wlv * 0.08)
	var tr: Transform3D = M.frame(M.s)
	var fwd: Vector3 = -tr.basis.z
	var aim_pt = null
	if lock != null:
		var lw: Vector3 = lock.wp
		var ship_w := w_of(M.ship_x, M.ship_y, 0)
		var tt := lw.distance_to(ship_w) / 300.0
		aim_pt = lw + lock.wv * tt - fwd * M.speed * tt
	for sh in shots:
		var o: float = sh[0]
		var a: float = sh[1]
		var from := w_of(M.ship_x + o, M.ship_y, -1.4)
		var d: Vector3 = fwd
		if aim_pt != null and (aim_pt - from).dot(fwd) > 0:
			d = (aim_pt - from).normalized()
		if a != 0.0:
			d = d.rotated(tr.basis.y, a)
		_spawn_pbullet(from, d, col, dmg, big)

var _pb_mats := {}
func _spawn_pbullet(from: Vector3, d: Vector3, col: Color, dmg: float, big: float) -> void:
	var key := col.to_html()
	if not _pb_mats.has(key):
		_pb_mats[key] = bm(Color(col.r * 0.6 + 0.4, col.g * 0.6 + 0.4, col.b * 0.6 + 0.4), 4.5)
	var n := Node3D.new()
	var core := mk("pbullet", _pb_mats[key], big * 1.3, big * 1.3, 1.0)
	n.add_child(core)
	var gl := glow(col, 1.8 * big, 0.7)
	n.add_child(gl)
	M.add_child(n)
	var tr: Transform3D = M.frame(M.s)
	var v: Vector3 = d * 300.0 - tr.basis.z * M.speed
	n.global_position = from
	n.look_at(from + v, tr.basis.y)
	pbullets.append({"node": n, "p": from, "prev": from, "v": v, "life": 1.0, "dmg": dmg, "big": big})

func seg_dist(a: Vector3, b: Vector3, p: Vector3) -> float:
	var ab := b - a
	var l := ab.length_squared()
	var t := 0.0 if l <= 0 else clampf((p - a).dot(ab) / l, 0, 1)
	return (a + ab * t).distance_to(p)

# ======================= Wellen =======================
func build_wave(n: int) -> Array:
	var q: Array = []
	var dur := minf(40, 14 + n * 1.4)
	var nf := mini(12, 2 + ceili(n * 0.8))
	for i in nf:
		q.append({"t": 1 + float(i) / nf * dur + rand(0, 1), "f": spawn_fighter})
	for i in 1 + n / 3:
		q.append({"t": rand(3, dur), "f": func(): spawn_interceptors(5 if n > 5 else 3)})
	for i in 1 + n / 3:
		q.append({"t": rand(2, dur), "f": func(): spawn_flankers(3 if n > 3 else 2)})
	if n >= 2:
		for i in n / 3:
			q.append({"t": rand(4, dur), "f": func(): spawn_chasers(3 if n > 5 else 2)})
	for i in 1 + n / 4:
		q.append({"t": rand(3, dur), "f": func(): spawn_escorts(2 if n > 4 else 1)})
	if n >= 2:
		for i in 1 + n / 5:
			q.append({"t": rand(4, dur), "f": func(): spawn_swarm(5 + mini(4, n / 3))})
	if n >= 4:
		for i in n / 2:
			q.append({"t": rand(3, dur), "f": spawn_brander})
		for i in 1 + (n - 4) / 3:
			q.append({"t": rand(4, dur - 3), "f": spawn_bomber})
	if n >= 5:
		for i in 1 + (n - 5) / 3:
			q.append({"t": rand(4, dur - 3), "f": spawn_sniper})
			q.append({"t": rand(4, dur - 3), "f": spawn_spinner})
	if n >= 7:
		for i in 1 + (n - 7) / 3:
			q.append({"t": rand(5, dur - 3), "f": spawn_shieldship})
	for i in 1 + n / 3:
		q.append({"t": rand(2, dur - 2), "f": spawn_world_enemy})
	if n % 3 == 2:
		q.append({"t": dur * 0.55, "f": spawn_miniboss})
	if not M.W.planet and n % 4 == 1 and rng.randf() < 0.7:
		q.append({"t": rand(4, dur * 0.6), "f": spawn_capital})
	var nh := (n - 1) / 3 if n >= 3 else 0
	for i in nh:
		q.append({"t": 5 + i * (dur / maxf(1, nh)), "f": spawn_heavy})
	if not M.W.planet and not M.W.has("city"):
		for i in int(dur / 2.5):
			q.append({"t": rand(0, dur), "f": spawn_debris})
	q.sort_custom(func(a, b): return a.t < b.t)
	return q

func start_wave() -> void:
	wave += 1
	wave_clock = 0.0
	if wave % 4 == 0 and has_method("spawn_boss"):
		queue = [{"t": 2.5, "f": Callable(self, "spawn_boss")}]
	else:
		queue = build_wave(wave)
		banner("WELLE " + str(wave), pick(["FEINDLICHE STAFFEL", "FEINDKONTAKT", "JÄGER IM ANFLUG"]))

func _update_waves(dt: float) -> void:
	wave_clock += dt
	while queue.size() > 0 and queue[0].t <= wave_clock:
		var f: Callable = queue.pop_front().f
		f.call()
	var rem := 0
	for e in enemies:
		if not e.env and not e.has("haz"):
			rem += 1
	if queue.size() > 0 and boss == null and rem == 0 and state == "play":
		idle_t += dt
		if idle_t > 1.2 and queue[0].t - wave_clock > 0.4:
			wave_clock = queue[0].t - 0.3
			idle_t = 0.0
	else:
		idle_t = 0.0
	if wave > 0 and queue.is_empty() and boss == null and rem > 0 and rem <= 2:
		stall_t += dt
	else:
		stall_t = 0.0
	if wave > 0 and queue.is_empty() and boss == null and (rem == 0 or stall_t > 4):
		inter_wave += dt
		if inter_wave > 1.1:
			inter_wave = 0.0
			if state == "play":
				add_score(250 * wave)
			if has_method("maybe_passage") and call("maybe_passage"):
				return
			start_wave()
	else:
		inter_wave = 0.0

# ======================= Hauptschleife =======================
func update(dt: float) -> void:
	time += dt
	for i in range(timers.size() - 1, -1, -1):
		var tm: Dictionary = timers[i]
		tm.t -= dt
		if tm.t <= 0:
			timers.remove_at(i)
			var f: Callable = tm.f
			f.call()
	var alive := state == "play"
	roll_t -= dt
	roll_cd -= dt
	invul -= dt
	mis_cd -= dt
	bubble = maxf(0, bubble - dt)
	mult_t -= dt
	if mult_t <= 0 and chain > 0:
		chain = 0
		mult = 1
	if nmis < 6:
		mis_regen += dt
		if mis_regen >= 9:
			mis_regen = 0.0
			nmis += 1
	if alive:
		lock = find_lock()
		_fire(dt)
	_update_waves(dt)
	if has_method("update_boss"):
		call("update_boss", dt)
	for e in enemies:
		if e.alive:
			update_enemy(e, dt)
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		if not e.alive or (e.gone and not e.has("boss")):
			if not e.has("boss"):
				e.node.queue_free()
			if e.has("line") and is_instance_valid(e.line):
				e.line.queue_free()
			enemies.remove_at(i)
	for e in enemies:
		e.pwp = e.wp
		if e.has("boss"):
			e.wp = e.node.global_position
		else:
			e.wp = w_of(e.x, e.y, e.z)
		if dt > 0 and e.pwp != Vector3.ZERO:
			e.wv = (e.wp - e.pwp) / dt
	# Spielerschüsse (fliegen geradeaus im Raum)
	for i in range(pbullets.size() - 1, -1, -1):
		var b: Dictionary = pbullets[i]
		b.prev = b.p
		b.p += b.v * dt
		b.life -= dt
		var hit = null
		var hd := 1e9
		for e in enemies:
			if not e.alive:
				continue
			if seg_dist(b.prev, b.p, e.wp) < e.radius + (b.big - 1) * 0.6:
				var dd: float = b.prev.distance_squared_to(e.wp)
				if dd < hd:
					hd = dd
					hit = e
		if hit == null and M.W.has("city"):
			for c in M.cars:
				var cw: Vector3 = M.l2w(c.s, c.x, c.y)
				if seg_dist(b.prev, b.p, cw) < 2.0:
					c.hp -= b.dmg
					hit = c
					sparks(b.p, Color(1.0, 0.75, 0.4), 4)
					break
			if hit != null:
				b.life = 0.0
				hit = null
		if hit != null:
			hit_enemy(hit, b.dmg, b.p)
		if hit != null or b.life <= 0:
			b.node.queue_free()
			pbullets.remove_at(i)
		else:
			b.node.global_position = b.p
	# Gegnerschüsse (relativ zum Spieler)
	var sp := Vector3(M.ship_x, M.ship_y, 0)
	for i in range(ebullets.size() - 1, -1, -1):
		var b: Dictionary = ebullets[i]
		b.prev = b.p
		b.p += b.v * dt
		var rm: bool = b.p.z > 30 or b.p.z < -500 or absf(b.p.x) > 120
		if b.has("burst"):
			b.burst -= dt
			if b.burst <= 0 and not rm:
				for k in 8:
					var a := k / 8.0 * TAU
					spawn_ebullet(b.p.x, b.p.y, b.p.z, Vector3(cos(a) * 13, sin(a) * 13, 0) + b.v * 0.7)
				sparks(w_of(b.p.x, b.p.y, b.p.z), Color(1.0, 0.63, 0.25), 10)
				rm = true
		if not rm and alive and seg_dist(b.prev, b.p, sp) < 2.05:
			if roll_t > 0:
				b.v *= -1.2
			else:
				damage_player(b.dmg)
				sparks(w_of(b.p.x, b.p.y, b.p.z), Color(1.0, 0.42, 0.48), 10)
				rm = true
		if rm:
			b.node.queue_free()
			ebullets.remove_at(i)
		else:
			b.node.global_position = w_of(b.p.x, b.p.y, b.p.z)
	# Raketen
	for i in range(missiles.size() - 1, -1, -1):
		var m: Dictionary = missiles[i]
		m.life -= dt
		m.speed = minf(220, m.speed + 240 * dt)
		if m.target != null and not m.target.alive:
			m.target = _missile_target(m.p)
		if m.target != null:
			var tp := Vector3(m.target.x, m.target.y, m.target.z)
			m.v = m.v.lerp((tp - m.p).normalized() * m.speed, minf(1, dt * (3 + (5 - m.life) * 2)))
		else:
			m.v.z -= 150 * dt
		m.p += m.v * dt
		var wpos := w_of(m.p.x, m.p.y, m.p.z)
		m.node.global_position = wpos
		var ahead := w_of(m.p.x + m.v.x * 0.05, m.p.y + m.v.y * 0.05, m.p.z + m.v.z * 0.05)
		if ahead.distance_to(wpos) > 0.01:
			m.node.look_at(ahead, Vector3.UP)
		if rng.randf() < 0.5:
			smoke(wpos, 0.6)
		var done: bool = m.life <= 0 or m.p.z < -420
		if m.target != null and m.p.distance_to(Vector3(m.target.x, m.target.y, m.target.z)) < m.target.radius + 1.2:
			hit_enemy(m.target, 0.0 if m.target.invul else 14.0, wpos)
			boom(wpos, 0.8)
			done = true
		if done:
			m.node.queue_free()
			missiles.remove_at(i)
	# Power-ups
	for i in range(pickups.size() - 1, -1, -1):
		var p: Dictionary = pickups[i]
		p.z += 40 * dt
		if p.z > -45 and alive:
			var f := minf(1, dt * (5.0 if p.z > -20 else 1.5))
			p.x += (M.ship_x - p.x) * f
			p.y += (M.ship_y - p.y) * f
		p.t += dt
		p.model.rotation.y += dt * 2.4
		p.model.rotation.x = sin(time * 1.7) * 0.35
		p.halo.scale = Vector3.ONE * (6.5 + sin(p.t * 7) * 1.6)
		p.node.global_position = w_of(p.x, p.y, p.z)
		var rm2: bool = p.z > 20
		if not rm2 and alive and absf(p.z) < 2.2 and Vector2(p.x - M.ship_x, p.y - M.ship_y).length() < 2.8:
			collect(p)
			rm2 = true
		if rm2:
			p.node.queue_free()
			pickups.remove_at(i)
	_update_fx(dt)
	trauma = maxf(0, trauma - dt * 1.4)
	_update_hud(dt)

func _missile_target(from: Vector3):
	var best = null
	var bd := 1e9
	for e in enemies:
		if not e.alive or e.invul or e.z > -5:
			continue
		var d: float = Vector3(e.x, e.y, e.z).distance_to(from) + (80.0 if e.env else 0.0)
		if d < bd:
			bd = d
			best = e
	return best

func _update_hud(dt: float) -> void:
	l_wave.text = "WELLE %d" % wave
	l_mult.text = ("x%d KOMBO" % mult) if mult > 1 else ""
	b_mis.text = "RAKETEN %d" % nmis
	b_nuke.text = "☢ %d" % nukes
	b_roll.modulate.a = 0.5 if roll_cd > 0 else 1.0
	if banner_t > 0:
		banner_t -= dt
		l_banner.modulate.a = clampf(banner_t, 0, 1)
		l_banner2.modulate.a = clampf(banner_t, 0, 1)
	if toast_t > 0:
		toast_t -= dt
		l_toast.modulate.a = clampf(toast_t, 0, 1)
	if lock != null and state == "play":
		var cam: Camera3D = M.cam
		if not cam.is_position_behind(lock.wp):
			var sp := cam.unproject_position(lock.wp)
			var vs := get_viewport().get_visible_rect().size
			var k := 1280.0 / vs.x
			lock_mk.position = sp * k - Vector2(30, 28)
			lock_mk.visible = true
		else:
			lock_mk.visible = false
	else:
		lock_mk.visible = false

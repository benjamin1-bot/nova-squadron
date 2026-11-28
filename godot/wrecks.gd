extends Node
## Großkampfschiff-Wracks (Kreuzer, Zerstörer, Keil, Träger) und Durchflug durch ein Wrack-Hangardeck – Port aus der HTML-Version

var M
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var m_wreck: StandardMaterial3D
var m_dark: StandardMaterial3D
var m_rust: StandardMaterial3D
var m_haz: StandardMaterial3D
var m_win: StandardMaterial3D
var m_winb: StandardMaterial3D
var box: BoxMesh
var cyl: CylinderMesh
var tube: CylinderMesh
var sph: SphereMesh
var HSEC: Array = []
var WSEC := [[0, 1], [0.18, 0.86], [0.42, 0.5], [0.8, 0.16], [1, 0], [0.96, -0.12], [0.6, -0.3], [0.25, -0.38], [0, -0.4], [-0.25, -0.38], [-0.6, -0.3], [-0.96, -0.12], [-1, 0], [-0.8, 0.16], [-0.42, 0.5], [-0.18, 0.86]]

func setup(main) -> void:
	M = main
	rng.seed = 99
	noise.seed = 5
	noise.frequency = 1.0
	m_wreck = _mat(Color(0.44, 0.45, 0.48), 0.75, 0.45)
	m_dark = _mat(Color(0.16, 0.16, 0.18), 0.7, 0.5)
	m_rust = _mat(Color(0.46, 0.29, 0.19), 0.35, 0.8)
	m_haz = _mat(Color(0.92, 0.66, 0.14), 0.25, 0.6)
	m_win = StandardMaterial3D.new()
	m_win.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_win.albedo_color = Color(1.0, 0.82, 0.5) * 1.5
	m_winb = StandardMaterial3D.new()
	m_winb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m_winb.albedo_color = Color(0.45, 0.8, 1.0) * 1.5
	box = BoxMesh.new()
	cyl = CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 14
	tube = CylinderMesh.new()
	tube.top_radius = 0.5
	tube.bottom_radius = 0.5
	tube.height = 1.0
	tube.radial_segments = 14
	tube.cap_top = false
	tube.cap_bottom = false
	sph = SphereMesh.new()
	for k in 22:
		var a := PI / 2 - float(k) / 22 * TAU
		var c := cos(a)
		var s := sin(a)
		HSEC.append([signf(c) * pow(absf(c), 2 / 3.2), signf(s) * pow(absf(s), 2 / 3.2) * (0.9 if s < 0 else 1.0)])

func _mat(col: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.metallic = metal
	m.roughness = rough
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if M.outline_mat != null:
		m.next_pass = M.outline_mat
	return m

func rand(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func mk(mesh: Mesh, mat: Material, sx: float, sy: float, sz: float, x := 0.0, y := 0.0, z := 0.0, rx := 0.0, ry := 0.0, rz := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.rotation_order = EULER_ORDER_XYZ
	mi.position = Vector3(x, y, z)
	mi.rotation = Vector3(rx, ry, rz)
	mi.scale = Vector3(sx, sy, sz)
	return mi

# ---------- Rumpf als Querschnitt-Loft ----------
func loft(L: float, prof: Callable, sec: Array, nr := 34, dmg := 1.0, cap_a := true, cap_b := true, hole := Callable()) -> ArrayMesh:
	var ns := sec.size()
	var pts: Array = []
	var sd := rand(0, 50)
	for r in nr:
		var t := float(r) / (nr - 1)
		var z := -L / 2 + t * L
		var p: Dictionary = prof.call(t)
		for k in ns:
			var sx: float = sec[k][0]
			var sy: float = sec[k][1]
			var d := 1.0
			var n := noise.get_noise_3d(sx * 2.5 + sd, sy * 2.5, z * 0.05) * 0.5 + 0.5
			if n > 0.66:
				d -= (n - 0.66) * 1.3 * dmg
			d += noise.get_noise_3d(sx * 9, sy * 9 + sd, z * 0.4) * 0.025 * dmg
			pts.append(Vector3(sx * p.w * d, sy * p.h * d + p.get("y", 0.0), z))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in nr - 1:
		for k in ns:
			if hole.is_valid() and hole.call(float(r) / (nr - 1), k):
				continue
			var a: Vector3 = pts[r * ns + k]
			var b: Vector3 = pts[r * ns + (k + 1) % ns]
			var c: Vector3 = pts[(r + 1) * ns + k]
			var d2: Vector3 = pts[(r + 1) * ns + (k + 1) % ns]
			for v in [a, c, b, b, c, d2]:
				st.add_vertex(v)
	if cap_a:
		var p0: Dictionary = prof.call(0.0)
		var ca := Vector3(0, p0.get("y", 0.0), -L / 2)
		for k in ns:
			for v in [ca, pts[k], pts[(k + 1) % ns]]:
				st.add_vertex(v)
	if cap_b:
		var p1: Dictionary = prof.call(1.0)
		var cb := Vector3(0, p1.get("y", 0.0), L / 2)
		var o := (nr - 1) * ns
		for k in ns:
			for v in [cb, pts[o + (k + 1) % ns], pts[o + k]]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func _hull(L: float, prof: Callable, mat: Material, sec: Array, cap_a: bool, cap_b: bool, hole := Callable(), nr := 34) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = loft(L, prof, sec, nr, 1.0, cap_a, cap_b, hole)
	mi.material_override = mat
	return mi

func cruiser_prof(W: float, H: float) -> Callable:
	return func(t: float) -> Dictionary:
		var pr := minf(1.0, t / 0.3)
		var stp := 1.0 - (t - 0.9) * 2.2 if t > 0.9 else 1.0
		return {"w": W * (0.16 + 0.84 * pow(pr, 0.6)) * stp, "h": H * (0.42 + 0.58 * pow(pr, 0.45)) * maxf(0.82, stp), "y": -H * 0.18 * (1 - pr)}

func destroyer_prof(W: float, H: float) -> Callable:
	return func(t: float) -> Dictionary:
		var pr := minf(1.0, t / 0.45)
		return {"w": W * (0.1 + 0.9 * pow(pr, 0.85)), "h": H * (0.35 + 0.65 * sqrt(pr)), "y": H * 0.1 * (1 - pr)}

# ---------- Details ----------
func add_break(g: Node3D, p: Dictionary, z0: float, dir: float) -> void:
	var py: float = p.get("y", 0.0)
	for i in 4:
		var zz := z0 - dir * i * 4.2
		var sc := 0.97 - i * 0.01
		for k in HSEC.size():
			if rng.randf() < 0.22:
				continue
			var a: Array = HSEC[k]
			var b: Array = HSEC[(k + 1) % HSEC.size()]
			var ax: float = a[0] * p.w * sc
			var ay: float = a[1] * p.h * sc + py
			var bx: float = b[0] * p.w * sc
			var by: float = b[1] * p.h * sc + py
			var L := Vector2(bx - ax, by - ay).length()
			g.add_child(mk(box, m_dark, L, 1.1, 1.1, (ax + bx) / 2, (ay + by) / 2, zz, 0, 0, atan2(by - ay, bx - ax)))
	for k in HSEC.size():
		if rng.randf() < 0.4:
			continue
		var a: Array = HSEC[k]
		var l := rand(3, 12)
		g.add_child(mk(box, m_dark if rng.randf() < 0.5 else m_rust, 0.7, 0.7, l, a[0] * p.w * 0.95, a[1] * p.h * 0.95 + py, z0 + dir * l / 2, rand(-0.25, 0.25), rand(-0.25, 0.25)))
	for k in 7:
		var a: Array = HSEC[rng.randi() % HSEC.size()]
		g.add_child(mk(box, m_wreck if rng.randf() < 0.5 else m_rust, rand(3, 9), 0.35, rand(3, 8), a[0] * p.w, a[1] * p.h + py, z0 + dir * rand(1, 5), rand(-1, 1), rand(-1, 1), rand(-1, 1)))
	for k in 3:
		var f := MeshInstance3D.new()
		f.mesh = sph
		f.material_override = M.game.bm([Color(1.0, 0.42, 0.12), Color(1.0, 0.6, 0.25), Color(1.0, 0.19, 0.06)][k], 3.0)
		f.position = Vector3(rand(-0.6, 0.6) * p.w, rand(-0.5, 0.5) * p.h + py, z0 - dir * rand(1, 8))
		f.scale = Vector3.ONE * rand(0.8, 1.6)
		g.add_child(f)

func add_turret(g: Node3D, x: float, y: float, z: float, s: float, up := 1.0) -> void:
	var t := Node3D.new()
	t.add_child(mk(cyl, m_dark, 2.6 * s, 1 * s, 2.6 * s, 0, 0.5 * s * up, 0))
	t.add_child(mk(box, m_wreck, 2.4 * s, 1.3 * s, 3 * s, 0, 1.5 * s * up, 0.2 * s))
	var n := 2 + rng.randi() % 2
	for i in n:
		t.add_child(mk(cyl, m_dark, 0.32 * s, 4.5 * s, 0.32 * s, (i - (n - 1) / 2.0) * 0.7 * s, 1.5 * s * up, -3.2 * s, PI / 2 + rand(-0.15, 0.25)))
	t.position = Vector3(x, y, z)
	t.rotation.y = rand(-1.2, 1.2)
	if up < 0:
		t.rotation.z = PI
	g.add_child(t)

func add_tower(g: Node3D, x: float, y: float, z: float, s: float) -> void:
	var t := Node3D.new()
	var yy := 0.0
	for i in 3:
		var w := (7 - i * 1.8) * s
		var h := (3.2 - i * 0.4) * s
		var d := (10 - i * 2.5) * s
		t.add_child(mk(box, m_dark if i == 1 else m_wreck, w, h, d, 0, yy + h / 2, i * s))
		t.add_child(mk(box, m_win, w + 0.1, 0.5 * s, d * 0.8, 0, yy + h * 0.6, i * s))
		yy += h
	for i in 3:
		t.add_child(mk(cyl, m_dark, 0.18 * s, rand(3, 7) * s, 0.18 * s, rand(-1.5, 1.5) * s, yy + 2 * s, rand(-1, 2) * s, 0, 0, rand(-0.25, 0.25)))
	t.add_child(mk(sph, m_wreck, 1.6 * s, 0.8 * s, 1.6 * s, 0, yy + 0.6 * s, -2 * s, -0.8))
	t.position = Vector3(x, y, z)
	g.add_child(t)

func add_hull_detail(g: Node3D, prof: Callable, L: float, z0: float, t0: float, t1: float) -> void:
	var t := t0 + 0.03
	while t < t1 - 0.02:
		var p: Dictionary = prof.call(t)
		var py: float = p.get("y", 0.0)
		var z := z0 + (t - t0) * L
		for k in [1, 2, HSEC.size() - 1, HSEC.size() - 2]:
			if rng.randf() < 0.45:
				var a: Array = HSEC[k]
				g.add_child(mk(box, [m_wreck, m_dark, m_rust][rng.randi() % 3], rand(2, 5), 0.5, rand(3, 7), a[0] * p.w * 1.01, a[1] * p.h * 1.01 + py, z, 0, 0, atan2(a[1], a[0]) - PI / 2))
		if rng.randf() < 0.5:
			for sx in [-1.0, 1.0]:
				g.add_child(mk(box, m_win if rng.randf() < 0.85 else m_winb, 0.15, 0.9, rand(4, 9), sx * p.w * 0.995, p.h * 0.05 + py, z))
		t += rand(0.025, 0.05)

# ---------- Wrack-Arten ----------
func make_capital(kind: String) -> Node3D:
	var g := Node3D.new()
	var des := kind == "destroyer"
	var L := rand(150, 200) if des else rand(190, 260)
	var W := rand(11, 15) if des else rand(18, 25)
	var H := W * rand(0.55, 0.68)
	var prof := destroyer_prof(W, H) if des else cruiser_prof(W, H)
	var brk := rand(0.5, 0.68)
	var gap := rand(10, 22)
	var mat := m_wreck if rng.randf() < 0.75 else m_rust
	var La := L * brk
	var Lb := L * (1 - brk)
	var fa := Node3D.new()
	var fb := Node3D.new()
	fa.add_child(_hull(La, func(t): return prof.call(t * brk), mat, HSEC, true, false, func(t, _k): return t > 0.93 and rng.randf() < 0.45))
	fb.add_child(_hull(Lb, func(t): return prof.call(brk + t * (1 - brk)), mat, HSEC, false, true, func(t, _k): return t < 0.07 and rng.randf() < 0.45))
	add_break(fa, prof.call(brk), La / 2, 1)
	add_break(fb, prof.call(brk), -Lb / 2, -1)
	add_hull_detail(fa, prof, L, -La / 2, 0, brk)
	add_hull_detail(fb, prof, L, -Lb / 2, brk, 1)
	for i in (3 if des else 4):
		var t := rand(0.18, 0.9)
		var p: Dictionary = prof.call(t)
		var tgt := fa if t < brk else fb
		var z := -La / 2 + t * L if t < brk else -Lb / 2 + (t - brk) * L
		add_turret(tgt, rand(-0.3, 0.3) * p.w, p.h + p.get("y", 0.0) - 0.3, z, 0.9 if des else 1.25)
		if rng.randf() < 0.5:
			add_turret(tgt, 0, -p.h + p.get("y", 0.0) + 0.3, z + 4, 1.0, -1.0)
	var tt := 0.72 if des else 0.66
	var pt: Dictionary = prof.call(tt)
	add_tower(fa if tt < brk else fb, 0, pt.h + pt.get("y", 0.0) - 0.6, (-La / 2 + tt * L) if tt < brk else (-Lb / 2 + (tt - brk) * L), 1.0 if des else 1.5)
	var pe: Dictionary = prof.call(0.97)
	var ne := 2 if des else 3 + rng.randi() % 2
	for i in ne:
		var x: float = (i - (ne - 1) / 2.0) * pe.w * 0.6
		fb.add_child(mk(tube, m_dark, pe.h * 0.7, 8, pe.h * 0.7, x, pe.get("y", 0.0) - pe.h * 0.1, Lb / 2 + 3, PI / 2))
		fb.add_child(mk(cyl, m_rust, pe.h * 0.55, 2, pe.h * 0.55, x, pe.get("y", 0.0) - pe.h * 0.1, Lb / 2 + 1, PI / 2))
	fa.position.z = -L / 2 + La / 2
	fb.position = Vector3(rand(-6, 6), rand(-6, 6), -L / 2 + La + gap + Lb / 2)
	fb.rotation = Vector3(rand(-0.12, 0.12), rand(-0.18, 0.18), rand(-0.45, 0.45))
	g.add_child(fa)
	g.add_child(fb)
	for i in 12:
		g.add_child(mk(box, [m_wreck, m_dark, m_rust][rng.randi() % 3], rand(1.5, 6), rand(0.3, 1), rand(1.5, 5), rand(-W, W), rand(-H, H), -L / 2 + La + gap * rng.randf(), rand(0, 6), rand(0, 6), rand(0, 6)))
	g.set_meta("L", L)
	return g

func make_wedge() -> Node3D:
	var g := Node3D.new()
	var L := rand(220, 300)
	var W := rand(42, 58)
	var H := W * rand(0.3, 0.38)
	var prof := func(t: float) -> Dictionary:
		return {"w": W * (0.04 + 0.96 * pow(t, 0.9)), "h": H * (0.18 + 0.82 * pow(t, 0.8)), "y": 0.0}
	var brk := rand(0.55, 0.72)
	var La := L * brk
	var Lb := L * (1 - brk)
	var gap := rand(14, 30)
	var fa := Node3D.new()
	var fb := Node3D.new()
	fa.add_child(_hull(La, func(t): return prof.call(t * brk), m_wreck, WSEC, true, false, func(t, _k): return t > 0.92 and rng.randf() < 0.45, 30))
	fb.add_child(_hull(Lb, func(t): return prof.call(brk + t * (1 - brk)), m_wreck, WSEC, false, true, func(t, _k): return t < 0.08 and rng.randf() < 0.45, 16))
	var t := 0.06
	while t < 0.98:
		var p: Dictionary = prof.call(t)
		var tgt := fa if t < brk else fb
		var z := -La / 2 + t * L if t < brk else -Lb / 2 + (t - brk) * L
		for sx in [-1.0, 1.0]:
			if rng.randf() < 0.55:
				tgt.add_child(mk(box, [m_wreck, m_dark, m_rust][rng.randi() % 3], rand(2, 6), 0.5, rand(3, 8), sx * p.w * rand(0.3, 0.75), p.h * rand(0.55, 0.85), z, 0, 0, -sx * 0.55))
			if rng.randf() < 0.5:
				tgt.add_child(mk(box, m_win, 0.2, 0.7, rand(4, 10), sx * p.w * 0.97, -0.05 * p.h, z))
		if rng.randf() < 0.18:
			add_turret(tgt, rand(-0.4, 0.4) * p.w, p.h * 0.9, z, 1.3)
		t += rand(0.02, 0.04)
	var p8: Dictionary = prof.call(0.8)
	var z8 := -Lb / 2 + (0.8 - brk) * L
	var yy: float = p8.h * 0.9
	for i in 4:
		var w: float = p8.w * (0.55 - i * 0.11)
		var d := L * (0.16 - i * 0.025)
		var h := H * (0.16 - i * 0.015)
		fb.add_child(mk(box, m_wreck if i % 2 == 0 else m_dark, w * 2, h, d, 0, yy + h * 0.4, z8 + i * d * 0.15))
		fb.add_child(mk(box, m_win, w * 1.4, 0.5, 0.2, 0, yy + h * 0.3, z8 + i * d * 0.15 - d / 2))
		yy += h * 0.75
	add_tower(fb, 0, yy, z8 + L * 0.04, 2.2)
	var pb: Dictionary = prof.call(brk)
	add_break(fa, {"w": pb.w * 0.98, "h": pb.h, "y": 0.0}, La / 2, 1)
	add_break(fb, {"w": pb.w, "h": pb.h, "y": 0.0}, -Lb / 2, -1)
	fa.position.z = -L / 2 + La / 2
	fb.position = Vector3(rand(-8, 8), rand(-8, 8), -L / 2 + La + gap + Lb / 2)
	fb.rotation = Vector3(rand(-0.1, 0.1), rand(-0.15, 0.15), rand(-0.5, 0.5))
	g.add_child(fa)
	g.add_child(fb)
	g.set_meta("L", L)
	return g

## Wrack als Kulisse seitlich der Flugbahn
func spawn_derelict(sv: float) -> void:
	var r := rng.randf()
	var g: Node3D = make_wedge() if r < 0.4 else make_capital("cruiser" if r < 0.7 else "destroyer")
	var L: float = g.get_meta("L")
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var dist := rand(100, 140) if r < 0.4 else rand(70, 110)
	M.add_child(g)
	var tr: Transform3D = M.frame(sv + L * 0.3)
	var rot := Vector3(rand(-0.15, 0.15), rand(-0.3, 0.3) + (PI if rng.randf() < 0.3 else 0.0), rand(-0.45, 0.45))
	g.global_transform = Transform3D(tr.basis * Basis.from_euler(rot), tr.origin + tr.basis.x * side * dist + tr.basis.y * rand(-35, 25))
	M.rocks.append({"node": g, "s": sv + L * 0.8, "x": side * dist, "y": 0.0, "r": L * 0.5, "hard": false, "big": true})

# ---------- Durchflug durch das Hangardeck eines Trägerwracks ----------
func _rail_loft(s0: float, ln: float, cx: float, cy: float, hw: float, hh: float, sec: Array, mat: Material, rough: float, hole := Callable(), step := 3.0) -> MeshInstance3D:
	var rings := int(round(ln / step)) + 1
	var ns := sec.size()
	var pts: Array = []
	for r in rings:
		var sv := s0 + r * step
		var fr: Transform3D = M.frame(sv)
		for k in ns:
			var n := noise.get_noise_3d(sec[k][0] * 3 + cx * 0.1, sec[k][1] * 3, sv * 0.06)
			var d := 1 + n * rough
			var x: float = cx + sec[k][0] * hw * d
			var y: float = cy + sec[k][1] * hh * d
			pts.append(fr.origin + fr.basis.x * x + fr.basis.y * y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in rings - 1:
		for k in ns:
			if hole.is_valid() and hole.call(s0 + r * step, k):
				continue
			var a: Vector3 = pts[r * ns + k]
			var b: Vector3 = pts[r * ns + (k + 1) % ns]
			var c: Vector3 = pts[(r + 1) * ns + k]
			var d2: Vector3 = pts[(r + 1) * ns + (k + 1) % ns]
			for v in [a, b, c, b, d2, c]:
				st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	M.add_child(mi)
	return mi

func _hsec(n: int, e: float) -> Array:
	var out: Array = []
	for k in n:
		var a := float(k) / n * TAU
		var c := cos(a)
		var s := sin(a)
		out.append([signf(c) * pow(absf(c), 2 / e), signf(s) * pow(absf(s), 2 / e)])
	return out

func _stat(n: Node3D, sv: float, x: float, y: float, nodes: Array) -> void:
	M.add_child(n)
	var tr: Transform3D = M.frame(sv)
	n.global_transform = Transform3D(tr.basis, tr.origin + tr.basis.x * x + tr.basis.y * y)
	nodes.append(n)

func spawn_hangar(s0: float, ln: float) -> Array:
	var nodes: Array = []
	var W := 30.0
	var H := 21.0
	var sec := _hsec(28, 7.0)
	var sd := rand(0, 99)
	var hole := func(sv: float, k: int) -> bool:
		var a := float(k) / 28 * TAU
		var sn := sin(a)
		if sn < -0.45 or sv < s0 + 14 or sv > s0 + ln - 14:
			return false
		return noise.get_noise_3d(cos(a) * 2 + sd, sn * 2, sv * 0.03) * 0.5 + 0.5 > 0.67
	var sv := s0
	while sv < s0 + ln - 0.1:
		var l := minf(60.0, s0 + ln - sv)
		nodes.append(_rail_loft(sv, l, 0, 0, W + 3, H + 3, sec, m_wreck, 0.05, hole))
		nodes.append(_rail_loft(sv, l, 0, 0, W + 6, H + 6, sec, m_dark, 0.08, hole))
		nodes.append(_rail_loft(sv, l, -(W + 78), 4, 40, 30, HSEC, m_wreck, 0.07, Callable(), 4.0))
		sv += 60.0
	for k in 4:
		var ss := s0 + ln * (k + 0.5) / 4
		_stat(mk(box, m_dark, 34, 9, 16), ss, -(W + 22), 0, nodes)
	var tg := Node3D.new()
	add_tower(tg, 0, 0, 0, 2.4)
	_stat(tg, s0 + ln * 0.55, -(W + 78), 33, nodes)
	# Mündungen mit Warnstreifen und Landelichtern
	for e in [[s0, true], [s0 + ln, false]]:
		var ss: float = e[0]
		var fr := Node3D.new()
		fr.add_child(mk(box, m_dark, 2 * W + 26, 8, 7, 0, H + 7, 0))
		fr.add_child(mk(box, m_dark, 2 * W + 26, 8, 7, 0, -H - 7, 0))
		fr.add_child(mk(box, m_dark, 8, 2 * H + 22, 7, -W - 7, 0, 0))
		fr.add_child(mk(box, m_dark, 8, 2 * H + 22, 7, W + 7, 0, 0))
		for sy in [-1.0, 1.0]:
			fr.add_child(mk(box, m_haz, 2 * W + 6, 0.9, 7.6, 0, sy * (H + 3.2), 0))
			for i in 12:
				fr.add_child(mk(box, m_dark, 1.2, 0.95, 7.7, -W + i * W / 5.5, sy * (H + 3.2), 0, 0, 0, 0.6))
		if e[1]:
			for i in 10:
				var l := MeshInstance3D.new()
				l.mesh = sph
				l.material_override = M.game.bm(Color(1.0, 0.7, 0.25) if i % 2 else Color(0.25, 0.82, 1.0), 3.0)
				l.scale = Vector3.ONE * 0.6
				l.position = Vector3((i / 9.0 - 0.5) * 2 * W, -H - 4.5, -4)
				fr.add_child(l)
		_stat(fr, ss, 0, 0, nodes)
	# Innenleben: abgestellte Jäger, Deckenlampen, Frachtcontainer
	var x := s0 + 12.0
	while x < s0 + ln - 10:
		for side in [-1.0, 1.0]:
			if rng.randf() < 0.55:
				var f := Node3D.new()
				f.add_child(mk(box, m_wreck, 2.8, 1.2, 7))
				f.add_child(mk(box, m_dark, 9, 0.25, 2.4, 0, -0.1, 1.4))
				f.add_child(mk(sph, m_dark, 0.7, 0.45, 1.4, 0, 0.7, -0.6))
				f.rotation.y = rand(-0.6, 0.6)
				_stat(f, x + rand(-2, 2), side * rand(W * 0.55, W * 0.85), -H + 1.6, nodes)
			elif rng.randf() < 0.5:
				var c := mk(box, m_rust if rng.randf() < 0.5 else m_haz, rand(4, 7), rand(3, 5), rand(6, 10))
				_stat(c, x, side * rand(W * 0.6, W * 0.85), -H + 2, nodes)
		if rng.randf() < 0.6:
			var lamp := Node3D.new()
			lamp.add_child(mk(box, m_dark, 6, 0.6, 2.4))
			lamp.add_child(mk(box, m_win, 5, 0.2, 1.6, 0, -0.35, 0))
			_stat(lamp, x, rand(-W * 0.5, W * 0.5), H + 1.2, nodes)
			var ol := OmniLight3D.new()
			ol.light_color = Color(1.0, 0.8, 0.55)
			ol.light_energy = 1.6
			ol.omni_range = 34.0
			_stat(ol, x, 0, H - 2, nodes)
		x += rand(14, 22)
	return nodes

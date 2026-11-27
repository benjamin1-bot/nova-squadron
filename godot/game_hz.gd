extends "res://game_boss.gd"
## Hindernisse, Geschicklichkeits-Passagen, Welt-Ereignisse, Energiewürfel, Kristalle – Port aus der HTML-Version

const HTML_ORDER := ["ASTEROIDENGÜRTEL KEPLER", "GEFRORENER OZEAN NIFL", "SCHIFFSFRIEDHOF", "LAVAPLANET SURTR", "KRISTALLNEBEL", "OZEANWELT THALASSA",
	"ORBITALSTATION ORION", "PILZWALD MYKOS", "GEWITTERNEBEL", "NEONSTADT VEGA-9", "EREIGNISHORIZONT", "WÜSTENPLANET ARRAKON", "SONNENKORONA HELIOS", "SMARAGDGÜRTEL"]
const EV := {"ASTEROIDENGÜRTEL KEPLER": "crossrocks", "GEFRORENER OZEAN NIFL": "icefall", "SCHIFFSFRIEDHOF": "fuel", "LAVAPLANET SURTR": "eruption",
	"KRISTALLNEBEL": "crystalring", "OZEANWELT THALASSA": "spouts", "ORBITALSTATION ORION": "turrets", "PILZWALD MYKOS": "jellies", "GEWITTERNEBEL": "lightning",
	"NEONSTADT VEGA-9": "neonbars", "EREIGNISHORIZONT": "gravity", "WÜSTENPLANET ARRAKON": "sandstorm", "SONNENKORONA HELIOS": "flare", "SMARAGDGÜRTEL": "spores"}
const LCOLS := [Color("ff30c0"), Color("30e0ff"), Color("60ff80"), Color("ff4020"), Color("ffd020"), Color("a060ff"), Color("ff8020")]

var hazards: Array = []
var statics: Array = []
var obst: Array = []
var cubes: Array = []
var cgates: Array = []
var lanes: Array = []
var popups: Array = []
var spouts: Array = []
var passage = null
var ev_t := 3.0
var col_t := 4.0
var g_pull := 0.0
var g_t := 0.0
var next_cube := 400.0
var crystals := 0
var cube_mat: StandardMaterial3D
var cube_mesh: BoxMesh
var l_cr: Label
var hazard_mat: StandardMaterial3D
var wreck_mat: StandardMaterial3D
var rust_mat: StandardMaterial3D
var station_mat: StandardMaterial3D
var station_or: StandardMaterial3D

func setup(main) -> void:
	super.setup(main)
	cube_mat = pbr(Color("7ff6ff"), 0.2, 0.25, Color("40c0ff"), 1.4)
	cube_mesh = BoxMesh.new()
	cube_mesh.size = Vector3(1.2, 1.2, 1.2)
	hazard_mat = pbr(Color(0.95, 0.75, 0.1), 0.3, 0.5)
	wreck_mat = pbr(Color(0.42, 0.42, 0.45), 0.75, 0.45)
	rust_mat = pbr(Color(0.45, 0.28, 0.18), 0.4, 0.8)
	station_mat = pbr(Color(0.75, 0.77, 0.8), 0.7, 0.35)
	station_or = pbr(Color(1.0, 0.55, 0.15), 0.4, 0.4, Color(1.0, 0.45, 0.1), 0.4)
	crystals = int(M.get_save().get("cr", 0))
	l_cr = _lab(20, Vector2(20, 88), 300.0, Color(0.5, 0.95, 1.0))
	l_cr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if M.has_meta("passage"):
		queue.clear()
		start_passage()

func html_idx() -> int:
	return HTML_ORDER.find(M.W.name)

func spawn_world_enemy() -> void:
	var tbl := ["over", "form", "cloak", "brander", "layer", "form", "over", "cloak", "layer", "form", "cloak", "over", "brander", "layer"]
	var t: String = tbl[maxi(0, html_idx()) % 14]
	match t:
		"form": spawn_formation()
		"cloak": spawn_cloaker()
		"over": spawn_overtaker()
		"layer": spawn_layer()
		_:
			spawn_brander()
			spawn_brander()

func give_crystals(n: int) -> void:
	crystals += n
	M.save_crystals(crystals)

func kill_enemy(e: Dictionary, by_ram: bool) -> void:
	var was: bool = e.alive
	super.kill_enemy(e, by_ram)
	if was and not by_ram and not e.env and not e.has("boss") and e.maxhp >= 5 and rng.randf() < 0.35:
		give_crystals(1)
	if was and e.has("boss") and e.kind == "core":
		give_crystals(10)

# ======================= Statische Bauten an der Bahn =======================
func stat(n: Node3D, sv: float, x: float, y: float, rot := Vector3.ZERO, keep := 40.0) -> Node3D:
	M.add_child(n)
	var tr: Transform3D = M.frame(sv)
	n.global_transform = Transform3D(tr.basis * Basis.from_euler(rot, EULER_ORDER_XYZ), tr.origin + tr.basis.x * x + tr.basis.y * y)
	statics.append({"n": n, "s": sv + keep})
	return n

func add_obst(sv: float, x: float, y: float, hx: float, hy: float, hz: float) -> void:
	obst.append({"s": sv, "x": x, "y": y, "hx": hx, "hy": hy, "hz": hz})

func ground_y(x: float, sv: float) -> float:
	return M.GY + (M.ground_h(x, sv) if M.W.planet else 0.0)

# ======================= Passagen =======================
func maybe_passage() -> bool:
	if wave % 4 != 0 and (wave + 1) % 4 != 0 and (wave % 4 == 1 or rng.randf() < 0.4):
		start_passage()
		return true
	return false

func start_passage() -> void:
	var sp: float = M.s + 320.0
	var sp0 := sp
	var surf: bool = M.W.planet
	var wname: String = M.W.name
	var n := 17 + rng.randi() % 4
	for i in n:
		if sp > sp0 + 1900:
			break
		while M._near_tunnel(sp, 50.0):
			sp += 40.0
		var k := float(i) / n
		if wname == "WÜSTENPLANET ARRAKON" and rng.randf() < 0.45:
			spawn_city_gate(sp, true)
			if rng.randf() < 0.4:
				spawn_city_gate(sp + rand(22, 32), true)
			sp += rand(70, 90) - k * 20
			continue
		if M.W.has("city") and rng.randf() < 0.6:
			if rng.randf() < 0.5:
				spawn_traffic(sp)
			else:
				spawn_city_gate(sp, false)
			sp += rand(70, 90) - k * 20
			continue
		if wname == "ORBITALSTATION ORION" and rng.randf() < 0.4:
			spawn_pop_group(sp, 1 + int(k * 2.5))
			sp += rand(70, 95)
			continue
		if surf or M.W.has("city"):
			var t: String = pick(["arch", "pillar", "spikes"] if k < 0.3 else ["arch", "arch", "spikes", "spikes", "pillar"])
			if t == "spikes":
				spawn_spikes(sp)
				if k > 0.25 and rng.randf() < 0.7:
					spawn_spikes(sp + 30)
			else:
				spawn_pillar(sp, t == "arch")
		else:
			var t2: String = "beam" if i == 0 else pick(["beam", "beam", "gate", "wall"] if k < 0.3 else (["beam", "beam2", "grid", "gate", "wall"] if k < 0.65 else ["beam2", "beam2", "grid", "gate", "beam"]))
			spawn_hazard(t2, sp)
			if k > 0.15 and rng.randf() < 0.65:
				var zs: float = -(sp + 42 - M.s)
				for j in 2 + int(round(k * 3)):
					var m := spawn_mine(rand(-BX * 0.8, BX * 0.8), rand(-BY * 0.7, BY * 0.7), zs + rand(-8, 8))
					m.vx = 0.0
					m.vy = 0.0
					m.vz = 0.0
					m.env = true
					m.fixed = true
		sp += rand(64, 80) - k * 22
	passage = {"end": sp + 20}
	M.next_tunnel_s = maxf(M.next_tunnel_s, sp + 300)
	banner("GESCHICKLICHKEIT", "FELSPASSAGE – AUSWEICHEN!" if surf else "SPERREN DURCHFLIEGEN · SCHALTER ABSCHIESSEN")
	if not surf:
		toast("GRÜNE ZIELE ÖFFNEN DEN WEG", Color(0.5, 1.0, 0.6))

func _update_waves(dt: float) -> void:
	if passage != null:
		if M.s > passage.end:
			passage = null
			if state == "play":
				add_score(4000)
				toast("PASSAGE GESCHAFFT  +4.000", Color(1.0, 0.82, 0.3))
			start_wave()
		return
	super._update_waves(dt)

# ---------- Felsspitzen, Säulen, Bögen (Planeten) ----------
func _rock_column(sv: float, x: float, y0: float, y1: float, w: float) -> Node3D:
	var g := Node3D.new()
	var h := y1 - y0
	var nseg := maxi(2, int(h / (w * 1.4)))
	for i in nseg:
		var t := (i + 0.5) / nseg
		var mi := MeshInstance3D.new()
		mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
		mi.material_override = M.rock_mat
		var ww := w * (1.15 - t * 0.45) * rand(0.85, 1.1)
		mi.scale = Vector3(ww, h / nseg * 0.9, ww) * 0.5
		mi.position = Vector3(rand(-0.4, 0.4), t * h, rand(-0.4, 0.4))
		mi.rotation = Vector3(0, rand(0, TAU), rand(-0.08, 0.08))
		g.add_child(mi)
	return stat(g, sv, x, y0)

func spawn_spikes(sv: float) -> void:
	var gy := ground_y(0, sv)
	var n := 2 + rng.randi() % 2
	var gap := rand(-BX * 0.6, BX * 0.6)
	for i in n:
		var x := -BX + i * (2 * BX / (n - 1)) + rand(-2.5, 2.5)
		if absf(x - gap) < 6:
			continue
		var top := rand(-BY * 0.1, BY * 0.75)
		var s2 := sv + rand(-6, 6)
		_rock_column(s2, x, gy - 3, top, rand(4.8, 6.8))
		add_obst(s2, x, (gy + top) / 2, 2.9, (top - gy) / 2, 2.6)

func spawn_pillar(sv: float, arch: bool) -> void:
	var gy := ground_y(0, sv)
	if not arch:
		var x := rand(-BX * 0.65, BX * 0.65)
		var top := rand(-BY * 0.2, BY * 0.6)
		_rock_column(sv, x, gy - 3, top, 6.0)
		add_obst(sv, x, (gy + top) / 2, 2.8, (top - gy) / 2, 2.8)
		return
	# Felsbogen: zwei Säulen und ein Bogen darüber, darunter durchfliegen
	var gap := rand(8, 12)
	var cx := rand(-BX * 0.35, BX * 0.35)
	var by := rand(BY * 0.05, BY * 0.5)
	var L := cx - gap - 1.5
	var R := cx + gap + 1.5
	var top := BY + 16
	_rock_column(sv, L, gy - 4, top, 7.5)
	_rock_column(sv, R, gy - 4, top, 7.5)
	var lintel := Node3D.new()
	for i in 6:
		var mi := MeshInstance3D.new()
		mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
		mi.material_override = M.rock_mat
		var t := (i + 0.5) / 6.0
		mi.scale = Vector3((R - L) / 5.0, rand(3.5, 5.5), rand(3, 4)) * 0.5
		mi.position = Vector3(lerpf(L, R, t) - cx, sin(t * PI) * 2.5, 0)
		mi.rotation = Vector3(rand(-0.2, 0.2), rand(0, TAU), rand(-0.2, 0.2))
		lintel.add_child(mi)
	stat(lintel, sv, cx, by + 6)
	add_obst(sv, L, (gy + top) / 2, 3.6, (top - gy) / 2, 3.4)
	add_obst(sv, R, (gy + top) / 2, 3.6, (top - gy) / 2, 3.4)
	add_obst(sv, cx, by + 6, gap + 5, 4.5, 3.6)

# ---------- Weltraum-Sperren: Plasmastrahlen, Gitter, Tore, Wände ----------
func _ring_r() -> float:
	return maxf(BX, BY) + 18.5

func _station_ring(sv: float) -> void:
	var g := Node3D.new()
	var R := _ring_r()
	g.add_child(torus(R, 1.6, TAU, station_mat, 48, 10))
	g.add_child(torus(R + 1.8, 0.5, TAU, mats.bossDark, 48, 6))
	for i in 12:
		var a := i / 12.0 * TAU
		g.add_child(mk("box", mats.bossDark if i % 2 else station_or, 3, 3, 4, cos(a) * R, sin(a) * R, 0, 0, 0, a))
		if i % 3 == 0:
			var l := glow(Color(1.0, 0.45, 0.15), 3, 0.9)
			l.position = Vector3(cos(a) * (R - 2), sin(a) * (R - 2), 1.5)
			g.add_child(l)
	stat(g, sv, 0, 0)

func _pod() -> Node3D:
	var g := Node3D.new()
	g.add_child(mk("sphere", station_mat, 1.6, 1.6, 2))
	g.add_child(mk("cyl", mats.eDark, 1.8, 0.8, 1.8))
	g.add_child(glow(Color(1.0, 0.25, 0.88), 5, 0.9))
	M.add_child(g)
	return g

func _switch(h: Dictionary, hp: float) -> Dictionary:
	var g := Node3D.new()
	g.add_child(mk("cyl", mats.eDark, 2.8, 1.2, 2.8, 0, 0, 0, PI / 2))
	g.add_child(mk("sphere", bm(Color(0.25, 1.0, 0.38)), 1.2, 1.2, 0.8, 0, 0, 0.7))
	g.add_child(glow(Color(0.25, 1.0, 0.38), 5, 0.9))
	var r := MeshInstance3D.new()
	r.mesh = shapes.quad
	r.material_override = glow_mat(Color(0.25, 1.0, 0.31), 0.9, true)
	r.scale = Vector3.ONE * 6
	g.add_child(r)
	var e := add_enemy("switch", g, {"hp": hp, "maxhp": hp, "radius": 2.8, "score": 150, "collide": 0.0, "haz": h, "env": false})
	e.z = -600.0
	e.on_kill = func(): _haz_kill(h, e)
	return e

func spawn_hazard(type: String, sv: float) -> void:
	var h := {"type": type, "s": sv, "t": rand(0, 6), "z": -1000.0, "pz": -1000.0, "done": false, "nodes": [], "lines": []}
	if type == "beam2":
		h.type = "beam"
		h.dbl = true
	if h.type == "beam" or h.type == "grid":
		_station_ring(sv)
		var col: Color = pick(LCOLS)
		if h.type == "beam":
			if h.has("dbl"):
				var a0 := rand(0, PI)
				var w := rand(0.7, 1.2)
				h.lines.append({"mode": "rot", "a0": a0, "w": w, "d0": 0.0, "on": true})
				h.lines.append({"mode": "rot", "a0": a0 + PI / 2, "w": -w, "d0": 0.0, "on": true})
			else:
				var mode: String = pick(["static", "rot", "rot", "slide", "slide"])
				h.lines.append({"mode": mode, "a0": rand(0, PI), "w": pick([-1.0, 1.0]) * rand(0.6, 1.1), "amp": rand(4, BY * 0.8),
					"d0": rand(-BY * 0.5, BY * 0.5) if mode == "static" else 0.0, "on": true})
		else:
			var a0 := rand(0, PI)
			var w2: float = (pick([-1.0, 1.0]) * 0.25) if rng.randf() < 0.5 else 0.0
			for i in 4:
				h.lines.append({"mode": "rot" if w2 != 0.0 else "static", "a0": a0, "w": w2, "d0": (i - 1.5) * 5.2, "on": true})
			for i in 3:
				h.lines.append({"mode": "rot" if w2 != 0.0 else "static", "a0": a0 + PI / 2, "w": w2, "d0": (i - 1) * 5.2, "on": true})
			h.sw = [_switch(h, 3), _switch(h, 3)]
		for l in h.lines:
			var o := MeshInstance3D.new()
			o.mesh = shapes.cyl
			o.material_override = glow_line_mat(col)
			var i2 := MeshInstance3D.new()
			i2.mesh = shapes.cyl
			var im := glow_line_mat(col.lerp(Color.WHITE, 0.6))
			im.albedo_color.a = 1.0
			i2.material_override = im
			M.add_child(o)
			M.add_child(i2)
			l.o = o
			l.i = i2
			l.p1 = _pod()
			l.p2 = _pod()
			h.nodes.append_array([o, i2, l.p1, l.p2])
	elif type == "gate":
		var vert := rng.randf() < 0.5
		var ow := BX + 3
		var oh := BY + 3
		_bulkhead(sv, ow, oh)
		h.vert = vert
		h.ow = ow
		h.oh = oh
		h.open = 0.0
		h.opening = false
		var halves: Array = []
		for sd in [-1.0, 1.0]:
			var g := Node3D.new()
			var w := ow if vert else 2 * ow
			var hh := 2 * oh if vert else oh
			g.add_child(mk("box", wreck_mat, w, hh, 2.4))
			g.add_child(mk("box", hazard_mat, 1.4 if vert else w, hh if vert else 1.4, 2.6, -sd * (w / 2 - 0.7) if vert else 0.0, 0.0 if vert else -sd * (hh / 2 - 0.7), 0))
			for k in range(-2, 3):
				g.add_child(mk("box", mats.eDark, 1 if vert else w, hh if vert else 1, 3, k * w / 5 if vert else 0.0, 0.0 if vert else k * hh / 5, 0))
			var e := add_enemy("gatehalf", g, {"hp": 9.0, "maxhp": 9.0, "radius": minf(w, hh) * 0.55, "score": 200, "collide": 0.0, "haz": h, "sd": sd})
			e.z = -600.0
			halves.append(e)
		h.halves = halves
		h.sw = [_switch(h, 2), _switch(h, 2)]
	else:
		var ow2 := BX + 3
		var oh2 := BY + 3
		_bulkhead(sv, ow2, oh2)
		h.cw = 2 * ow2 / 4
		h.ch = 2 * oh2 / 3
		var panels: Array = []
		for r in 3:
			for c in 4:
				var g := Node3D.new()
				g.add_child(mk("box", pick([wreck_mat, rust_mat]), h.cw - 0.5, h.ch - 0.5, 1.6))
				g.add_child(mk("box", mats.eDark, h.cw - 0.4, 0.5, 1.9, 0, h.ch / 2 - 0.5, 0))
				g.add_child(mk("box", mats.eDark, 0.5, h.ch - 0.4, 1.9, h.cw / 2 - 0.5, 0, 0))
				var e := add_enemy("panel", g, {"hp": 2.0, "maxhp": 2.0, "radius": minf(h.cw, h.ch) * 0.6, "score": 60, "collide": 0.0, "haz": h})
				e.px = -ow2 + (c + 0.5) * h.cw
				e.py = -oh2 + (r + 0.5) * h.ch
				e.z = -600.0
				panels.append(e)
		h.panels = panels
	hazards.append(h)

func _bulkhead(sv: float, ow: float, oh: float) -> void:
	var g := Node3D.new()
	var W := ow + 30
	var H := oh + 24
	g.add_child(mk("box", wreck_mat, 2 * W, H - oh, 10, 0, (oh + H) / 2, 0))
	g.add_child(mk("box", wreck_mat, 2 * W, H - oh, 10, 0, -(oh + H) / 2, 0))
	g.add_child(mk("box", wreck_mat, W - ow, 2 * oh, 10, (ow + W) / 2, 0, 0))
	g.add_child(mk("box", wreck_mat, W - ow, 2 * oh, 10, -(ow + W) / 2, 0, 0))
	for sx in [-1.0, 1.0]:
		g.add_child(mk("box", hazard_mat, 1.5, 2 * oh + 1.6, 10.5, sx * (ow + 0.45), 0, 0))
		g.add_child(mk("box", mats.eDark, 3, 2 * H, 14, sx * (ow + 6), 0, 0))
		g.add_child(mk("box", hazard_mat, 2 * ow + 2.4, 1.5, 10.9, 0, sx * (oh + 0.45), 0))
		g.add_child(mk("box", mats.eDark, 2 * W, 3, 14, 0, sx * (oh + 6), 0))
		g.add_child(mk("box", mats.eDark, 4, 2 * oh + 10, 34, sx * (ow + 3), 0, -12))
		g.add_child(mk("box", mats.eDark, 2 * ow + 10, 4, 34, 0, sx * (oh + 3), -12))
	for i in 6:
		var l := glow(pick([Color(1.0, 0.48, 0.16), Color(1.0, 0.19, 0.12)]), 2.6, 0.85)
		l.position = Vector3(rand(-ow, ow), (-1.0 if rng.randf() < 0.5 else 1.0) * (oh + 1.6), 7.5)
		g.add_child(l)
	stat(g, sv, 0, 0)

func _haz_kill(h: Dictionary, e: Dictionary) -> void:
	if h.type == "grid" or h.type == "beam":
		if not h.lines[0].on:
			return
		for l in h.lines:
			l.on = false
		for x in h.sw:
			if x.alive:
				x.alive = false
		toast("PLASMAGITTER AUS", Color(0.5, 1.0, 0.6))
	elif h.type == "gate":
		if e.type == "gatehalf":
			return
		if h.opening:
			return
		h.opening = true
		for x in h.sw:
			if x.alive and not is_same(x, e):
				x.alive = false
		toast("TOR ÖFFNET SICH", Color(0.5, 1.0, 0.6))

func _update_hazards(dt: float) -> void:
	var Rr := _ring_r() - 0.5
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		h.t += dt
		h.pz = h.z
		h.z = M.s - h.s
		var far: bool = h.z < -470
		var cross: bool = state == "play" and h.pz < 0 and h.z >= 0 and not h.done
		if h.lines.size() > 0:
			for l in h.lines:
				var a: float = l.a0 + l.w * h.t if l.mode == "rot" else l.a0
				var d: float = sin(h.t * l.w * 1.4) * l.amp if l.mode == "slide" else l.d0
				var ux := cos(a)
				var uy := sin(a)
				var nx := -uy
				var ny := ux
				var hl := sqrt(maxf(1, Rr * Rr - d * d))
				var ha := Vector3(nx * d - ux * hl, ny * d - uy * hl, h.z)
				var hb := Vector3(nx * d + ux * hl, ny * d + uy * hl, h.z)
				l.p1.visible = not far
				l.p2.visible = not far
				if not far:
					place(l.p1, ha.x, ha.y, ha.z)
					place(l.p2, hb.x, hb.y, hb.z)
				l.o.visible = l.on and not far
				l.i.visible = l.on and not far
				if l.on and not far:
					beam_between(l.o, ha, hb, 0.7 + 0.12 * sin(time * 30))
					beam_between(l.i, ha, hb, 0.22)
				if cross and l.on and absf(M.ship_x * nx + M.ship_y * ny - d) < 1.5:
					h.done = true
					damage_player(24, true)
			if h.has("sw"):
				for k in h.sw.size():
					var e: Dictionary = h.sw[k]
					if e.alive:
						var l0: Dictionary = h.lines[0]
						var a2: float = (l0.a0 + l0.w * h.t if l0.mode == "rot" else l0.a0) + PI / 2 + (PI if k else 0.0)
						e.x = cos(a2) * (Rr - 2.5)
						e.y = sin(a2) * (Rr - 2.5)
						e.z = h.z + 1.5
		elif h.type == "gate":
			if h.opening:
				h.open = minf(1, h.open + dt * 1.3)
			var off: float = h.open * (h.ow if h.vert else h.oh) * 1.1
			for e in h.halves:
				if e.alive:
					e.x = e.sd * (h.ow / 2 + off) if h.vert else 0.0
					e.y = 0.0 if h.vert else e.sd * (h.oh / 2 + off)
					e.z = h.z
			for k in h.sw.size():
				var e: Dictionary = h.sw[k]
				if e.alive:
					var sd := 1.0 if k else -1.0
					e.x = sd * (h.ow * 0.55 + off) if h.vert else sd * h.ow * 0.45
					e.y = sd * h.oh * 0.3 if h.vert else sd * (h.oh * 0.5 + off)
					e.z = h.z + 1.6
			if cross and h.open < 0.6:
				for e in h.halves:
					if e.alive and ((signf(M.ship_x if M.ship_x != 0 else 1.0) == e.sd) if h.vert else (signf(M.ship_y if M.ship_y != 0 else 1.0) == e.sd)):
						h.done = true
						damage_player(32, true)
						trauma = 1.0
						kill_enemy(e, true)
						break
		else:
			for e in h.panels:
				if e.alive:
					e.x = e.px
					e.y = e.py
					e.z = h.z
			if cross:
				for e in h.panels:
					if e.alive and absf(M.ship_x - e.px) < h.cw / 2 and absf(M.ship_y - e.py) < h.ch / 2:
						h.done = true
						damage_player(28, true)
						kill_enemy(e, true)
						break
		if h.z > 40:
			for n in h.nodes:
				n.queue_free()
			for key in ["sw", "halves", "panels"]:
				if h.has(key):
					for e in h[key]:
						e.gone = true
						e.alive = false
			hazards.remove_at(i)

# ---------- Neonstadt / Wüste: Lasertore zwischen Gebäuden, Luftstraßen ----------
func spawn_city_gate(sv: float, desert: bool) -> void:
	var g := {"s": sv, "t": 0.0, "z": -999.0, "beams": [], "done": false}
	var X := BX + 9
	var gy := ground_y(0, sv)
	var mode: String = pick(["sweep", "sweep", "sweep2", "static"] if desert else ["sweep", "static", "grid", "sweep2"])
	var col: Color = pick(LCOLS)
	for sx in [-1.0, 1.0]:
		var b := Node3D.new()
		if desert:
			var rk := MeshInstance3D.new()
			rk.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
			rk.material_override = M.rock_mat
			rk.scale = Vector3(9, 2 * BY + 26, 10) * 0.5
			rk.position = Vector3(sx * 6, BY + 6, 0)
			b.add_child(rk)
		else:
			b.add_child(mk("box", M.city_mat, 10, 90, 10, 0, 45, 0))
			for k in 5:
				b.add_child(mk("box", bm(col, 2.0), 10.3, 0.4, 10.3, 0, 8 + k * 16, 0))
		b.add_child(mk("box", mats.bossDark, 1.6, 2 * BY + 8, 2.4, -sx * 1.2, BY + 8, 0))
		b.add_child(mk("box", hazard_mat, 1.7, 1, 2.6, -sx * 1.2, 2 * BY + 12, 0))
		stat(b, sv, sx * (X + 5.5), gy)
	var add := func(o: Dictionary) -> void:
		var m1 := MeshInstance3D.new()
		m1.mesh = shapes.cyl
		m1.material_override = glow_line_mat(col)
		var m2 := MeshInstance3D.new()
		m2.mesh = shapes.cyl
		var im := glow_line_mat(col.lerp(Color.WHITE, 0.45))
		im.albedo_color.a = 1.0
		m2.material_override = im
		M.add_child(m1)
		M.add_child(m2)
		o.m1 = m1
		o.m2 = m2
		g.beams.append(o)
	if mode == "sweep":
		add.call({"ax": "h", "y0": 0.0, "amp": BY * 0.85, "w": rand(1.1, 1.7), "ph": rand(0, 6)})
	elif mode == "sweep2":
		var w := rand(1, 1.5)
		add.call({"ax": "h", "y0": 0.0, "amp": BY * 0.85, "w": w, "ph": 0.0})
		add.call({"ax": "h", "y0": 0.0, "amp": BY * 0.85, "w": w, "ph": PI})
	elif mode == "static":
		var gap := rand(-BY * 0.6, BY * 0.6)
		for y in [-BY * 0.85, -BY * 0.3, BY * 0.25, BY * 0.8]:
			if absf(y - gap) > BY * 0.3:
				add.call({"ax": "h", "y0": y, "amp": 0.0, "w": 0.0, "ph": 0.0})
	else:
		add.call({"ax": "h", "y0": BY * 0.35, "amp": 0.0, "w": 0.0, "ph": 0.0})
		add.call({"ax": "h", "y0": -BY * 0.4, "amp": 0.0, "w": 0.0, "ph": 0.0})
		add.call({"ax": "v", "y0": 0.0, "amp": BX * 0.7, "w": rand(0.7, 1.1), "ph": 0.0})
		add.call({"ax": "v", "y0": 0.0, "amp": BX * 0.7, "w": rand(0.7, 1.1), "ph": PI})
	cgates.append(g)

func spawn_traffic(sv: float) -> void:
	var n := 2 + rng.randi() % 2
	var X := BX + 70
	for i in n:
		var y := -BY * 0.75 + (i + 0.5) * (1.5 * BY / n) + rand(-1.5, 1.5)
		var dir := (1.0 if i % 2 else -1.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		var ls := sv + i * rand(0, 18)
		var road := Node3D.new()
		road.add_child(mk("box", glow_line_mat(Color(0.19, 0.88, 1.0)), 2 * X, 0.15, 5, 0, -1.4, 0))
		road.add_child(mk("box", bm(Color(1.0, 0.19, 0.75)), 2 * X, 0.2, 0.25, 0, -1.35, 2.5))
		road.add_child(mk("box", bm(Color(0.19, 0.88, 1.0)), 2 * X, 0.2, 0.25, 0, -1.35, -2.5))
		M.add_child(road)
		var lane := {"s": ls, "y": y, "dir": dir, "v": rand(26, 40), "cars": [], "road": road}
		var x := -X + rand(0, 10)
		while x < X:
			var c: Node3D = M._make_car(false)
			lane.cars.append({"m": c, "x": x, "alive": true})
			x += rand(12, 22)
		lanes.append(lane)

func _update_city(dt: float) -> void:
	for i in range(lanes.size() - 1, -1, -1):
		var L: Dictionary = lanes[i]
		var X := BX + 70
		var z: float = M.s - L.s
		place(L.road, 0, L.y, z)
		for c in L.cars:
			if not c.alive:
				continue
			c.x += L.dir * L.v * dt
			if c.x > X:
				c.x -= 2 * X
			if c.x < -X:
				c.x += 2 * X
			place(c.m, c.x, L.y, z, Vector3(0, -PI / 2 * L.dir, 0))
			if state == "play" and absf(z) < 2.2 and absf(c.x - M.ship_x) < 3.4 and absf(L.y - M.ship_y) < 1.9:
				c.alive = false
				c.m.visible = false
				boom(c.m.global_position, 1.6)
				damage_player(20, true)
		if z > 40:
			L.road.queue_free()
			for c in L.cars:
				c.m.queue_free()
			lanes.remove_at(i)
	for i in range(cgates.size() - 1, -1, -1):
		var g: Dictionary = cgates[i]
		var pz: float = g.z
		g.t += dt
		g.z = M.s - g.s
		var X := BX + 9.5
		var cross: bool = state == "play" and pz < 0 and g.z >= 0 and not g.done
		for b in g.beams:
			var v: float = b.y0 + sin(g.t * b.w + b.ph) * b.amp
			var ha: Vector3
			var hb: Vector3
			if b.ax == "h":
				ha = Vector3(-X, v, g.z)
				hb = Vector3(X, v, g.z)
			else:
				ha = Vector3(v, BY + 6, g.z)
				hb = Vector3(v, -(BY + 8), g.z)
			beam_between(b.m1, ha, hb, 0.6 + 0.1 * sin(time * 30))
			beam_between(b.m2, ha, hb, 0.2)
			if cross and (absf(M.ship_y - v) if b.ax == "h" else absf(M.ship_x - v)) < 1.3:
				g.done = true
				damage_player(22, true)
				trauma = 0.7
		if cross:
			g.done = true
		if g.z > 40:
			for b in g.beams:
				b.m1.queue_free()
				b.m2.queue_free()
			cgates.remove_at(i)

# ---------- Orbitalstation: Säulen fahren aus dem Boden ----------
func spawn_pop_group(sv: float, n: int) -> void:
	for i in n:
		var ss := sv + i * rand(26, 40)
		_spawn_popup(ss, rand(-BX * 0.7, BX * 0.7))
		if rng.randf() < 0.45:
			_spawn_popup(ss + rand(-4, 4), rand(-BX * 0.7, BX * 0.7))

func _spawn_popup(sv: float, x: float) -> void:
	var y0 := -(BY + 7)
	var shape: String = pick(["cyl", "box", "cone"])
	var top := rand(-BY * 0.25, BY * 0.85)
	var H := top - y0
	var r := rand(2.5, 4) if shape == "box" else rand(2.4, 4.2)
	var g := Node3D.new()
	var p := Node3D.new()
	if shape == "cyl":
		p.add_child(mk("cyl", station_mat, r * 2, H, r * 2, 0, H / 2, 0))
		for k in range(1, 4):
			p.add_child(mk("cyl", station_or, r * 2.08, 0.6, r * 2.08, 0, H * k / 4, 0))
	elif shape == "box":
		p.add_child(mk("box", station_mat, r * 2, H, r * 2, 0, H / 2, 0))
		p.add_child(mk("box", hazard_mat, r * 2.06, 1.2, r * 2.06, 0, H - 1.2, 0))
	else:
		p.add_child(mk("cone", mats.bossDark, r * 2, H, r * 2, 0, H / 2, 0))
	var l := glow(Color(1.0, 0.19, 0.12), 3, 0.9)
	l.position.y = H + 0.8
	p.add_child(l)
	p.scale.y = 0.02
	g.add_child(p)
	g.add_child(mk("box", mats.bossDark, r * 2 + 5, 1.4, r * 2 + 5, 0, -0.7, 0))
	g.add_child(mk("box", hazard_mat, r * 2 + 5.3, 0.3, r * 2 + 5.3, 0, 0, 0))
	stat(g, sv, x, y0)
	popups.append({"s": sv, "x": x, "y0": y0, "r": r, "H": H, "shape": shape, "p": p, "k": 0.0, "hit": false, "up": false})

func _update_popups(dt: float) -> void:
	for i in range(popups.size() - 1, -1, -1):
		var p: Dictionary = popups[i]
		var z: float = M.s - p.s
		if not p.up and z > -150:
			p.up = true
		if p.up and p.k < 1:
			p.k = minf(1, p.k + dt * 2.6)
			p.p.scale.y = maxf(0.02, 1 - pow(1 - p.k, 3))
		if not p.hit and state == "play" and absf(z) < p.r + 0.8:
			var hh: float = p.H * p.p.scale.y
			var yy: float = M.ship_y - p.y0
			if yy < hh + 0.8:
				var rr: float = p.r * (1 - maxf(0, yy) / p.H) if p.shape == "cone" else p.r
				if absf(M.ship_x - p.x) < rr + 0.9:
					p.hit = true
					damage_player(24, true)
		if z > 40:
			popups.remove_at(i)

# ======================= Welt-Ereignisse =======================
func _world_events(dt: float) -> void:
	if state != "play" or boss != null or passage != null:
		return
	if not M._in_tunnel(M.s + 20).is_empty() and not M.W.has("city"):
		col_t -= dt
		if col_t <= 0:
			col_t = rand(5, 8)
			toast("EINSTURZ!", Color(1.0, 0.7, 0.38))
			trauma = minf(1, trauma + 0.5)
			for i in 6:
				later(i * 0.15, func():
					var r := rand(1.4, 2.4)
					var mi := MeshInstance3D.new()
					mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
					mi.material_override = M.tunnel_mat
					var e := add_enemy("thrown", mi, {"hp": 3.0, "maxhp": 3.0, "radius": r * 0.95, "score": 40, "collide": 22.0, "bs": r * 0.5, "env": true})
					e.x = clampf(M.ship_x + rand(-10, 10), -BX, BX)
					e.y = BY + 4
					e.z = rand(-90, -50)
					e.vy = -rand(12, 18)
					e.vz = M.speed * 0.7
					e.spin = Vector3(rand(-2, 2), rand(-2, 2), 0))
		return
	ev_t -= dt
	if ev_t > 0:
		return
	var ev: String = EV.get(M.W.name, "")
	match ev:
		"crossrocks":
			ev_t = rand(1.2, 2.2)
			var sd := -1.0 if rng.randf() < 0.5 else 1.0
			var r := rand(1.8, 3.2)
			var e := _thrown_rock(r, M.rock_mat)
			e.x = sd * (BX + 30)
			e.y = rand(-BY * 0.7, BY * 0.7)
			e.z = rand(-120, -70)
			e.vx = -sd * rand(16, 26)
			e.vy = rand(-2, 2)
			e.vz = M.speed * 0.85
		"icefall":
			ev_t = rand(1.4, 2.4)
			for i in 2:
				var icem := pbr(Color(0.6, 0.9, 1.0), 0.1, 0.12, Color(0.05, 0.3, 0.5), 0.5)
				var g := Node3D.new()
				g.add_child(mk("cone", icem, 2.2, 9, 2.2, 0, 0, 0, PI))
				var e := add_enemy("thrown", g, {"hp": 3.0, "maxhp": 3.0, "radius": 2.2, "score": 50, "collide": 24.0, "env": true})
				e.x = clampf(M.ship_x + rand(-12, 12), -BX, BX)
				e.y = BY + 22
				e.z = rand(-110, -70)
				e.vy = -rand(14, 20)
				e.vz = M.speed * 0.75
				e.spin = Vector3(0, rand(-1, 1), 0)
		"eruption":
			ev_t = rand(1.6, 2.6)
			var x := rand(-BX * 0.8, BX * 0.8)
			for i in 4:
				later(i * 0.12, func():
					var g := Node3D.new()
					g.add_child(mk("sphere", bm(Color(1.0, 0.45, 0.1), 3.0), 1.3, 1.3, 1.3))
					g.add_child(glow(Color(1.0, 0.38, 0.06), 7, 0.9))
					var e := add_enemy("thrown", g, {"hp": 2.0, "maxhp": 2.0, "radius": 1.6, "score": 30, "collide": 18.0, "env": true})
					e.x = x + rand(-3, 3)
					e.y = -BY - 10
					e.z = rand(-80, -60)
					e.vx = rand(-4, 4)
					e.vy = rand(20, 28)
					e.vz = M.speed * 0.7
					e.grav = 14.0
					e.spin = Vector3.ZERO)
			toast("AUSBRUCH!", Color(1.0, 0.5, 0.25))
		"crystalring":
			ev_t = rand(5, 7)
			var a0 := rand(0, 6)
			var z := rand(-200, -160)
			var w := -1.0 if rng.randf() < 0.5 else 1.0
			for i in 7:
				var cm := pbr(M.W.glow, 0.2, 0.2, M.W.glow, 1.5)
				var e := add_enemy("crys", mk("octa", cm, 1.6, 4, 1.6), {"hp": 3.0, "maxhp": 3.0, "radius": 2.4, "score": 40, "collide": 22.0, "env": true})
				e.ca = a0 + i / 7.0 * TAU
				e.cw = w * 0.9
				e.cz = z
				e.z = z
		"turrets":
			ev_t = rand(2.6, 4)
			var sd := -1.0 if rng.randf() < 0.5 else 1.0
			var g := Node3D.new()
			g.add_child(mk("box", mats.bossDark, 4, 2, 4))
			g.add_child(mk("cyl", station_or, 1, 4, 1, 0, 1.4, 1.4, PI / 2))
			g.add_child(glow(Color(1.0, 0.19, 0.12), 3, 0.8))
			var e := add_enemy("gturret", g, {"hp": 8.0, "maxhp": 8.0, "radius": 2.6, "score": 150, "collide": 20.0})
			e.x = sd * (BX + 3)
			e.y = rand(-BY * 0.6, -BY * 0.1)
			e.z = -170.0
			e.fire_t = rand(1, 2)
		"lightning":
			ev_t = rand(1.8, 3)
			var x := clampf(M.ship_x + rand(-6, 6), -BX, BX)
			var p := w_of(x, BY + 30, -60)
			var q := w_of(x + rand(-3, 3), -BY - 12, -60)
			later(0.6, func(): _bolt(p, q, true))
			var warnl := glow(Color(0.7, 1.0, 0.9), 16, 0.6)
			M.add_child(warnl)
			warnl.global_position = p
			fxs.append({"n": warnl, "t": 0.0, "life": 0.7, "k": "ball", "s0": 10.0, "s1": 22.0})
		"gravity":
			ev_t = rand(5, 8)
			g_pull = (-1.0 if rng.randf() < 0.5 else 1.0) * rand(5, 8)
			g_t = 3.5
			toast("GRAVITATION NACH RECHTS!" if g_pull > 0 else "GRAVITATION NACH LINKS!", Color(1.0, 0.7, 0.44))
			for k in 5:
				later(k * 0.35, func():
					var e := _thrown_rock(rand(1.6, 3.6), M.rock_mat)
					var sd2 := signf(g_pull)
					e.x = -sd2 * (BX + rand(30, 55))
					e.y = rand(-BY * 0.9, BY * 0.9)
					e.z = rand(-150, -85)
					e.vx = sd2 * rand(22, 34)
					e.vz = M.speed * rand(0.2, 0.45))
		"sandstorm":
			ev_t = rand(7, 10)
			g_pull = (-1.0 if rng.randf() < 0.5 else 1.0) * rand(4, 6.5)
			g_t = 4.0
			toast("SANDSTURM!", Color(1.0, 0.82, 0.5))
			if rng.randf() < 0.5:
				for k in 1 + rng.randi() % 3:
					_spawn_tank(-rand(170, 240))
		"spouts":
			ev_t = rand(2.8, 4.2)
			_spawn_spout()
		"fuel":
			ev_t = rand(1.4, 2.4)
			var g := Node3D.new()
			var fm := pbr(Color(0.82, 0.12, 0.06), 0.5, 0.4, Color(0.25, 0.03, 0), 1.0)
			g.add_child(mk("cyl", fm, 2.4, 4.5, 2.4, 0, 0, 0, 0, 0, PI / 2))
			g.add_child(mk("box", hazard_mat, 0.4, 2.6, 2.6, 1.2, 0, 0))
			g.add_child(mk("box", hazard_mat, 0.4, 2.6, 2.6, -1.2, 0, 0))
			g.add_child(glow(Color(1.0, 0.25, 0.12), 4, 0.6))
			var e := add_enemy("fuel", g, {"hp": 2.0, "maxhp": 2.0, "radius": 2.4, "score": 60, "collide": 20.0, "env": true})
			e.x = rand(-BX * 0.8, BX * 0.8)
			e.y = rand(-BY * 0.7, BY * 0.7)
			e.z = -170.0
			e.spin = Vector3(rand(-1, 1), rand(-1, 1), rand(-1, 1))
			e.on_kill = func():
				boom(e.wp, 2.2)
				for x2 in enemies:
					if x2.alive and not is_same(x2, e) and Vector3(x2.x - e.x, x2.y - e.y, x2.z - e.z).length() < 9:
						hit_enemy(x2, 6, x2.wp)
				if Vector3(M.ship_x - e.x, M.ship_y - e.y, e.z).length() < 7:
					damage_player(18)
		"jellies":
			ev_t = rand(1.2, 2)
			var jm := pbr(Color(0.5, 1.0, 0.9), 0.1, 0.2, Color(0.12, 0.62, 0.56), 1.0)
			var g := Node3D.new()
			g.add_child(mk("sphere", jm, 2.4, 1.6, 2.4))
			for k in 5:
				var a := k / 5.0 * TAU
				g.add_child(mk("cyl", jm, 0.18, 4, 0.18, cos(a) * 1.2, -2.4, sin(a) * 1.2))
			g.add_child(glow(Color(0.38, 1.0, 0.88), 6, 0.6))
			var e := add_enemy("jelly", g, {"hp": 3.0, "maxhp": 3.0, "radius": 2.4, "score": 70, "collide": 18.0, "env": true})
			e.x = rand(-BX * 0.8, BX * 0.8)
			e.y = rand(-BY * 0.6, BY * 0.5)
			e.z = -170.0
			e.ph = rand(0, 6)
		"neonbars":
			ev_t = rand(3.6, 5.2)
			if rng.randf() < 0.5:
				spawn_traffic(M.s + 300)
			else:
				spawn_city_gate(M.s + 300, false)
		"flare":
			ev_t = rand(5.5, 7.5)
			_solar_flare()
		"spores":
			ev_t = rand(1.6, 2.6)
			var sm := pbr(Color(0.3, 0.85, 0.4), 0.1, 0.5, Color(0.2, 0.9, 0.3), 0.8)
			var g := Node3D.new()
			g.add_child(mk("sphere", sm, 2, 2.4, 2))
			for k in 6:
				var a := k / 6.0 * TAU
				g.add_child(mk("cone", sm, 0.5, 1.6, 0.5, cos(a) * 1.9, sin(a) * 1.9, 0, 0, 0, a - PI / 2))
			g.add_child(glow(Color(0.38, 1.0, 0.44), 5, 0.6))
			var e := add_enemy("spore", g, {"hp": 3.0, "maxhp": 3.0, "radius": 2.4, "score": 80, "collide": 18.0, "env": true})
			e.x = rand(-BX * 0.8, BX * 0.8)
			e.y = rand(-BY * 0.7, BY * 0.7)
			e.z = -180.0
		_:
			ev_t = 99.0

func _thrown_rock(r: float, mat: Material) -> Dictionary:
	var mi := MeshInstance3D.new()
	mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
	mi.material_override = mat
	var e := add_enemy("thrown", mi, {"hp": ceilf(r * 2), "maxhp": ceilf(r * 2), "radius": r * 0.95, "score": 40, "collide": 24.0, "bs": r * 0.5, "env": true})
	e.spin = Vector3(rand(-2, 2), rand(-2, 2), rand(-2, 2))
	return e

func _bolt(p: Vector3, q: Vector3, dmg: bool) -> void:
	var bolt := Node3D.new()
	M.add_child(bolt)
	var mat := glow_line_mat(Color(0.7, 1.0, 0.95))
	mat.albedo_color.a = 1.0
	var pts: Array = [p]
	for i in 8:
		var t := (i + 1) / 9.0
		pts.append(p.lerp(q, t) + Vector3(rand(-3, 3), 0, rand(-3, 3)))
	pts.append(q)
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg := MeshInstance3D.new()
		seg.mesh = shapes.cyl
		seg.material_override = mat
		bolt.add_child(seg)
		var up := (b - a).normalized()
		var side := up.cross(Vector3(0.31, 0.5, 0.81)).normalized()
		seg.global_transform = Transform3D(Basis(side * 0.7, up * a.distance_to(b), side.cross(up) * 0.7), (a + b) * 0.5)
	M.flash_fx = 0.6
	fxs.append({"n": bolt, "t": 0.0, "life": 0.25, "k": "free"})
	if dmg and state == "play":
		var sw := w_of(M.ship_x, M.ship_y, 0)
		var l: Vector3 = (q - p)
		var t2 := clampf((sw - p).dot(l) / l.length_squared(), 0, 1)
		if (p + l * t2).distance_to(sw) < 3.0:
			damage_player(20)

func _solar_flare() -> void:
	# Plasmawand mit Lücke kommt auf dich zu
	var gap_x := rand(-BX * 0.6, BX * 0.6)
	var gap_y := rand(-BY * 0.5, BY * 0.5)
	toast("SONNENERUPTION – LÜCKE SUCHEN!", Color(1.0, 0.6, 0.2))
	var x := -BX
	while x <= BX + 0.1:
		var y := -BY
		while y <= BY + 0.1:
			if Vector2(x - gap_x, y - gap_y).length() >= 5.0:
				var b := spawn_ebullet(x, y, -220, Vector3(0, 0, 70), "orb")
				b.dmg = 14.0
			y += 3.6
		x += 3.6

func _spawn_tank(z: float) -> void:
	var tm := pbr(Color(0.66, 0.52, 0.35), 0.25, 0.85)
	var g := Node3D.new()
	g.add_child(mk("box", tm, 3.8, 1.5, 6))
	for sx in [-1.0, 1.0]:
		g.add_child(mk("box", mats.eDark, 0.9, 1.1, 6.4, sx * 2, -0.5, 0))
	var tur := Node3D.new()
	tur.add_child(mk("sphere", tm, 1.2, 0.55, 1.4))
	tur.add_child(mk("cyl", mats.eDark, 0.32, 3.6, 0.32, 0, 0.2, 2.4, PI / 2))
	tur.position.y = 0.8
	g.add_child(tur)
	g.set_meta("tur", tur)
	var e := add_enemy("tank", g, {"hp": 7.0, "maxhp": 7.0, "radius": 2.8, "score": 220, "collide": 20.0})
	e.x = rand(-BX * 0.9, BX * 0.9)
	e.z = z
	e.vx = pick([-1.0, 1.0]) * rand(4, 9)
	e.fire_t = rand(1, 2.2)

func _spawn_spout() -> void:
	var H := 2 * BY + 34
	var g := Node3D.new()
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.62, 0.75, 0.85, 0.82)
	wm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wm.roughness = 0.3
	wm.emission_enabled = true
	wm.emission = Color(0.05, 0.12, 0.18)
	wm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var prof: Array = []
	for i in 25:
		var t := i / 24.0
		var r := (9 - t / 0.08 * 5.6) if t < 0.08 else ((3.4 + sin(t * 11) * 0.35 + t * 1.6) if t < 0.55 else 4.3 + pow((t - 0.55) / 0.45, 1.6) * 18)
		prof.append(Vector2(r, t * H))
	for i in 24:
		for k in 24:
			var a0 := k / 24.0 * TAU
			var a1 := (k + 1) / 24.0 * TAU
			var A: Vector2 = prof[i]
			var B: Vector2 = prof[i + 1]
			var p := [Vector3(cos(a0) * A.x, A.y, sin(a0) * A.x), Vector3(cos(a1) * A.x, A.y, sin(a1) * A.x), Vector3(cos(a0) * B.x, B.y, sin(a0) * B.x), Vector3(cos(a1) * B.x, B.y, sin(a1) * B.x)]
			for j in [0, 2, 1, 1, 2, 3]:
				st.add_vertex(p[j])
	st.generate_normals()
	var outer := MeshInstance3D.new()
	outer.mesh = st.commit()
	outer.material_override = wm
	g.add_child(outer)
	for i in 5:
		var cl := MeshInstance3D.new()
		cl.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
		cl.material_override = pbr(Color(0.42, 0.48, 0.54), 0.0, 1.0)
		cl.scale = Vector3(rand(12, 22), rand(4, 7), rand(12, 22)) * 0.5
		cl.position = Vector3(rand(-14, 14), H + rand(-1, 4), rand(-14, 14))
		g.add_child(cl)
	M.add_child(g)
	spouts.append({"g": g, "o": outer, "s": M.s + 150, "x": rand(-BX * 0.7, BX * 0.7), "vx": rand(-3, 3), "hit": false, "t": 0.0})
	toast("WASSERHOSE!", Color(0.75, 0.9, 1.0))

func _update_spouts(dt: float) -> void:
	for i in range(spouts.size() - 1, -1, -1):
		var w: Dictionary = spouts[i]
		w.t += dt
		w.x += w.vx * dt
		if absf(w.x) > BX:
			w.vx = -w.vx
		var z: float = M.s - w.s
		var gy: float = M.GY + M.W.get("liquid_y", 0.0)
		place(w.g, w.x + sin(w.t * 1.3) * 0.8, gy, z, Vector3(0, 0, sin(w.t * 0.9) * 0.08))
		w.o.rotation.y += dt * 3.2
		if not w.hit and state == "play" and absf(z) < 3 and absf(M.ship_x - w.x) < 3.6:
			w.hit = true
			damage_player(20, true)
			M.ship_vx += signf(M.ship_x - w.x if M.ship_x != w.x else 1.0) * 14
		if z > 40:
			w.g.queue_free()
			spouts.remove_at(i)

func update_special(e: Dictionary, dt: float, px: float) -> void:
	var sp: float = M.speed
	match e.type:
		"crys":
			e.ca += e.cw * dt
			e.cz += sp * dt
			e.x = cos(e.ca) * BX * 0.62
			e.y = sin(e.ca) * BY * 0.7
			e.z = e.cz
			e.rot.z = e.ca
			e.rot.y += dt * 2
		"tank":
			e.z += sp * dt
			e.x += e.vx * dt
			if absf(e.x) > BX + 6:
				e.vx = -signf(e.x) * absf(e.vx)
			e.y = ground_y(e.x, M.s - e.z) + 1.3
			e.rot = Vector3(0, atan2(e.vx, 0), 0)
			e.fire_t -= dt
			if e.fire_t <= 0 and e.z < -22 and e.z > -170:
				e.fire_t = rand(1.5, 2.4) / diff()
				enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.8)
		"gturret":
			e.z += sp * dt
			e.fire_t -= dt
			if e.fire_t <= 0 and e.z < -25:
				e.fire_t = rand(1.4, 2.2) / diff()
				enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.85)
			e.rot.y = atan2(M.ship_x - e.x, -e.z)
		"fuel":
			e.z += sp * dt
			e.rot += e.spin * dt
		"jelly":
			e.z += sp * 0.75 * dt
			e.y += sin(time * 1.6 + e.ph) * 3 * dt
			e.x += cos(time * 0.9 + e.ph) * 2.5 * dt
		"spore":
			e.z += sp * 0.8 * dt
			e.rot.y += dt
			e.rot.x += dt * 0.6
			if e.z > -26 and not e.has("popped"):
				e.popped = true
				for k in 6:
					var a := k / 6.0 * TAU
					spawn_ebullet(e.x, e.y, e.z, Vector3(cos(a) * 7, sin(a) * 7, 16))
				kill_enemy(e, true)
		"switch", "gatehalf", "panel":
			pass
		"mine":
			pass
		_:
			super.update_special(e, dt, px)

func update_enemy(e: Dictionary, dt: float) -> void:
	if e.type == "mine" and e.has("fixed"):
		e.z += M.speed * dt
	super.update_enemy(e, dt)

# ======================= Energiewürfel =======================
func spawn_cube_set(s0: float) -> void:
	var n := 10
	var cset := {"n": n, "got": 0, "missed": false}
	var pat: String = pick(["line", "sine", "ring", "zig", "spiral"])
	var cx := rand(-BX * 0.5, BX * 0.5)
	var cy := rand(-BY * 0.4, BY * 0.4)
	var dir := -1.0 if rng.randf() < 0.5 else 1.0
	for i in n:
		var t := i / (n - 1.0)
		var x := 0.0
		var y := 0.0
		match pat:
			"line":
				x = dir * (-BX * 0.75 + t * BX * 1.5)
				y = cy + (t - 0.5) * BY * 0.6
			"sine":
				x = cx + sin(t * TAU) * BX * 0.55
				y = cy + cos(t * TAU) * BY * 0.2
			"ring":
				x = cx + cos(t * TAU) * 5
				y = cy + sin(t * TAU) * 5
			"zig":
				x = (1.0 if i % 2 else -1.0) * BX * 0.45 + cx * 0.3
				y = cy
			_:
				var a := t * PI * 3.5
				var r := 2 + t * 7
				x = cx * 0.5 + cos(a) * r
				y = cy * 0.5 + sin(a) * r * 0.7
		x = clampf(x, -BX * 0.9, BX * 0.9)
		y = clampf(y, -BY * 0.8, BY * 0.8)
		var g := Node3D.new()
		var c := MeshInstance3D.new()
		c.mesh = cube_mesh
		c.material_override = cube_mat
		g.add_child(c)
		g.add_child(glow(Color(0.38, 0.91, 1.0), 3, 0.55))
		var ss := s0 + i * (5.0 if pat == "ring" else 7.0)
		M.add_child(g)
		var tr: Transform3D = M.frame(ss)
		g.global_position = tr.origin + tr.basis.x * x + tr.basis.y * y
		cubes.append({"n": g, "c": c, "s": ss, "x": x, "y": y, "set": cset})
	if not seen.has("cubes"):
		seen["cubes"] = true
		toast("ENERGIEWÜRFEL – EINSAMMELN!", Color(0.5, 0.96, 1.0))

func _update_cubes(dt: float) -> void:
	if state == "play" and boss == null and passage == null and M.s > next_cube:
		next_cube = M.s + rand(1400, 2100)
		if not M._near_tunnel(M.s + 240, 80.0):
			spawn_cube_set(M.s + 240)
	for i in range(cubes.size() - 1, -1, -1):
		var c: Dictionary = cubes[i]
		c.c.rotation.x += dt * 2
		c.c.rotation.y += dt * 2.6
		var rm := false
		if state == "play" and absf(M.s - c.s) < 1.9 and Vector2(c.x - M.ship_x, c.y - M.ship_y).length() < 2.8:
			rm = true
			c.set.got += 1
			add_score(50 * mult)
			sparks(c.n.global_position, Color(0.5, 0.96, 1.0), 10)
			if c.set.got == c.set.n and not c.set.missed:
				add_score(1000)
				give_crystals(3)
				toast("PERFEKT! ALLE WÜRFEL +1000 · ◆3", Color(0.5, 0.96, 1.0))
		elif c.s < M.s - 4:
			rm = true
			c.set.missed = true
		if rm:
			c.n.queue_free()
			cubes.remove_at(i)

# ======================= Hauptschleife-Ergänzung =======================
func update(dt: float) -> void:
	super.update(dt)
	_world_events(dt)
	_update_hazards(dt)
	_update_city(dt)
	_update_popups(dt)
	_update_spouts(dt)
	_update_cubes(dt)
	# Gravitation / Sandsturm zieht das Schiff seitlich
	if g_t > 0:
		g_t -= dt
		if state == "play":
			M.ship_x = clampf(M.ship_x + g_pull * dt, -BX, BX)
	# feste Hindernisse (Felsen, Säulen)
	if state == "play" and invul <= 0:
		for o in obst:
			if absf(M.s - o.s) < o.hz + 0.8 and absf(M.ship_x - o.x) < o.hx + 0.8 and absf(M.ship_y - o.y) < o.hy + 0.6:
				damage_player(22, true)
				invul = 0.8
				if o.hx > o.hy:
					M.ship_y += (1.0 if M.ship_y > o.y else -1.0) * 1.5
				else:
					M.ship_x += (1.0 if M.ship_x > o.x else -1.0) * 1.5
				break
	for i in range(obst.size() - 1, -1, -1):
		if obst[i].s < M.s - 20:
			obst.remove_at(i)
	for i in range(statics.size() - 1, -1, -1):
		if statics[i].s < M.s:
			statics[i].n.queue_free()
			statics.remove_at(i)
	l_cr.text = "◆ %d" % crystals

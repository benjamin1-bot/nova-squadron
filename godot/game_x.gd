extends "res://game_hz.gd"
## Overdrive, Rettungsmission mit Flügelmann, geheimer Weg mit Bonus-Zone, Sektor-Auswertung mit Medaille, Warp-Sprung

var sp_meter := 0.0
var od := 0.0
var b_od: Button
var st := {"shots": 0, "hits": 0, "kills": 0, "dmg": 0.0, "score0": 0}
var cr_got := 0
var allies: Array = []
var bonus_t := 0.0
var warp_t := -1.0
var white: ColorRect

func setup(main) -> void:
	super.setup(main)
	b_od = _btn("⚡", Vector2(1040, 500), Vector2(100, 80), try_overdrive)
	white = ColorRect.new()
	white.color = Color(1, 1, 1, 0)
	white.position = Vector2.ZERO
	white.size = Vector2(1280, 720)
	white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(white)
	st.score0 = score

func give_crystals(n: int) -> void:
	super.give_crystals(n)
	cr_got += n

# ---------- Overdrive ----------
func try_overdrive() -> void:
	if state != "play" or od > 0 or sp_meter < 100:
		return
	od = 7.0
	sp_meter = 0.0
	toast("⚡ OVERDRIVE!", Color(0.8, 0.66, 1.0))
	trauma = 0.4
	M.audio.sfx("zap", -4.0)

func _fire(dt: float) -> void:
	if od > 0:
		fire_t -= dt * 1.2
	var before := pbullets.size()
	super._fire(dt)
	var n := pbullets.size() - before
	if n > 0:
		st.shots += n
		if od > 0:
			for i in range(before, pbullets.size()):
				var b: Dictionary = pbullets[i]
				b.dmg *= 2.0
				b.node.scale = Vector3.ONE * 1.3

func hit_enemy(e: Dictionary, dmg: float, at: Vector3) -> void:
	if e.alive and not e.invul and not e.env:
		st.hits += 1
	super.hit_enemy(e, dmg, at)

func kill_enemy(e: Dictionary, by_ram: bool) -> void:
	var was: bool = e.alive
	super.kill_enemy(e, by_ram)
	if was and not e.env and not e.has("haz"):
		st.kills += 1
		sp_meter = minf(100, sp_meter + (3.0 if e.has("boss") else 5.0))

func damage_player(d: float, force := false) -> void:
	var h0: float = M.hull + M.shield
	super.damage_player(d, force)
	st.dmg += maxf(0, h0 - (M.hull + M.shield))

# ---------- Rettungsmission ----------
func make_ally() -> Node3D:
	var g: Node3D = M.build_ship_model(Color(0.2, 0.75, 0.38))
	M.add_child(g)
	return g

func spawn_rescue() -> void:
	var a := {"node": make_ally(), "x": rand(-BX * 0.5, BX * 0.5), "y": rand(-BY * 0.3, BY * 0.4), "z": -90.0, "state": "flee", "t": 0.0, "hp": 100.0, "fire_t": 0.0, "pur": [], "sd": 1.0}
	a.node.scale = Vector3.ONE * 0.75
	allies.append(a)
	for i in 3:
		var e := add_enemy("pursuer", make_fighter(mats.eRed), {"hp": 3.0, "maxhp": 3.0, "radius": 1.9, "score": 200, "collide": 25.0})
		e.ally = a
		e.ox = (i - 1) * 4.0
		e.oy = rand(-2, 2)
		e.x = a.x + e.ox
		e.y = a.y
		e.z = a.z - 30
		a.pur.append(e)
	banner("NOTRUF!", "VERBÜNDETEN RETTEN – JÄGER ABSCHIESSEN", true)
	M.audio.sfx("alarm", -8.0, 0.0)

func _update_allies(dt: float) -> void:
	for i in range(allies.size() - 1, -1, -1):
		var a: Dictionary = allies[i]
		a.t += dt
		if a.state == "flee":
			a.x = sin(a.t * 1.3) * BX * 0.55
			a.y = sin(a.t * 0.9) * BY * 0.4
			a.z += (-60 - a.z) * minf(1, dt)
			var all_dead := true
			for e in a.pur:
				if e.alive:
					all_dead = false
			if all_dead:
				a.state = "wing"
				a.t = 0.0
				toast("GERETTET! FLÜGELMANN FLIEGT MIT", Color(0.5, 1.0, 0.6))
				give_crystals(5)
				add_score(2000)
				a.sd = 1.0 if M.ship_x < 0 else -1.0
			else:
				a.hp -= dt * 10.0
				if a.hp <= 0:
					boom(a.node.global_position, 2.0)
					for e in a.pur:
						if e.alive:
							e.gone = true
					a.node.queue_free()
					allies.remove_at(i)
					toast("VERBÜNDETER VERLOREN", Color(1.0, 0.48, 0.42))
					continue
		elif a.state == "wing":
			var sc: float = a.node.scale.x
			a.node.scale = Vector3.ONE * (sc + (0.42 - sc) * minf(1, dt * 4))
			var tx: float = M.ship_x + a.sd * 2.8
			var ty: float = M.ship_y + 0.15 + sin(a.t * 2.2) * 0.12
			var k := minf(1, dt * 4) if a.t < 1.2 else 1.0
			a.x += (tx - a.x) * k
			a.y += (ty - a.y) * k
			a.z += (0.3 - a.z) * k
			a.fire_t -= dt
			if a.fire_t <= 0:
				a.fire_t = 0.14
				var best = null
				var bd := 1e9
				for e in enemies:
					if not e.alive or e.env or e.invul:
						continue
					var dz: float = -e.z
					if dz < 15 or dz > 200:
						continue
					var d: float = Vector2(e.x - a.x, e.y - a.y).length() + dz * 0.2
					if d < bd:
						bd = d
						best = e
				if best != null:
					var from := w_of(a.x, a.y, a.z - 1)
					_spawn_pbullet(from, (best.wp - from).normalized(), Color(0.38, 1.0, 0.56), 1.6, 1.0)
			if a.t > 9.0 or (boss != null and boss.state == "dying"):
				a.state = "leave"
				toast("FLÜGELMANN DREHT AB", Color(0.5, 0.92, 1.0))
		else:
			a.y += 30 * dt
			a.z -= 60 * dt
			if a.z < -300:
				a.node.queue_free()
				allies.remove_at(i)
				continue
		place(a.node, a.x, a.y, a.z, Vector3(0, 0, sin(a.t * 2) * 0.3), a.node.scale.x)

func update_special(e: Dictionary, dt: float, px: float) -> void:
	match e.type:
		"pursuer":
			var a: Dictionary = e.ally
			if not allies.has(a):
				e.gone = true
				return
			e.x += (a.x + e.ox - e.x) * minf(1, dt * 2.2)
			e.y += (a.y + e.oy - e.y) * minf(1, dt * 2.2)
			e.z += (a.z - 14 - e.z) * minf(1, dt * 2)
			e.rot.y = atan2(a.x - e.x, a.z - e.z)
			e.fire_t -= dt
			if e.fire_t <= 0:
				e.fire_t = rand(0.4, 0.8)
				sparks(a.node.global_position, Color(1.0, 0.19, 0.25), 3)
		"secret":
			e.z += M.speed * dt
			e.rot.z += dt * 0.2
			if e.z > 40:
				e.gone = true
		_:
			super.update_special(e, dt, px)

# ---------- Geheimer Weg: Luke am Rand abschießen ----------
func spawn_secret() -> void:
	var g := Node3D.new()
	if M.W.planet:
		var r := MeshInstance3D.new()
		r.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
		r.material_override = M.rock_mat
		r.scale = Vector3(4, 5, 3) * 0.5
		g.add_child(r)
	else:
		g.add_child(mk("box", mats.eDark, 6, 6, 2))
		g.add_child(mk("box", hazard_mat, 6.4, 0.5, 2.2, 0, 2.8, 0))
	for i in 5:
		g.add_child(mk("box", bm(Color(1.0, 0.82, 0.29)), 0.25, rand(1.5, 3), 0.3, rand(-1.6, 1.6), rand(-1.6, 1.6), 2.6 if M.W.planet else 1.2, 0, 0, rand(-1, 1)))
	g.add_child(glow(Color(1.0, 0.82, 0.29), 5, 0.5))
	var sd := -1.0 if rng.randf() < 0.5 else 1.0
	var e := add_enemy("secret", g, {"hp": 5.0, "maxhp": 5.0, "radius": 3.4, "score": 500, "collide": 0.0, "env": true})
	e.x = sd * (BX + 1)
	e.y = rand(-BY * 0.6, BY * 0.6)
	e.z = -300.0
	e.on_kill = start_bonus

func start_bonus() -> void:
	bonus_t = 22.0
	for e in enemies:
		if e.alive and not e.has("boss") and not e.env:
			e.alive = false
	banner("GEHEIMER WEG!", "BONUS-ZONE – ALLES EINSAMMELN", true)
	M.audio.sfx("whoosh", -2.0, 0.0)
	for i in 4:
		spawn_cube_set(M.s + 120 + i * 170)
	later(3.0, func(): spawn_pickup(rand(-8, 8), rand(-4, 4), -200, pick(["P", "X", "Z"])))
	later(8.0, func(): spawn_pickup(rand(-8, 8), rand(-4, 4), -200, "N"))
	later(13.0, func(): spawn_pickup(rand(-8, 8), rand(-4, 4), -200, pick(["S", "M"])))

func _update_waves(dt: float) -> void:
	if bonus_t > 0:
		bonus_t -= dt
		M.env.fog_light_color = M.W.fog.lerp(Color(1.0, 0.69, 0.19), minf(1, minf(22 - bonus_t, bonus_t) * 0.6) * 0.75)
		if bonus_t <= 0:
			M.env.fog_light_color = M.W.fog
			toast("ZURÜCK AUF KURS", Color(0.5, 0.92, 1.0))
		return
	super._update_waves(dt)

func build_wave(n: int) -> Array:
	var q := super.build_wave(n)
	var dur := minf(40, 14 + n * 1.4)
	if rng.randf() < 0.45:
		q.append({"t": rand(3, dur - 4), "f": spawn_secret})
	if n % 4 == 2 and rng.randf() < 0.6:
		q.append({"t": rand(4, dur * 0.5), "f": spawn_rescue})
	q.sort_custom(func(a, b): return a.t < b.t)
	return q

# ---------- Auswertung + Warp ----------
func world_cleared() -> void:
	if state != "play":
		return
	var acc := int(round(float(st.hits) / maxf(1, st.shots) * 100))
	var m := 1
	if acc >= 35 and st.dmg < 160:
		m = 2
	if acc >= 50 and st.dmg < 80:
		m = 3
	var bonus: int = [0, 4, 10, 20][m] + 8
	give_crystals(bonus)
	var medals: Dictionary = M.get_save().get("medals", {})
	medals[M.W.name] = maxi(int(medals.get(M.W.name, 0)), m)
	M.put_save("medals", medals)
	var names := ["—", "BRONZE", "SILBER", "GOLD"]
	var cols := [Color(0.6, 0.6, 0.6), Color(0.82, 0.54, 0.29), Color(0.85, 0.9, 0.95), Color(1.0, 0.82, 0.29)]
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.05, 0.1, 0.85)
	sb.border_color = cols[m]
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	p.add_theme_stylebox_override("panel", sb)
	p.position = Vector2(390, 170)
	p.size = Vector2(500, 380)
	hud.add_child(p)
	var t := Label.new()
	t.text = "SEKTOR GESCHAFFT\n\n%s\n\nPUNKTE  %d\nABSCHÜSSE  %d\nTREFFERQUOTE  %d %%\nSCHADEN  %d\nKRISTALLE  +%d" % [names[m], score - st.score0, st.kills, acc, int(st.dmg), cr_got]
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", cols[m] if m > 0 else Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector2(0, 20)
	t.size = Vector2(500, 340)
	p.add_child(t)
	M.audio.sfx("pickup", 0.0, 0.0)
	later(3.2, func(): p.queue_free())
	later(3.4, func():
		warp_t = 0.0
		M.audio.sfx("whoosh", 0.0, 0.0))
	M.put_save("world", (M.widx + 1) % M.WORLDS.size())
	M.set_carry({"score": score, "wave": wave, "nmis": nmis, "nukes": nukes, "wpn": wpn, "wlv": wlv, "hull": M.hull})

func update(dt: float) -> void:
	super.update(dt)
	od = maxf(0, od - dt)
	_update_allies(dt)
	b_od.text = "⚡ %d%%" % int(sp_meter) if od <= 0 else "⚡ AN"
	b_od.modulate = Color(1, 1, 1, 1.0 if sp_meter >= 100 or od > 0 else 0.45)
	if od > 0:
		M.ship.scale = Vector3.ONE
	if warp_t >= 0:
		warp_t += dt
		M.speed = lerpf(M.speed, 330.0, minf(1, dt * 1.5))
		M.cam.fov = lerpf(M.cam.fov, 110.0, minf(1, dt * 2))
		white.color.a = clampf((warp_t - 1.2) / 0.8, 0, 1)
		if warp_t > 2.2:
			warp_t = -10.0
			M.goto_next_world()

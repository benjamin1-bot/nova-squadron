extends "res://game.gd"
## 19 Bosse – Port aus der HTML-Version (Rumpfformen, Waffenteile, Gruppen-Schutz, Panzertor, Spezialangriffe)

const BOSSES := [
	{"name": "SCHLACHTSCHIFF ARGUS", "tip": "WEICH DEN SALVEN AUS!", "shape": "slab", "hull": Color("6a5ab8"), "glow": Color("40e8ff"), "move": "hover", "core": "ring", "hp": 1.0, "abil": ["salvo", "arms"], "p2": ["beams"],
	 "parts": [["turret", -8, 0.6, 6.3, 0], ["turret", 8, 0.6, 6.3, 0], ["turret", -4.2, 3.4, 2.2, 0], ["turret", 4.2, 3.4, 2.2, 0], ["core", 0, -0.2, 6.6, 1]]},
	{"name": "SCHWARMMUTTER", "tip": "NUR WENN DIE LUKE OFFEN IST!", "shape": "carrier", "hull": Color("a89878"), "glow": Color("ffa030"), "move": "far", "core": "swarm", "hp": 0.9, "abil": ["hatch", "minefield"], "p2": ["barrage"],
	 "parts": [["hangar", -6.6, 0, 6, 0], ["hangar", 6.6, 0, 6, 0], ["mine", -4, 3.4, 8, 0], ["mine", 4, 3.4, 8, 0], ["core", 0, -0.6, 13.4, 1]]},
	{"name": "LANZENTRÄGER", "tip": "LASER: NICHT IN DER LINIE BLEIBEN!", "shape": "trident", "hull": Color("5a68c8"), "glow": Color("ff40c0"), "move": "strafe", "core": "beam", "hp": 1.05, "abil": ["flank", "beams"], "p2": ["xbeams"],
	 "parts": [["laser", -8, 0, 11.6, 0], ["laser", 8, 0, 11.6, 0], ["turret", 0, 2.4, 5, 0], ["core", 0, 0, 12.8, 1]]},
	{"name": "MINENLEGER", "tip": "MINENRING ABSCHIESSEN!", "shape": "disc", "hull": Color("7a8a72"), "glow": Color("ffe040"), "move": "hover", "core": "wall", "hp": 1.05, "abil": ["minefield", "orbitals"], "p2": ["salvo"],
	 "parts": [["mine", -6, 1.4, 6.5, 0], ["mine", 6, 1.4, 6.5, 0], ["turret", -3, 1.6, 7.5, 0], ["turret", 3, 1.6, 7.5, 0], ["core", 0, -0.4, 9.4, 1]]},
	{"name": "SPIRALWÄCHTER", "tip": "ACHTUNG – DREHT AUF!", "shape": "ring", "hull": Color("7a50c0"), "glow": Color("60ffd0"), "move": "circle", "core": "spiral", "hp": 1.1, "spin": 0.35, "abil": ["spinup", "orbitals"], "p2": ["xbeams"],
	 "parts": [["spiral", 0, 9, 1.6, 0], ["spiral", -7.8, -4.5, 1.6, 0], ["spiral", 7.8, -4.5, 1.6, 0], ["core", 0, 0, 3.4, 1]]},
	{"name": "RAMMBOCK", "tip": "RAMMANGRIFF – AUSWEICHEN!", "shape": "spike", "hull": Color("a87a66"), "glow": Color("ff6020"), "move": "hover", "core": "ring", "hp": 1.1, "abil": ["charge"], "p2": ["flyby", "boulder"],
	 "parts": [["turret", -2.9, 1.9, 2.5, 0], ["turret", 2.9, 1.9, 2.5, 0], ["spread", 0, -2.9, 5.5, 0], ["core", 0, 0, 11.8, 1]]},
	{"name": "HYDRA", "tip": "KÖPFE WACHSEN NACH!", "shape": "hydra", "hull": Color("78a888"), "glow": Color("60ff90"), "move": "drift", "core": "homing", "hp": 1.15, "abil": ["enrage", "revive"], "p2": ["barrage"],
	 "parts": [["turret", 0, 7.5, 4.8, 0], ["spread", -7, -3.6, 4.8, 0], ["homing", 7, -3.6, 4.8, 0], ["core", 0, 0, 4.9, 1]]},
	{"name": "PHANTOM", "tip": "FINDE DAS ECHTE SCHIFF!", "shape": "crescent", "hull": Color("4a60b0"), "glow": Color("60ffe0"), "move": "hover", "core": "bombs", "hp": 1.15, "abil": ["blink", "decoys"], "p2": ["beams"],
	 "parts": [["flak", -10, 0, 1.9, 0], ["flak", 10, 0, 1.9, 0], ["turret", 0, 10, 1.9, 0], ["core", 0, 4, 2, 1]]},
	{"name": "FESTUNG", "tip": "SCHILD-PAUSEN NUTZEN!", "shape": "sphere", "hull": Color("9a9aa6"), "glow": Color("40c8ff"), "move": "drift", "core": "wall", "hp": 1.2, "abil": ["reflect", "arms"], "p2": ["orbitals"],
	 "parts": [["gen", -5.2, 0, 5.4, 0], ["gen", 5.2, 0, 5.4, 0], ["turret", 0, 5, 5, 1], ["turret", -4.4, -3.2, 5.2, 1], ["turret", 4.4, -3.2, 5.2, 1], ["core", 0, 0, 7.4, 2]]},
	{"name": "ASTEROIDENBRECHER", "tip": "FELSBROCKEN ABSCHIESSEN!", "shape": "drill", "hull": Color("a89a78"), "glow": Color("ffb040"), "move": "hover", "core": "ring", "hp": 1.2, "abil": ["rockrain", "boulder"], "p2": ["charge"],
	 "parts": [["rock", -8, 0, 11.6, 0], ["rock", 8, 0, 11.6, 0], ["turret", 0, 2.4, 5, 0], ["core", 0, 0, 12.8, 1]]},
	{"name": "RAKETENKREUZER", "tip": "RAKETENSCHWÄRME!", "shape": "cruiser", "hull": Color("7f907f"), "glow": Color("ff8030"), "move": "strafe", "core": "homing", "hp": 1.25, "abil": ["barrage", "arms"], "p2": ["flank"],
	 "parts": [["homing", -8, 0.6, 6.3, 0], ["homing", 8, 0.6, 6.3, 0], ["homing", -4.2, 3.4, 2.2, 0], ["homing", 4.2, 3.4, 2.2, 0], ["core", 0, -0.2, 6.6, 1]]},
	{"name": "SENSE", "tip": "ANGRIFF VON DER SEITE!", "shape": "scythe", "hull": Color("a07090"), "glow": Color("ff40a0"), "move": "strafe", "spin": 0.3, "core": "spiral", "hp": 1.25, "abil": ["flank", "xbeams"], "p2": ["decoys"],
	 "parts": [["laser", -10, 0, 1.9, 0], ["laser", 10, 0, 1.9, 0], ["spiral", 0, 10, 1.9, 0], ["core", 0, 4, 2, 1]]},
	{"name": "GRAVITRON", "tip": "SCHUTZKUGELN ZUERST!", "shape": "gyro", "hull": Color("6f80a8"), "glow": Color("4080ff"), "move": "hover", "core": "ring", "hp": 1.3, "abil": ["tractor", "orbitals"], "p2": ["boulder"],
	 "parts": [["turret", 0, 9, 1.6, 0], ["turret", -7.8, -4.5, 1.6, 0], ["turret", 7.8, -4.5, 1.6, 0], ["core", 0, 0, 3.4, 1]]},
	{"name": "FLAKKREUZER", "tip": "NUR BEI OFFENER LUKE!", "shape": "tower", "hull": Color("968470"), "glow": Color("ff7040"), "move": "circle", "core": "bombs", "hp": 1.3, "abil": ["salvo", "hatch"], "p2": ["beams"],
	 "parts": [["flak", -6, 1.4, 6.5, 0], ["flak", 6, 1.4, 6.5, 0], ["spiral", 0, 1.6, 8, 0], ["core", 0, -0.4, 9.4, 1]]},
	{"name": "DREADNOUGHT OMEGA", "tip": "DER ENDGEGNER!", "shape": "dread", "hull": Color("5a3a9a"), "glow": Color("40ff80"), "move": "hover", "core": "beam", "hp": 1.5, "big": 1.25, "abil": ["charge", "tractor", "arms", "revive"], "p2": ["xbeams", "decoys", "barrage"],
	 "parts": [["gen", -5.2, 0, 5.4, 0], ["gen", 5.2, 0, 5.4, 0], ["laser", 0, 5, 5, 1], ["homing", -4.4, -3.2, 5.2, 1], ["hangar", 4.4, -3.2, 5.2, 1], ["core", 0, 0, 7.4, 2]]},
	{"name": "EISWURM JÖRMUN", "tip": "SEGMENTE TREFFEN!", "shape": "worm", "hull": Color("8ad0f0"), "glow": Color("40e0ff"), "move": "drift", "core": "spiral", "hp": 1.3, "world": "GEFRORENER OZEAN NIFL", "abil": ["charge", "rockrain"], "p2": ["flank", "barrage"],
	 "parts": [["turret", 0, 0, 0, 0, 2], ["turret", 0, 0, 0, 0, 4], ["spread", 0, 0, 0, 0, 6], ["homing", 0, 0, 0, 0, 8], ["core", 0, 0, 1.5, 1, 0]]},
	{"name": "LAVA-GOLEM SURTUR", "tip": "WEICH DEN FELSBROCKEN AUS!", "shape": "golem", "hull": Color("4a3028"), "glow": Color("ff6010"), "move": "hover", "core": "ring", "hp": 1.35, "world": "LAVAPLANET SURTR", "abil": ["boulder", "rockrain"], "p2": ["charge", "orbitals"],
	 "parts": [["rock", -11, 2, 3, 0], ["rock", 11, 2, 3, 0], ["flak", 0, 8, 3, 0], ["core", 0, 0, 5, 1]]},
	{"name": "KAMPFROBOTER VX-9", "tip": "ARME ZUERST!", "shape": "mech", "hull": Color("3a3a4a"), "glow": Color("ff30c0"), "move": "strafe", "core": "beam", "hp": 1.4, "world": "NEONSTADT VEGA-9", "abil": ["barrage", "arms"], "p2": ["xbeams", "salvo"],
	 "parts": [["turret", -9, 0, 3, 0], ["turret", 9, 0, 3, 0], ["homing", -5, 6, 1, 0], ["homing", 5, 6, 1, 0], ["core", 0, 1, 4.2, 1]]},
	{"name": "PILZMUTTER", "tip": "SPORENSÄCKE ZERSTÖREN!", "shape": "mother", "hull": Color("a04090"), "glow": Color("60ffd0"), "move": "drift", "core": "swarm", "hp": 1.35, "world": "PILZWALD MYKOS", "abil": ["orbitals", "hatch"], "p2": ["barrage", "decoys"],
	 "parts": [["spiral", -8, -3, 2, 0], ["spiral", 8, -3, 2, 0], ["spread", 0, -7, 2, 0], ["core", 0, 2, 5, 1]]},
]
const PART_HP := {"turret": 38, "spread": 42, "spiral": 46, "homing": 42, "laser": 46, "flak": 42, "mine": 38, "rock": 46, "hangar": 50, "gen": 55, "core": 170}

var bbeams: Array = []
var boss_bar: ProgressBar
var boss_lbl: Label
var markers: Array = []
var bb_hit_t := 0.0
var boss_bag: Array = []
var last_boss := -1

# ---------- Hilfsformen ----------
func torus(R: float, tube: float, arc: float, mat: Material, segs := 40, sides := 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = torus_mesh(R, tube, arc, segs, sides)
	mi.material_override = mat
	if M.outline_mat != null and mat is StandardMaterial3D and (mat as StandardMaterial3D).shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
		pass
	return mi

func _point_y_to(n: Node3D, a: Vector3, b: Vector3, sc: Vector3) -> void:
	var up := (b - a).normalized()
	var side := up.cross(Vector3(0.31, 0.5, 0.81)).normalized()
	n.basis = Basis(side, up, side.cross(up)).scaled(sc)
	n.position = (a + b) * 0.5

func _rock_mi(mat: Material, sc: Vector3, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
	mi.material_override = mat
	mi.scale = sc * 0.5
	mi.position = pos
	return mi

# ---------- Rumpf ----------
func boss_hull(def: Dictionary) -> Node3D:
	var g := Node3D.new()
	var hm := pbr(def.hull, 0.55, 0.45)
	var dm: Material = mats.bossDark
	var lm: Material = mats.bossLit
	var gm := bm(def.glow, 2.5)
	var spin: Array = []
	var add := func(o: Node3D) -> Node3D:
		g.add_child(o)
		return o
	var greeble := func(n: int, x0: float, x1: float, y: float, z0: float, z1: float) -> void:
		for i in n:
			g.add_child(mk("box", pick([dm, hm]), rand(0.6, 2), rand(0.3, 1), rand(0.6, 2), rand(x0, x1), y + rand(0, 0.4), rand(z0, z1)))
	var eglow := func(x: float, y: float, z: float, s: float) -> void:
		var e := glow(def.glow, s, 0.8)
		e.position = Vector3(x, y, z)
		g.add_child(e)
	match def.shape:
		"slab":
			add.call(mk("box", hm, 22, 3.6, 12))
			add.call(mk("box", lm, 10, 2.2, 7, 0, 2.9, -1.5))
			add.call(mk("box", dm, 3, 2.6, 2.6, 0, 5.2, -2.6))
			add.call(mk("cyl", dm, 2.2, 0.2, 2.2, 0, 6.6, -3, 0.4))
			greeble.call(30, -10, 10, 1.8, -5.5, 5.5)
			for s in [-1.0, 1.0]:
				add.call(mk("box", dm, 9, 1.1, 9, s * 14.5, -0.6, -1, 0, 0, s * 0.14))
				add.call(mk("box", gm, 0.25, 0.25, 8, s * 18.6, -1.1, -1))
				add.call(mk("cyl", hm, 2.2, 6, 2.2, s * 7, -2.4, -1, PI / 2))
				eglow.call(s * 7, -2.4, -5, 6)
			add.call(mk("box", gm, 19, 0.22, 0.2, 0, -1.3, 6.05))
		"carrier":
			add.call(mk("box", hm, 12, 5, 26))
			add.call(mk("box", lm, 8, 2, 10, 0, 3.4, -4))
			add.call(mk("box", dm, 3, 4, 4, 3, 5.5, -6))
			for s in [-1.0, 1.0]:
				add.call(mk("box", dm, 1.2, 1.2, 24, s * 6.6, -2, 0))
				add.call(mk("cyl", dm, 3, 2, 3, s * 3.5, 0, -13.5, PI / 2))
				eglow.call(s * 3.5, 0, -14.5, 7)
			add.call(mk("box", gm, 10, 0.2, 0.2, 0, 2.6, 12.9))
			greeble.call(22, -5.5, 5.5, 2.5, -12, 12)
		"trident":
			add.call(mk("box", hm, 4, 3, 14))
			add.call(mk("box", hm, 18, 1.6, 2.4, 0, 0, 4))
			add.call(mk("box", hm, 2.2, 2.2, 6, 0, 0, 9.5))
			add.call(mk("box", lm, 3, 1.6, 5, 0, 2.2, -2))
			for s in [-1.0, 1.0]:
				add.call(mk("box", hm, 2.4, 2.4, 9, s * 8, 0, 7))
				add.call(mk("box", gm, 0.2, 0.2, 8, s * 9.25, 0, 7))
				eglow.call(s * 1.5, 0, -7.5, 5)
			greeble.call(12, -1.8, 1.8, 1.5, -6, 6)
		"disc":
			add.call(mk("cyl", hm, 20, 2, 20))
			add.call(mk("sphere", lm, 5, 2.6, 5, 0, 1, 0))
			add.call(mk("ring", gm, 10.1, 10.1, 6, 0, 0, 0, PI / 2))
			greeble.call(20, -6, 6, 1, -6, 6)
			for i in 6:
				var a := i / 6.0 * TAU
				eglow.call(cos(a) * 9, -1.2, sin(a) * 9, 3)
		"ring":
			add.call(torus(9, 1.6, TAU, hm, 44, 12))
			add.call(mk("sphere", hm, 3, 3, 3))
			for i in 4:
				var th := i * PI / 2 + 0.785
				add.call(mk("box", dm, 0.8, 9, 0.8, -sin(th) * 4.5, cos(th) * 4.5, 0, 0, 0, th))
			var gr := torus(9, 0.25, TAU, gm, 44, 6)
			gr.position.z = 1.5
			add.call(gr)
			for i in 12:
				var a := i / 12.0 * TAU
				add.call(mk("box", dm, 1.2, 1.2, 1.8, cos(a) * 9, sin(a) * 9, -1.4))
		"crescent":
			add.call(torus(10, 1.8, PI, hm, 40, 10))
			var ga := torus(10, 0.3, PI, gm, 40, 6)
			ga.position.z = 1.6
			add.call(ga)
			for s in [-1.0, 1.0]:
				add.call(mk("cone", dm, 2.2, 4, 2.2, s * 10, -2.4, 0, 0, 0, PI))
				eglow.call(s * 10, 0, -2, 4)
		"sphere":
			add.call(mk("sphere", hm, 7, 7, 7))
			add.call(mk("ring", gm, 7.3, 7.3, 10, 0, 0, 0, PI / 2))
			add.call(mk("ring", dm, 7.7, 7.7, 30, 0, 0, 0, PI / 2))
			for i in 26:
				var v := Vector3(rand(-1, 1), rand(-1, 1), rand(-1, 0.6)).normalized()
				var bx := mk("box", pick([dm, lm, hm]), 1, 1, 1)
				var side := v.cross(Vector3(0.3, 0.9, 0.1)).normalized()
				bx.basis = Basis(side, side.cross(v), v).scaled(Vector3(rand(0.8, 2.2), rand(0.8, 2.2), rand(0.5, 1.4)))
				bx.position = v * 6.9
				add.call(bx)
			eglow.call(0, 0, -7, 8)
		"spike":
			add.call(mk("cone", hm, 7, 22, 7, 0, 0, 0, PI / 2))
			for s in [-1.0, 1.0]:
				add.call(mk("box", dm, 2.2, 1.4, 7, s * 2.9, 1.1, 1.5))
				add.call(mk("box", hm, 0.3, 5, 6, s * 2.4, 0, -8, 0, 0, s * 0.6))
				eglow.call(s * 1.8, 0, -11.5, 5)
			add.call(mk("box", dm, 2.2, 1.6, 6, 0, -2.6, 3.5))
			add.call(mk("box", gm, 0.25, 0.25, 16, 0, 1.9, 0))
		"hydra":
			add.call(mk("box", hm, 6, 6, 8))
			add.call(mk("box", lm, 4, 1.5, 6, 0, 3.4, -1))
			greeble.call(10, -2.5, 2.5, 3, -3.5, 3.5)
			for h in [Vector3(0, 7.5, 4), Vector3(-7, -3.6, 4), Vector3(7, -3.6, 4)]:
				var arm := mk("cyl", dm, 1, 1, 1)
				var a0 := Vector3(0, 0, 1.5)
				_point_y_to(arm, a0, h, Vector3(1.1, a0.distance_to(h), 1.1))
				add.call(arm)
				add.call(mk("sphere", hm, 1.9, 1.9, 1.9, h.x, h.y, h.z - 0.4))
			eglow.call(0, 0, -4.5, 6)
		"worm":
			var segs: Array = []
			var head := Node3D.new()
			head.add_child(mk("sphere", hm, 4.6, 4, 5.4))
			for s2 in [-1.0, 1.0]:
				head.add_child(mk("cone4", dm, 1.2, 5, 1.2, s2 * 3.2, -1.6, 3.6, 1.9, 0, s2 * 0.4))
			for k in 6:
				var a := k / 6.0 * TAU
				head.add_child(mk("cone4", dm, 0.9, 3.5, 0.9, cos(a) * 3.6, sin(a) * 3.2, -1, 0, 0, a - PI / 2))
			add.call(head)
			segs.append(head)
			for i in range(1, 10):
				var sg := Node3D.new()
				var r := 3.8 - i * 0.22
				sg.add_child(mk("sphere", hm if i % 2 else dm, r, r * 0.9, r))
				sg.add_child(torus(r * 0.95, 0.35, TAU, gm, 16, 6))
				for k in 4:
					var a := k / 4.0 * TAU + i
					sg.add_child(mk("cone4", dm, 0.6, 2.2, 0.6, cos(a) * r, sin(a) * r, 0, 0, 0, a - PI / 2))
				add.call(sg)
				segs.append(sg)
			g.set_meta("worm", segs)
		"golem":
			var rm := pbr(def.hull, 0.0, 0.9, Color(0.13, 0.02, 0), 1.0)
			add.call(_rock_mi(rm, Vector3(9, 8, 6)))
			add.call(_rock_mi(rm, Vector3(3.6, 3.2, 3.2), Vector3(0, 8, 1)))
			for i in 14:
				add.call(mk("box", gm, rand(0.2, 0.4), rand(2, 5), 0.3, rand(-6, 6), rand(-5, 5), 5.6, 0, 0, rand(-1, 1)))
			add.call(mk("sphere", gm, 0.7, 0.5, 0.4, -1.2, 8.6, 3.8))
			add.call(mk("sphere", gm, 0.7, 0.5, 0.4, 1.2, 8.6, 3.8))
			for s2 in [-1.0, 1.0]:
				var arm := Node3D.new()
				arm.position = Vector3(s2 * 9, 3, 0)
				arm.add_child(_rock_mi(rm, Vector3(2.6, 4, 2.6), Vector3(0, -3, 0)))
				arm.add_child(_rock_mi(rm, Vector3(3.2, 3.2, 3.2), Vector3(s2 * 2, -7, 1)))
				add.call(arm)
				spin.append([arm, "x", 0.0, s2])
			eglow.call(0, 0, 6, 12)
		"mech":
			add.call(mk("box", hm, 12, 10, 7, 0, 1, 0))
			add.call(mk("box", dm, 8, 4, 7.4, 0, -5, 0))
			add.call(mk("box", lm, 6, 3, 1, 0, 2, 3.8))
			add.call(mk("box", hm, 4.6, 3.4, 4, 0, 7.8, 1))
			add.call(mk("box", gm, 3.6, 0.7, 0.3, 0, 8.2, 3.1))
			for s2 in [-1.0, 1.0]:
				add.call(mk("box", dm, 4.4, 3.6, 5.4, s2 * 8, 4.4, 0))
				add.call(mk("box", gm, 0.3, 2.6, 0.3, s2 * 8, 6.6, 2.8))
				var arm := Node3D.new()
				arm.position = Vector3(s2 * 9, 2, 0)
				arm.add_child(mk("box", hm, 2.8, 8, 2.8, 0, -3, 0))
				arm.add_child(mk("cyl", dm, 1.4, 6, 1.4, 0, -6, 2, PI / 2))
				add.call(arm)
				spin.append([arm, "x", 0.0, s2])
				var leg := Node3D.new()
				leg.position = Vector3(s2 * 3.4, -7, 0)
				leg.add_child(mk("box", dm, 3, 7, 3.4, 0, -3.5, 0))
				leg.add_child(mk("box", hm, 3.6, 1.6, 5, 0, -7.4, 1))
				add.call(leg)
				spin.append([leg, "x", 0.0, -s2])
			eglow.call(0, -9, -2, 8)
		"mother":
			add.call(mk("sphere", hm, 15, 6, 15, 0, 4, 0))
			add.call(mk("sphere", pbr(Color(0.55, 0.2, 0.7), 0.2, 0.5, def.glow, 0.4), 13, 4, 13, 0, 2.4, 0))
			add.call(mk("cyl", dm, 4, 12, 4, 0, -4, 0))
			for i in 16:
				var a := i / 16.0 * TAU
				add.call(mk("sphere", gm, 0.7, 0.7, 0.7, cos(a) * 12.5, 2.6, sin(a) * 12.5))
			for i in 6:
				var a := i / 6.0 * TAU
				var t := Node3D.new()
				t.position = Vector3(cos(a) * 5, -8, sin(a) * 5)
				for k in 5:
					t.add_child(mk("sphere", hm if i % 2 else dm, 0.9 - k * 0.12, 1.2, 0.9 - k * 0.12, 0, -k * 2, 0))
				add.call(t)
				spin.append([t, "z", 0.0, float(i)])
			eglow.call(0, -2, 0, 14)
		"cruiser":
			add.call(mk("box", hm, 9, 3.2, 34, 0, 0, -4))
			add.call(mk("box", lm, 6, 2, 14, 0, 2.4, -8))
			add.call(mk("box", dm, 3, 5, 4, 0, 4.6, -12))
			add.call(mk("cone4", hm, 9, 10, 3.2, 0, 0, 17.5, PI / 2, PI / 4))
			for s in [-1.0, 1.0]:
				add.call(mk("box", dm, 4, 3, 22, s * 8, 0.4, -2))
				for k in 6:
					add.call(mk("cyl", gm, 0.7, 0.4, 0.7, s * 8, 2.1, -10 + k * 3.2))
				add.call(mk("cyl", dm, 3, 4, 3, s * 3, 0, -22, PI / 2))
				eglow.call(s * 3, 0, -24.5, 7)
			greeble.call(24, -4, 4, 1.6, -18, 10)
		"drill":
			add.call(mk("cyl", hm, 9, 22, 9, 0, 0, 0, PI / 2))
			add.call(mk("box", dm, 14, 3, 10, 0, -3, -2))
			for s in [-1.0, 1.0]:
				add.call(mk("box", dm, 6, 2, 4, s * 5, 0, 6))
				var d := Node3D.new()
				d.position = Vector3(s * 8, 0, 9)
				d.add_child(mk("cone", hm, 5, 12, 5, 0, 0, 6, PI / 2))
				for k in 5:
					d.add_child(mk("ring", gm, 2.4 - k * 0.4, 2.4 - k * 0.4, 6, 0, 0, 2 + k * 2.2))
				add.call(d)
				spin.append([d, "z", 5.0, 0.0])
			for i in 8:
				var a := i / 8.0 * TAU
				add.call(mk("box", lm, 1, 1, 18, cos(a) * 4.4, sin(a) * 4.4, -1))
			eglow.call(0, 0, -12, 9)
		"scythe":
			var bl := torus(11, 1.2, PI * 1.5, hm, 48, 8)
			bl.scale = Vector3(1, 1, 0.6)
			add.call(bl)
			add.call(torus(12.3, 0.35, PI * 1.5, gm, 48, 4))
			for i in 9:
				var a := i / 9.0 * PI * 1.5
				add.call(mk("cone4", dm, 1.4, 4.5, 1.4, cos(a) * 13.6, sin(a) * 13.6, 0, 0, 0, a - PI / 2))
			add.call(mk("sphere", hm, 4, 4, 4))
			add.call(mk("box", dm, 1, 11, 1.4, 0, -5.5, 0))
			eglow.call(0, 0, -3, 8)
		"tower":
			for k in 4:
				add.call(mk("cyl", dm if k % 2 else hm, 16 - k * 3.2, 2.6, 16 - k * 3.2, 0, -3 + k * 2.6, 4))
			add.call(mk("cyl", dm, 3, 10, 3, 0, 8, 4))
			add.call(mk("sphere", gm, 1.2, 1.2, 1.2, 0, 13.4, 4))
			for i in 8:
				var a := i / 8.0 * TAU
				add.call(mk("box", lm, 1.4, 4, 1.4, cos(a) * 8, -4.5, 4 + sin(a) * 8))
			for s in [-1.0, 1.0]:
				add.call(mk("box", dm, 5, 2, 5, s * 6, 1.4, 6.5))
			eglow.call(0, -6, 4, 10)
		"gyro":
			add.call(mk("sphere", hm, 3.4, 3.4, 3.4))
			add.call(mk("sphere", gm, 1.6, 1.6, 1.6, 0, 0, 2.6))
			var defs := [[11.0, "x", 0.9], [8.5, "y", -1.3], [6.0, "x", 1.8]]
			for i in 3:
				var r: float = defs[i][0]
				var rg := Node3D.new()
				rg.add_child(torus(r, 0.8, TAU, dm if i % 2 else hm, 40, 10))
				rg.add_child(torus(r, 0.22, TAU, gm, 40, 4))
				for k in 6:
					var a := k / 6.0 * TAU
					rg.add_child(mk("box", dm, 1.4, 1.4, 2, cos(a) * r, sin(a) * r, 0))
				add.call(rg)
				spin.append([rg, defs[i][1], defs[i][2], 0.0])
		"dread":
			add.call(mk("sphere", hm, 7.5, 7.5, 8))
			add.call(mk("cone", hm, 10, 16, 6, 0, 0, 15, PI / 2))
			for k in 6:
				add.call(mk("box", dm if k % 2 else hm, 5 - k * 0.5, 4 - k * 0.4, 3.6, 0, 0, -7 - k * 3.6))
			for s in [-1.0, 1.0]:
				add.call(mk("box", hm, 22, 1.4, 14, s * 16, 0, -2, 0, -s * 0.35, s * 0.12))
				add.call(mk("box", dm, 14, 1, 6, s * 20, -1.4, -8, 0, -s * 0.5))
				add.call(mk("box", gm, 0.3, 0.3, 12, s * 26, 0.8, -4))
				for k in 3:
					add.call(mk("cone4", dm, 1.6, 6, 1.6, s * (9 + k * 5), 3.5, -4 - k * 2))
			var ring := Node3D.new()
			ring.add_child(torus(9.5, 0.5, TAU, gm, 40, 8))
			for k in 10:
				var a := k / 10.0 * TAU
				ring.add_child(mk("box", dm, 1.4, 1.4, 1.4, cos(a) * 9.5, sin(a) * 9.5, 0))
			ring.position.z = -1
			add.call(ring)
			spin.append([ring, "z", 0.8, 0.0])
			eglow.call(0, 0, -28, 12)
	g.set_meta("spin", spin)
	return g

func boss_part(kind: String, gcol: Color) -> Node3D:
	var g := Node3D.new()
	var gm := bm(gcol, 2.5)
	var bh := pbr(Color(0.45, 0.45, 0.5), 0.8, 0.3)
	var bd: Material = mats.bossDark
	var glow_at := func(c: Color, sc: float, z: float) -> void:
		var s := glow(c, sc, 0.85)
		s.position.z = z
		g.add_child(s)
		g.set_meta("gl", s)
		g.set_meta("glS", sc)
	var base := func() -> void:
		g.add_child(mk("cyl", bd, 2, 1.4, 2, 0, 0, 0, PI / 2))
	match kind:
		"turret":
			base.call()
			g.add_child(mk("sphere", bh, 0.9, 0.9, 0.7, 0, 0, 0.4))
			for bx in [-0.3, 0.3]:
				g.add_child(mk("cyl", bh, 0.3, 2.6, 0.3, bx, 0, 1.4, PI / 2))
			glow_at.call(Color(1.0, 0.48, 0.16), 2.6, 0.9)
			g.set_meta("aim", true)
		"spread":
			base.call()
			g.add_child(mk("sphere", bh, 1, 1, 0.8, 0, 0, 0.4))
			for a in [-0.35, 0.0, 0.35]:
				var h := Node3D.new()
				h.rotation.y = a
				h.add_child(mk("cyl", bh, 0.28, 2.4, 0.28, 0, 0, 1.3, PI / 2))
				g.add_child(h)
			glow_at.call(Color(1.0, 0.35, 0.16), 2.8, 0.9)
			g.set_meta("aim", true)
		"spiral":
			var r := Node3D.new()
			r.add_child(mk("ring", gm, 1.7, 1.7, 5))
			for i in 4:
				var a := i * PI / 2
				r.add_child(mk("box", bd, 0.5, 0.5, 0.9, cos(a) * 1.7, sin(a) * 1.7, 0.3))
			r.position.z = 0.6
			g.add_child(r)
			g.set_meta("spinp", r)
			base.call()
			g.add_child(mk("sphere", gm, 0.6, 0.6, 0.6, 0, 0, 0.7))
			glow_at.call(gcol, 3.2, 0.8)
		"homing":
			g.add_child(mk("box", bd, 2.4, 1.9, 1.6))
			for v in [Vector2(-0.55, 0.45), Vector2(0.55, 0.45), Vector2(-0.55, -0.45), Vector2(0.55, -0.45)]:
				g.add_child(mk("cyl", bh, 0.62, 1.1, 0.62, v.x, v.y, 0.6, PI / 2))
			glow_at.call(Color(1.0, 0.25, 0.19), 2.6, 1.2)
			g.set_meta("aim", true)
		"laser":
			base.call()
			g.add_child(mk("octa", gm, 0.6, 0.6, 1.7, 0, 0, 1.3))
			glow_at.call(gcol, 3.6, 1.7)
			g.set_meta("aim", true)
		"flak":
			base.call()
			g.add_child(mk("cyl", bh, 0.85, 3.2, 0.85, 0, 0, 1.6, PI / 2))
			g.add_child(mk("ring", bm(Color(1.0, 0.75, 0.1)), 0.55, 0.55, 1, 0, 0, 3.2))
			glow_at.call(Color(1.0, 0.63, 0.25), 2.8, 1.4)
			g.set_meta("aim", true)
		"mine":
			g.add_child(mk("box", bd, 2.6, 1.7, 1.4))
			g.add_child(mk("box", bm(Color(1.0, 0.88, 0.25)), 1.6, 0.9, 0.2, 0, 0, 0.72))
			glow_at.call(Color(1.0, 0.88, 0.25), 2.6, 0.9)
		"rock":
			base.call()
			for s in [-1.0, 1.0]:
				g.add_child(mk("box", bh, 0.5, 0.5, 2.6, s * 0.7, 0, 1.3, 0, -s * 0.4))
			glow_at.call(Color(1.0, 0.7, 0.25), 2.6, 0.8)
			g.set_meta("aim", true)
		"hangar":
			g.add_child(mk("box", bd, 3, 2.6, 1.2))
			g.add_child(mk("box", gm, 2.4, 2, 0.2, 0, 0, 0.62))
			glow_at.call(gcol, 3.6, 0.8)
		"gen":
			g.add_child(mk("cyl", bd, 0.7, 2.2, 0.7, 0, 0, 0.4, PI / 2))
			var gb := bm(Color(0.38, 0.85, 1.0))
			g.add_child(mk("sphere", gb, 1, 1, 1, 0, 0, 1.5))
			var r1 := mk("ring", gb, 1.5, 1.5, 3, 0, 0, 1.5)
			g.add_child(r1)
			g.set_meta("spinp", r1)
			glow_at.call(Color(0.38, 0.85, 1.0), 4.2, 1.5)
		"core":
			g.add_child(mk("sphere", pbr(Color(1.0, 0.5, 0.15), 0.3, 0.3, Color(1.0, 0.45, 0.1), 2.2), 1.6, 1.6, 1.6))
			g.add_child(glow(Color(1.0, 0.48, 0.16), 4.5, 0.45))
			var cr := mk("ring", gm, 2.4, 2.4, 2.4)
			g.add_child(cr)
			g.set_meta("spinp", cr)
			g.add_child(mk("ring", bd, 2.9, 2.9, 8))
	var shm := StandardMaterial3D.new()
	shm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shm.albedo_color = Color(0.23, 0.56, 0.82, 0.2)
	var r0 := 2.9 if kind == "core" else 2.2
	var sh := mk("sphere", shm, r0, r0, r0)
	g.add_child(sh)
	g.set_meta("shield", sh)
	return g

# ---------- Boss erzeugen ----------
func spawn_boss() -> void:
	boss_count += 1
	var idx := -1
	for i in BOSSES.size():
		if BOSSES[i].has("world") and BOSSES[i].world == M.W.name and rng.randf() < 0.75:
			idx = i
	if idx < 0:
		if boss_bag.is_empty():
			for i in 15:
				boss_bag.append(i)
			boss_bag.shuffle()
		idx = boss_bag.pop_back()
	if M.has_meta("force_boss"):
		idx = int(M.get_meta("force_boss")) % BOSSES.size()
	var def: Dictionary = BOSSES[idx]
	var g := boss_hull(def)
	var sc: float = def.get("big", 1.0) * 1.3
	M.add_child(g)
	var behind := boss_count % 2 == 0
	var b := {"def": def, "idx": idx, "node": g, "p": Vector3(0, 26, 80) if behind else Vector3(0, 8, -400), "rot": Vector3.ZERO, "t": 0.0, "ft": 0.0,
		"state": "in", "behind": behind, "sc": sc, "parts": [], "mode": "normal", "mT": 0.0, "minG": 0, "chT": rand(6, 8), "trT": rand(8, 10),
		"blT": rand(5, 7), "flT": rand(6, 8), "spinBoost": 1.0}
	var hp_mul: float = def.hp * (1 + wave * 0.04)
	var core_e = null
	var core_def = null
	for pd in def.parts:
		var kind: String = pd[0]
		var pm := boss_part(kind, def.glow)
		pm.position = Vector3(pd[1], pd[2], pd[3])
		g.add_child(pm)
		var hp := roundf(PART_HP[kind] * hp_mul)
		var e := add_enemy_noparent("bpart", pm, {"boss": b, "kind": kind, "off": Vector3(pd[1], pd[2], pd[3]), "grp": pd[4], "hp": hp, "maxhp": hp,
			"radius": (2.7 if kind == "core" else (2.5 if kind == "gen" or kind == "hangar" else 2.2)) * sc, "score": 3000 if kind == "core" else 500,
			"collide": 0.0, "fire_t": rand(1.5, 3), "seg": pd[5] if pd.size() > 5 else -1, "armK": 1.0})
		b.parts.append(e)
		if kind == "core":
			core_e = e
			core_def = pd
	b.core = core_e
	if core_e != null and def.shape != "worm":
		# Panzertor vor dem Kern
		var dg := Node3D.new()
		var doors: Array = []
		for sx in [-1.0, 1.0]:
			var d := Node3D.new()
			d.add_child(mk("box", mats.bossDark, 2.7, 5.6, 0.8))
			d.add_child(mk("box", bm(def.glow), 0.3, 5.6, 0.9, -sx * 1.25, 0, 0))
			d.add_child(mk("box", mats.bossDark, 2.2, 0.5, 1.2, 0, 1.8, 0))
			d.add_child(mk("box", mats.bossDark, 2.2, 0.5, 1.2, 0, -1.8, 0))
			d.position.x = sx * 1.35
			dg.add_child(d)
			doors.append(d)
		dg.position = Vector3(core_def[1], core_def[2], core_def[3] + 2.0)
		g.add_child(dg)
		b.doors = {"L": doors[0], "R": doors[1], "k": 1.0, "t": rand(0, 1.5), "open": false}
	var tot := 0.0
	for e in b.parts:
		tot += e.maxhp
	b.maxhp = tot
	var warn := glow(Color(1.0, 0.12, 0.12), 24, 0.55)
	warn.visible = false
	g.add_child(warn)
	b.warn = warn
	boss = b
	M.audio.sfx("alarm", -6.0, 0.0)
	M.audio.play_music("boss")
	place(g, b.p.x, b.p.y, b.p.z, b.rot, sc)
	boss_bar.visible = true
	boss_lbl.visible = true
	boss_lbl.text = def.name
	if behind:
		toast("ÜBER DIR!", Color(1.0, 0.42, 0.42))

func add_enemy_noparent(type: String, n: Node3D, props: Dictionary) -> Dictionary:
	var e := {"type": type, "node": n, "x": 0.0, "y": 0.0, "z": -340.0, "vx": 0.0, "vy": 0.0, "vz": 0.0, "rot": Vector3.ZERO,
		"hp": 1.0, "maxhp": 1.0, "radius": 1.5, "t": 0.0, "fire_t": 1.0, "flash": 0.0, "alive": true, "score": 100,
		"collide": 0.0, "bs": 1.0, "env": false, "invul": false, "gone": false, "wp": Vector3.ZERO, "pwp": Vector3.ZERO, "wv": Vector3.ZERO, "state": ""}
	for k in props:
		e[k] = props[k]
	enemies.append(e)
	return e

func _make_hud() -> void:
	super._make_hud()
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(390, 96)
	boss_bar.size = Vector2(500, 14)
	boss_bar.show_percentage = false
	boss_bar.modulate = Color(1.0, 0.35, 0.3)
	boss_bar.visible = false
	hud.add_child(boss_bar)
	boss_lbl = _lab(20, Vector2(0, 110), 1280.0, Color(1.0, 0.7, 0.6))
	boss_lbl.visible = false
	for i in 8:
		var l := _lab(34, Vector2.ZERO, 60.0, Color(0.3, 1.0, 0.35))
		l.text = "◎"
		l.visible = false
		markers.append(l)

# ---------- Spezial-Gegnertypen der Bosse ----------
func update_special(e: Dictionary, dt: float, _px: float) -> void:
	match e.type:
		"bpart":
			_update_boss_part(e, dt)
		"orb":
			var b = e.ob
			if b == null or not is_same(boss, b) or b.state != "fight":
				e.gone = true
				return
			var a: float = e.oa + b.t * (1.1 if b.def.has("spin") else 0.7)
			var R: float = (9 + e["or"]) * b.sc
			e.x = b.p.x + cos(a) * R
			e.y = b.p.y + sin(a) * R * 0.8
			e.z = b.p.z + 6
			e.fire_t -= dt
			if e.fire_t <= 0:
				e.fire_t = rand(3.5, 6) / diff()
				enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.7)
			e.rot.y += dt * 2
		"bpod":
			e.rot.y += dt * 2

func spawn_minion(x: float, y: float, z: float) -> void:
	var e := spawn_fighter()
	e.x = x
	e.y = y
	e.z = z
	e.minion = true
	e.holdZ = rand(-30, -18)
	e.x0 = clampf(x + rand(-6, 6), -BX * 0.8, BX * 0.8)

func throw_rock(x: float, y: float, z: float, r := 0.0, spd := 34.0, hp := 0.0) -> void:
	if r <= 0:
		r = rand(1.8, 2.6)
	var mi := MeshInstance3D.new()
	mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
	mi.material_override = M.rock_mat
	var h := hp if hp > 0 else ceilf(r * 2.5)
	var e := add_enemy("thrown", mi, {"hp": h, "maxhp": h, "radius": r * 0.95, "score": 60, "collide": 30.0, "bs": r * 0.5, "minion": true})
	e.x = x
	e.y = y
	e.z = z
	var tgt := Vector3(M.ship_x + M.ship_vx * 0.6, M.ship_y + M.ship_vy * 0.6, 0)
	var v := (tgt - Vector3(x, y, z)).normalized() * spd
	e.vx = v.x
	e.vy = v.y
	e.vz = v.z
	e.spin = Vector3(rand(-2, 2), rand(-2, 2), rand(-2, 2))

func rock_fall() -> void:
	var r := rand(1.6, 2.4)
	var mi := MeshInstance3D.new()
	mi.mesh = M.rock_meshes[rng.randi() % M.rock_meshes.size()]
	mi.material_override = M.rock_mat
	var e := add_enemy("thrown", mi, {"hp": ceilf(r * 2), "maxhp": ceilf(r * 2), "radius": r * 0.95, "score": 40, "collide": 28.0, "bs": r * 0.5, "minion": true})
	e.x = clampf(M.ship_x + rand(-10, 10), -BX, BX)
	e.y = BY + 16
	e.z = rand(-50, -30)
	var tgt := Vector3(e.x + rand(-3, 3), -BY - 10, rand(-4, 6))
	var v := (tgt - Vector3(e.x, e.y, e.z)).normalized() * 26
	e.vx = v.x
	e.vy = v.y
	e.vz = v.z
	e.spin = Vector3(rand(-2, 2), rand(-2, 2), rand(-2, 2))

func flak_shot(p: Vector3, spd: float) -> void:
	var d := Vector3(M.ship_x, M.ship_y, 0) - p
	var dist := d.length()
	var b := spawn_ebullet(p.x, p.y, p.z, d.normalized() * spd, "flak")
	b.burst = dist / spd * 0.62

func bullet_wall(z0: float, spd: float) -> void:
	var gx := clampf(M.ship_x + rand(-3, 3), -BX + 3, BX - 3)
	var gy := clampf(M.ship_y + rand(-2, 2), -BY + 3, BY - 3)
	var x := -BX
	while x <= BX + 0.1:
		var y := -BY
		while y <= BY + 0.1:
			if Vector2(x - gx, y - gy).length() >= 4.3:
				var bb := spawn_ebullet(x, y, z0, Vector3(0, 0, spd))
				bb.dmg = 12.0
			y += 3.4
		x += 3.4
	if not seen.has("wall"):
		seen["wall"] = true
		toast("ENERGIEWAND – FLIEG DURCH DIE LÜCKE!", Color(1.0, 0.6, 0.55))

func ring_burst(x: float, y: float, z: float, n: int, spd: float, ph: float) -> void:
	for k in n:
		var a := ph + k * TAU / n
		spawn_ebullet(x, y, z, Vector3(cos(a) * 0.13, sin(a) * 0.13, 1).normalized() * spd)

func _part_dmg_mul(b: Dictionary) -> float:
	var dead := 0
	for x in b.parts:
		if not x.alive:
			dead += 1
	var D := diff()
	if b.def.abil.has("enrage"):
		D *= 1 + dead * 0.6
	D *= b.spinBoost
	return D

func _update_boss_part(e: Dictionary, dt: float) -> void:
	var b: Dictionary = e.boss
	var basis := Basis.from_euler(b.rot, EULER_ORDER_XYZ)
	var f: float = 0.42 + 0.58 * e.armK if e.kind != "core" else 1.0
	var pos: Vector3 = basis * (e.off * b.sc * f) + b.p
	e.x = pos.x
	e.y = pos.y
	e.z = pos.z
	var n: Node3D = e.node
	n.position = e.off * f
	var shield: Node3D = n.get_meta("shield")
	shield.visible = e.invul
	n.scale = Vector3.ONE * (1 + maxf(0, e.flash) * 0.2) * (0.35 + 0.65 * e.armK)
	if n.has_meta("gl"):
		var gl: Node3D = n.get_meta("gl")
		gl.scale = Vector3.ONE * float(n.get_meta("glS")) * (1 + 0.35 * sin(time * 9))
	if n.has_meta("spinp"):
		var sp: Node3D = n.get_meta("spinp")
		sp.rotation.z += dt * 3
	if n.has_meta("aim"):
		var sw := w_of(M.ship_x, M.ship_y, 0)
		if n.global_position.distance_to(sw) > 1.0:
			n.look_at(sw, Vector3.UP)
			n.rotate_object_local(Vector3.UP, PI)
	if b.state != "fight" or b.get("blinkHidden", false) or e.invul or b.mode == "charge":
		if e.has("beam"):
			e.beam.visible = false
		return
	var p := pos
	var bs := bullet_speed()
	var D := _part_dmg_mul(b)
	if b.def.abil.has("salvo") and e.kind != "spiral":
		D *= 0.6
	if e.kind == "laser" or (e.kind == "core" and b.def.core == "beam"):
		_update_laser(e, dt)
		if e.kind == "core" and rng.randf() < dt * 0.5:
			ring_burst(p.x, p.y, p.z, 10, bs * 0.75, e.t)
		return
	e.fire_t -= dt
	if e.fire_t > 0:
		return
	match e.kind:
		"turret":
			e.fire_t = rand(1.5, 2.3) / D
			enemy_shoot(p.x, p.y, p.z, bs + 6, 2 if wave >= 9 else 1, 0.05)
		"spread":
			e.fire_t = 2.6 / D
			enemy_shoot(p.x, p.y, p.z, bs * 0.9, 5, 0.11)
		"spiral":
			e.cyc = e.get("cyc", 0.0) + 0.13
			e.fire_t = 0.13
			if fmod(e.cyc, 6.0) < 3.2:
				e.ang = e.get("ang", 0.0) + 0.55
				for o in [0.0, PI]:
					var a: float = e.ang + o
					spawn_ebullet(p.x, p.y, p.z, Vector3(cos(a) * 0.15, sin(a) * 0.15, 1).normalized() * bs * 0.7)
		"homing":
			e.fire_t = 3.8 / D
			spawn_homing(p.x, p.y, p.z, -1)
			spawn_homing(p.x, p.y, p.z, 1)
		"flak":
			e.fire_t = 3.0 / D
			flak_shot(p, bs * 0.85)
		"mine":
			e.fire_t = 2.4 / D
			var mn := spawn_mine(p.x, p.y, p.z)
			mn.vx = rand(-6, 6)
			mn.vy = rand(-4, 4)
			mn.vz = 18 + wave * 0.3
		"rock":
			e.fire_t = 3.2 / D
			throw_rock(p.x, p.y, p.z)
		"hangar":
			e.fire_t = 5.5 / D
			var cnt := 0
			for x in enemies:
				if x.has("minion") and x.alive and x.type == "fighter":
					cnt += 1
			if cnt < 6:
				spawn_minion(p.x, p.y, p.z)
				later(0.4, func(): if e.alive: spawn_minion(e.x, e.y, e.z))
		"gen":
			e.fire_t = 99.0
		"core":
			_core_attack(e)

func _core_attack(e: Dictionary) -> void:
	var b: Dictionary = e.boss
	var p := Vector3(e.x, e.y, e.z)
	var bs := bullet_speed()
	match b.def.core:
		"swarm":
			e.fire_t = 6 / diff()
			for i in 3:
				later(i * 0.35, func(): if e.alive: spawn_minion(e.x, e.y, e.z))
			ring_burst(p.x, p.y, p.z, 10, bs * 0.7, 0)
		"homing":
			e.fire_t = 4 / diff()
			for sd in [-1.0, 1.0, -1.0, 1.0]:
				spawn_homing(p.x, p.y, p.z, sd)
			enemy_shoot(p.x, p.y, p.z, bs)
		"bombs":
			e.fire_t = 3.4 / diff()
			for a in [-0.25, 0.0, 0.25]:
				var d := (Vector3(M.ship_x, M.ship_y, 0) - p)
				var dist := d.length()
				var bb := spawn_ebullet(p.x, p.y, p.z, d.normalized().rotated(Vector3.UP, a) * bs * 0.8, "flak")
				bb.burst = dist / (bs * 0.8) * 0.6
		"spiral":
			e.cyc = e.get("cyc", 0.0) + 0.16
			if fmod(e.cyc, 5.5) < 3.2:
				e.ang = e.get("ang", 0.0) + 0.45
				for k in 2:
					var a: float = e.ang + k * PI
					spawn_ebullet(p.x, p.y, p.z, Vector3(cos(a) * 0.15, sin(a) * 0.15, 1).normalized() * bs * 0.65)
			e.fire_t = 0.16
			if rng.randf() < 0.06:
				enemy_shoot(p.x, p.y, p.z, bs)
		"wall":
			e.fire_t = 4.4 / diff()
			bullet_wall(p.z, bs * 0.7)
			later(1.5, func(): if e.alive: ring_burst(e.x, e.y, e.z, 12, bs * 0.8, 0))
		_:
			e.fire_t = 2.4 / diff()
			ring_burst(p.x, p.y, p.z, 14, bs * 0.8, e.t)
			later(0.6, func(): if e.alive: enemy_shoot(e.x, e.y, e.z, bs * 1.1, 3, 0.05))

func _update_laser(e: Dictionary, dt: float) -> void:
	if not e.has("beam"):
		var bmm := MeshInstance3D.new()
		bmm.mesh = shapes.cyl
		bmm.material_override = glow_line_mat(e.boss.def.glow)
		bmm.visible = false
		M.add_child(bmm)
		e.beam = bmm
		e.line = bmm
		e.ls = "idle"
		e.lt = rand(1, 2.5)
		e.T = Vector3.ZERO
		e.swp = 0.0
	e.lt -= dt
	if e.ls == "idle":
		e.beam.visible = false
		if e.lt <= 0:
			e.ls = "tele"
			e.lt = 1.25
			e.T = Vector3(M.ship_x + rand(-2, 2), M.ship_y + rand(-1.5, 1.5), 18)
			e.swp = (-1.0 if rng.randf() < 0.5 else 1.0) * rand(5, 8)
		return
	if e.ls == "tele":
		if e.lt <= 0:
			e.ls = "fire"
			e.lt = 1.5
	else:
		e.T = Vector3(e.T.x + e.swp * dt, e.T.y, e.T.z)
		if e.lt <= 0:
			e.ls = "idle"
			e.lt = rand(2.4, 3.6) / diff() * 1.2
			e.beam.visible = false
			return
	var fire: bool = e.ls == "fire"
	var p := Vector3(e.x, e.y, e.z)
	beam_between(e.beam, p, e.T, (0.7 + rng.randf() * 0.15) if fire else 0.09)
	e.beam.visible = fire or sin(time * 30) > -0.3
	if fire and state == "play" and seg_dist(p, e.T, Vector3(M.ship_x, M.ship_y, 0)) < 1.8:
		damage_player(26)

# ---------- Treffer auf Bossteile ----------
func hit_enemy(e: Dictionary, dmg: float, at: Vector3) -> void:
	if e.has("boss"):
		var b: Dictionary = e.boss
		if e.kind == "core" and b.get("doorsClosed", false):
			dmg *= 0.2
	super.hit_enemy(e, dmg, at)

func kill_enemy(e: Dictionary, by_ram: bool) -> void:
	if e.has("boss") and e.alive:
		var n: Node3D = e.node
		e.alive = false
		boom(n.global_position, 1.6)
		add_score(int(e.score))
		n.visible = false
		if e.has("beam"):
			e.beam.visible = false
		var b: Dictionary = e.boss
		if e.kind == "core":
			boss_defeated(b)
		return
	super.kill_enemy(e, by_ram)

func boss_defeated(b: Dictionary) -> void:
	b.state = "dying"
	for i in 10:
		later(i * 0.17, func():
			var q: Vector3 = Basis.from_euler(b.rot, EULER_ORDER_XYZ) * (Vector3(rand(-14, 14), rand(-2, 4), rand(-5, 6)) * b.sc) + b.p
			boom(w_of(q.x, q.y, q.z), rand(1.4, 2.4)))
	var bonus := int(round(5000 * (1 + b.idx * 0.15)))
	later(1.9, func():
		boom(w_of(b.p.x, b.p.y, b.p.z), 4.5)
		boom(w_of(b.p.x - 8, b.p.y, b.p.z), 3)
		boom(w_of(b.p.x + 8, b.p.y, b.p.z), 3)
		trauma = 1.0
		_remove_boss(b)
		for e in enemies:
			if e.has("minion") and e.alive:
				kill_enemy(e, false)
		add_score(bonus)
		M.audio.play_music("play")
		banner(b.def.name, "ZERSTÖRT  +%d" % bonus)
		later(3.0, world_cleared))

func _remove_boss(b: Dictionary) -> void:
	for e in b.parts:
		e.alive = false
		if e.has("beam") and is_instance_valid(e.beam):
			e.beam.queue_free()
	if b.has("clones"):
		for c in b.clones:
			c.queue_free()
	if b.has("tbeam"):
		b.tbeam.queue_free()
	b.node.queue_free()
	boss = null
	boss_bar.visible = false
	boss_lbl.visible = false
	for m in markers:
		m.visible = false

func world_cleared() -> void:
	if state != "play":
		return
	banner("WELT GESCHAFFT!", "SPRUNG ZUR NÄCHSTEN WELT …", true)
	M.put_save("world", (M.widx + 1) % M.WORLDS.size())
	M.set_carry({"score": score, "wave": wave, "nmis": nmis, "nukes": nukes, "wpn": wpn, "wlv": wlv, "hull": M.hull})
	later(2.5, func(): M.goto_next_world())

# ---------- Boss-Steuerung ----------
func _move_boss(b: Dictionary, dt: float, enr: bool) -> void:
	var p: Vector3 = b.p
	var ft: float = b.ft
	var tx := 0.0
	var ty := 0.0
	var tz := 0.0
	match b.def.move:
		"strafe":
			tx = sin(ft * 0.9) * BX * 0.9
			ty = 3 + sin(ft * 0.6) * 3
			tz = -60
		"circle":
			tx = cos(ft * 0.6) * BX * 0.7
			ty = 2 + sin(ft * 0.6) * BY * 0.5
			tz = -62
		"far":
			tx = sin(ft * 0.25) * BX * 0.6
			ty = 4 + sin(ft * 0.33) * 3
			tz = -74 + sin(ft * 0.2) * 5
		"drift":
			tx = sin(ft * 0.22) * BX * 0.5
			ty = 2 + sin(ft * 0.31) * 2.5
			tz = -66 + sin(ft * 0.17) * 5
		_:
			tx = sin(ft * 0.35) * BX * 0.75
			ty = 3 + sin(ft * 0.5) * 3.5
			tz = -62 + sin(ft * 0.21) * 5
	if enr:
		tz += 3
	b.swT = b.get("swT", rand(3, 5)) - dt
	if b.swT <= 0:
		b.swT = rand(4.5, 7)
		b.swX = (-1.0 if b.get("swX", 0.0) > 0 else 1.0) * rand(BX * 0.45, BX * 0.8)
	tx = tx * 0.35 + b.get("swX", 0.0)
	var k := minf(1, dt * 1.6)
	p.x += (tx - p.x) * k
	p.y += (ty - p.y) * k
	p.z += (tz - p.z) * minf(1, dt * 1.5)
	b.p = p

func _specials(b: Dictionary, dt: float, ab: Array) -> void:
	var p: Vector3 = b.p
	if ab.has("hatch"):
		b.hT = b.get("hT", 5.0) - dt
		if b.hT <= 0:
			b.hOpen = not b.get("hOpen", false)
			b.hT = 4.5 if b.hOpen else 5.5
			if b.hOpen:
				toast("LUKE OFFEN – JETZT FEUERN!", Color(0.5, 1.0, 0.6))
				for i in 3:
					later(i * 0.4, func(): if is_same(boss, b): spawn_minion(b.p.x, b.p.y, b.p.z))
			else:
				toast("LUKE ZU", Color(1.0, 0.6, 0.55))
		b.hatchShut = not b.get("hOpen", false)
		for e in b.parts:
			if e.alive:
				e.armK += ((1.0 if b.get("hOpen", false) else 0.45) - e.armK) * minf(1, dt * 3)
				if not b.get("hOpen", false):
					e.invul = true
	if ab.has("orbitals"):
		var n := 0
		for e in enemies:
			if e.alive and e.type == "orb":
				n += 1
		if n == 0:
			b.obT = b.get("obT", 0.0) - dt
			if b.obT <= 0:
				b.obT = 11.0
				var cnt := 10 if b.def.has("big") else 8
				for i in cnt:
					var g := Node3D.new()
					g.add_child(mk("sphere", pbr(Color(1.0, 0.12, 0.19), 0.3, 0.3, Color(1.0, 0.06, 0.12), 1.4), 1.3, 1.3, 1.3))
					g.add_child(mk("ring", mats.white, 1.5, 1.5, 2))
					g.add_child(glow(Color(1.0, 0.19, 0.25), 5, 0.8))
					var o := add_enemy("orb", g, {"hp": 6.0, "maxhp": 6.0, "radius": 1.9, "score": 120, "collide": 22.0, "minion": true})
					o.ob = b
					o.oa = float(i) / cnt * TAU
					o["or"] = (i % 2) * 2.5
					o.fire_t = rand(2, 5)
					o.x = p.x
					o.y = p.y
					o.z = p.z
				toast("SCHUTZKUGELN!", Color(1.0, 0.42, 0.42))
	if ab.has("reflect"):
		b.rfT = b.get("rfT", 4.0) - dt
		if b.rfT <= 0:
			b.rfOn = not b.get("rfOn", false)
			b.rfT = 3.5 if b.rfOn else 5.5
			if b.rfOn:
				toast("SCHILD AKTIV – WARTEN!", Color(0.5, 0.7, 1.0))
		if not b.has("shield"):
			var shm := StandardMaterial3D.new()
			shm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			shm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			shm.albedo_color = Color(0.38, 0.72, 1.0, 0.18)
			var sh := mk("sphere", shm, 13, 13, 13)
			b.node.add_child(sh)
			b.shield = sh
		b.shield.visible = b.get("rfOn", false)
		if b.get("rfOn", false):
			for e in b.parts:
				e.invul = true
	if ab.has("boulder"):
		b.boT = b.get("boT", 4.0) - dt
		if b.boT <= 0:
			b.boT = rand(6, 8)
			throw_rock(p.x, p.y, p.z, rand(3.2, 4.2), 28.0, 14.0)
			toast("FELSBROCKEN!", Color(1.0, 0.7, 0.38))
	if ab.has("barrage"):
		b.baT = b.get("baT", 6.0) - dt
		if b.baT <= 0:
			b.baT = rand(8, 10)
			b.warn.visible = true
			toast("RAKETENSCHWARM!", Color(1.0, 0.54, 0.25))
			for i in 8:
				later(0.9 + i * 0.12, func(): if is_same(boss, b) and b.state == "fight": spawn_homing(b.p.x, b.p.y, b.p.z, 1.0 if i % 2 else -1.0))
	if ab.has("beams") or ab.has("xbeams"):
		b.lbT = b.get("lbT", rand(5, 7)) - dt
		if b.lbT <= 0 and bbeams.is_empty():
			b.lbT = rand(8, 11)
			if ab.has("xbeams"):
				var a := rand(0, PI)
				spawn_boss_beam("rot", a)
				spawn_boss_beam("rot", a + PI / 2)
			else:
				spawn_boss_beam("", 0.0)
	if ab.has("decoys"):
		b.dcT = b.get("dcT", 7.0) - dt
		if not b.get("decoy", false) and b.dcT <= 0:
			b.decoy = true
			b.dcT = 7.0
			var cl: Array = []
			for i in 2:
				var c: Node3D = b.node.duplicate()
				M.add_child(c)
				cl.append(c)
			b.clones = cl
			var sl := [-1, 0, 1]
			sl.shuffle()
			b.slots = sl
			toast("TRUGBILDER – FINDE DAS ECHTE!", Color(0.75, 0.54, 1.0))
		if b.get("decoy", false):
			for i in 2:
				var c: Node3D = b.clones[i]
				place(c, b.slots[i + 1] * BX * 0.62, p.y + sin(b.t * 2 + i) * 1.5, p.z, b.rot, b.sc)
			p.x += (b.slots[0] * BX * 0.62 - p.x) * minf(1, dt * 3)
			b.p = p
			if b.dcT <= 0:
				b.decoy = false
				b.dcT = rand(9, 12)
				for c in b.clones:
					sparks(c.global_position, b.def.glow, 20)
					c.queue_free()
				b.erase("clones")
	if ab.has("flyby") and b.mode == "normal":
		b.fyT = b.get("fyT", 6.0) - dt
		if b.fyT <= 0:
			b.fyT = rand(9, 12)
			b.mode = "flyby"
			b.mT = 3.2
			b.fyX = M.ship_x + rand(-3, 3)
			b.fyY = M.ship_y
			b.p = Vector3(b.fyX, b.fyY + 10, 60)
			toast("VON HINTEN – AUSWEICHEN!", Color(1.0, 0.42, 0.42))
	if ab.has("revive") and not b.get("revived", false) and b.core != null and b.minG >= b.core.grp and b.core.hp < b.core.maxhp * 0.6:
		b.revived = true
		for e in b.parts:
			if e.kind == "core" or e.alive:
				continue
			e.alive = true
			e.hp = roundf(e.maxhp * 0.55)
			e.node.visible = true
			e.flash = 1.0
			if not enemies.has(e):
				enemies.append(e)
		b.minG = 0
		toast("ER REGENERIERT SICH!", Color(1.0, 0.48, 0.42))

func _update_arms(b: Dictionary, dt: float) -> void:
	var ps: Array = []
	for e in b.parts:
		if e.alive and e.kind != "core":
			ps.append(e)
	if ps.is_empty():
		return
	b.arT = b.get("arT", 6.0) - dt
	var na := 0
	var nb := 0
	for e in ps:
		if b.parts.find(e) % 2 == 0:
			na += 1
		else:
			nb += 1
	if b.arT <= 0:
		b.arT = rand(6, 8)
		b.arm = b.get("arm", 0) ^ 1
		if na > 0 and nb > 0:
			toast("WAFFEN WECHSELN", Color(1.0, 0.7, 0.38))
	var both := na == 0 or nb == 0
	for e in ps:
		var out: bool = both or (b.parts.find(e) % 2) == b.get("arm", 0)
		e.armK += ((1.0 if out else 0.0) - e.armK) * minf(1, dt * 2.5)
		if e.armK < 0.8:
			e.invul = true

func spawn_boss_beam(md: String, a0: float) -> void:
	var bb := {"t": 0.0, "warn": 1.6, "dur": 3.2, "mode": md if md != "" else pick(["slideV", "slideH", "rot"]), "a0": 0.0, "d0": 0.0, "sp": pick([-1.0, 1.0]) * rand(0.8, 1.2)}
	if bb.mode == "slideV":
		bb.d0 = (-1.0 if rng.randf() < 0.5 else 1.0) * BY * 0.9
	elif bb.mode == "slideH":
		bb.a0 = PI / 2
		bb.d0 = (-1.0 if rng.randf() < 0.5 else 1.0) * BX * 0.85
	else:
		bb.a0 = a0 if md == "rot" else rand(0, PI)
	var o := MeshInstance3D.new()
	o.mesh = shapes.cyl
	o.material_override = glow_line_mat(Color(1.0, 0.16, 0.82))
	var i := MeshInstance3D.new()
	i.mesh = shapes.cyl
	var im := glow_line_mat(Color(1.0, 0.88, 1.0))
	im.albedo_color.a = 1.0
	i.material_override = im
	M.add_child(o)
	M.add_child(i)
	bb.o = o
	bb.i = i
	var pods: Array = []
	for k in 2:
		var g := Node3D.new()
		g.add_child(mk("sphere", pbr(Color(0.85, 0.87, 0.92), 0.7, 0.3), 1.6, 1.6, 2))
		g.add_child(mk("cyl", mats.eDark, 1.8, 0.8, 1.8))
		g.add_child(glow(Color(1.0, 0.25, 0.88), 5, 0.9))
		var e := add_enemy("bpod", g, {"hp": 3.0, "maxhp": 3.0, "radius": 2.2, "score": 150, "collide": 0.0, "haz": true})
		e.x = boss.p.x if boss != null else 0.0
		e.y = boss.p.y if boss != null else 0.0
		e.z = boss.p.z if boss != null else -60.0
		pods.append(e)
	bb.e1 = pods[0]
	bb.e2 = pods[1]
	bbeams.append(bb)
	toast("LASERSTRAHL – AUSWEICHEN!", Color(1.0, 0.38, 0.88))

func _update_boss_beams(dt: float) -> void:
	for i in range(bbeams.size() - 1, -1, -1):
		var bb: Dictionary = bbeams[i]
		bb.t += dt
		var act: bool = bb.t > bb.warn
		var k: float = (bb.t - bb.warn) / bb.dur if act else 0.0
		var a: float = bb.a0
		var d: float = bb.d0
		if bb.mode == "rot":
			a = bb.a0 + bb.sp * k * 2.2
		else:
			d = bb.d0 * (1 - 2 * k)
		var ux := cos(a)
		var uy := sin(a)
		var nx := -uy
		var ny := ux
		var L := Vector2(BX, BY).length() + 10
		var z := -6.0
		var ha := Vector3(nx * d - ux * L, ny * d - uy * L, z)
		var hb := Vector3(nx * d + ux * L, ny * d + uy * L, z)
		var f := minf(1, bb.t / (bb.warn * 0.8))
		var bp: Vector3 = boss.p if boss != null else ha
		var p1 := bp.lerp(ha, f)
		var p2 := bp.lerp(hb, f)
		for pr in [[bb.e1, p1], [bb.e2, p2]]:
			var e: Dictionary = pr[0]
			e.x = pr[1].x
			e.y = pr[1].y
			e.z = pr[1].z
		if (not bb.e1.alive or not bb.e2.alive) and not bb.has("cut"):
			bb.cut = true
			bb.dur = 0.0
			bb.t = bb.warn + 0.01
			toast("LASERKAPSEL ZERSTÖRT!", Color(0.5, 1.0, 0.6))
		if act:
			bb.o.visible = true
			bb.i.visible = true
			beam_between(bb.o, p1, p2, 0.8 + 0.15 * sin(time * 30))
			beam_between(bb.i, p1, p2, 0.25)
			if state == "play" and absf(M.ship_x * nx + M.ship_y * ny - d) < 1.5 and bb_hit_t <= 0:
				bb_hit_t = 0.6
				damage_player(24)
		else:
			bb.i.visible = sin(bb.t * 30) > 0
			bb.o.visible = false
			beam_between(bb.i, p1, p2, 0.06)
		if bb.t > bb.warn + bb.dur or boss == null or boss.state != "fight":
			bb.o.queue_free()
			bb.i.queue_free()
			for e in [bb.e1, bb.e2]:
				if e.alive:
					e.alive = false
			bbeams.remove_at(i)
	bb_hit_t = maxf(0, bb_hit_t - dt)

func update_boss(dt: float) -> void:
	_update_boss_beams(dt)
	var b = boss
	if b == null:
		return
	b.t += dt
	var def: Dictionary = b.def
	var ab: Array = def.abil.duplicate()
	var min_g := 99
	for e in b.parts:
		if e.alive:
			min_g = mini(min_g, int(e.grp))
	for e in b.parts:
		e.invul = e.grp > min_g
	if min_g != b.minG and min_g < 99:
		b.minG = min_g
		var only_core := true
		for e in b.parts:
			if e.alive and e.kind != "core":
				only_core = false
		if only_core:
			banner("KERN FREIGELEGT", "FEUER AUF DEN REAKTOR", true)
		else:
			toast("SCHILD AUSGEFALLEN – NEUE ZIELE", Color(0.5, 0.92, 1.0))
	b.warn.visible = false
	if b.has("tbeam"):
		b.tbeam.visible = false
	var p: Vector3 = b.p
	if b.state == "in":
		if b.behind:
			p.z -= 48 * dt
			if p.z < 15:
				p.y += (4 - p.y) * minf(1, dt * 1.1)
			if p.z <= -60:
				p.z = -60
				b.state = "fight"
				banner(def.name, "BOSS · " + def.tip, true)
		else:
			p.z += maxf(24, (-60 - p.z) * 1.15) * dt
			p.y += (4 - p.y) * minf(1, dt)
			if p.z >= -60:
				p.z = -60
				b.state = "fight"
				banner(def.name, "BOSS · " + def.tip, true)
		b.p = p
	elif b.state == "fight":
		var enr: bool = b.core != null and not b.core.invul and not b.get("hatchShut", false)
		if b.core != null and b.minG >= b.core.grp and def.has("p2"):
			ab.append_array(def.p2)
			if not b.has("p2told"):
				b.p2told = true
				toast("BOSS WIRD WÜTEND – NEUE ANGRIFFE!", Color(1.0, 0.48, 0.42))
		_specials(b, dt, ab)
		p = b.p
		b.ft += dt * (1.5 if enr else 1.0)
		b.mT -= dt
		if ab.has("arms"):
			_update_arms(b, dt)
		match b.mode:
			"normal":
				_move_boss(b, dt, enr)
				p = b.p
				if ab.has("charge"):
					b.chT -= dt
					if b.chT <= 0:
						b.mode = "chargeTele"
						b.mT = 1.4
						b.chX = M.ship_x
						b.chY = M.ship_y
						b.hitDone = false
						toast("ACHTUNG – BOSS-SALVE!", Color(1.0, 0.42, 0.42))
				if b.mode == "normal" and ab.has("tractor"):
					b.trT -= dt
					if b.trT <= 0:
						b.mode = "tractor"
						b.mT = 3.2
						toast("TRAKTORSTRAHL – GEGENSTEUERN!", Color(0.5, 0.7, 1.0))
				if b.mode == "normal" and ab.has("blink"):
					b.blT -= dt
					if b.blT <= 0:
						b.mode = "blinkOut"
						b.mT = 0.4
				if b.mode == "normal" and ab.has("salvo"):
					b.saT = b.get("saT", 4.0) - dt
					if b.saT <= 0:
						b.mode = "salvoTele"
						b.mT = 0.9
				if ab.has("minefield"):
					b.mfT = b.get("mfT", 5.0) - dt
					if b.mfT <= 0:
						b.mfT = rand(6.5, 8.5)
						var gap := rand(-BX * 0.6, BX * 0.6)
						var y := rand(-BY * 0.5, BY * 0.5)
						for i in 7:
							var x := -BX + i * (2 * BX / 6)
							if absf(x - gap) < 4.5:
								continue
							var mn := spawn_mine(x, y, p.z + 4)
							mn.vx = 0.0
							mn.vy = 0.0
							mn.vz = 20.0
						toast("MINENGÜRTEL – LÜCKE SUCHEN!", Color(1.0, 0.88, 0.38))
				if ab.has("spinup"):
					b.suT = b.get("suT", 6.0) - dt
					if b.suT <= 0:
						b.suT = rand(8, 10)
						b.spinBoost = 3.2
						toast("DREHT AUF!", Color(1.0, 0.6, 0.55))
				if ab.has("rockrain"):
					b.rrT = b.get("rrT", 4.0) - dt
					if b.rrT <= 0:
						b.rrT = rand(5.5, 7)
						for i in 5:
							later(i * 0.25, func(): if is_same(boss, b): rock_fall())
						toast("FELSREGEN!", Color(1.0, 0.7, 0.38))
				if b.mode == "normal" and ab.has("flank"):
					b.flT -= dt
					if b.flT <= 0:
						b.mode = "flank"
						b.mT = 6.0
						b.side = -1.0 if rng.randf() < 0.5 else 1.0
						toast("BOSS RECHTS VON DIR!" if b.side > 0 else "BOSS LINKS VON DIR!", Color(1.0, 0.6, 0.55))
			"flyby":
				p.z -= 95 * dt
				p.x += (b.fyX - p.x) * minf(1, dt * 2)
				p.y += (b.fyY - p.y) * minf(1, dt * 2)
				if not b.get("fyHit", false) and state == "play" and absf(p.z) < 6 and Vector2(p.x - M.ship_x, p.y - M.ship_y).length() < 6:
					b.fyHit = true
					damage_player(30)
				if p.z < -60:
					p.z = -60
					b.mode = "normal"
					b.fyHit = false
			"salvoTele":
				_move_boss(b, dt * 0.3, enr)
				p = b.p
				b.warn.visible = sin(b.t * 28) > 0
				if b.mT <= 0:
					b.mode = "normal"
					b.saT = rand(5, 6.5)
					for e in b.parts:
						if e.alive and not e.invul and (e.kind == "turret" or e.kind == "spread" or e.kind == "flak"):
							enemy_shoot(e.x, e.y, e.z, bullet_speed() * 0.95, 3, 0.09)
			"chargeTele":
				p.x += (b.chX - p.x) * minf(1, dt * 3)
				p.y += (b.chY - p.y) * minf(1, dt * 3)
				b.warn.visible = true
				b.warn.scale = Vector3.ONE * (26 + absf(sin(b.t * 14)) * 28)
				if b.mT <= 0:
					b.mode = "charge"
					b.mT = 1.0
					b.warn.scale = Vector3.ONE * 24
			"charge":
				p.z += (-36 - p.z) * minf(1, dt * 5)
				b.warn.visible = true
				if not b.hitDone and b.mT < 0.55:
					b.hitDone = true
					for e in b.parts:
						if e.alive and not e.invul:
							enemy_shoot(e.x, e.y, e.z, bullet_speed() * 1.05, 3, 0.12)
					trauma = maxf(trauma, 0.4)
				if b.mT <= 0:
					b.mode = "retreat"
					b.mT = 1.3
			"retreat":
				p.z += (-60 - p.z) * minf(1, dt * 2.5)
				if b.mT <= 0:
					b.mode = "normal"
					b.chT = rand(8, 11)
			"tractor":
				_move_boss(b, dt * 0.4, enr)
				p = b.p
				if state == "play":
					var dx: float = p.x - M.ship_x
					var dy: float = p.y - M.ship_y
					var f := 7.5 * dt
					M.ship_x += signf(dx) * minf(absf(dx), f)
					M.ship_y += signf(dy) * minf(absf(dy), f * 0.7)
				if not b.has("tbeam"):
					var tb := MeshInstance3D.new()
					tb.mesh = shapes.cyl
					var tm := glow_line_mat(Color(0.29, 0.56, 1.0))
					tm.albedo_color.a = 0.22
					tb.material_override = tm
					M.add_child(tb)
					b.tbeam = tb
				b.tbeam.visible = true
				beam_between(b.tbeam, p, Vector3(M.ship_x, M.ship_y, 0), 1.8 + sin(b.t * 8) * 0.3)
				if b.mT <= 0:
					b.mode = "normal"
					b.trT = rand(9, 12)
			"blinkOut":
				b.node.scale = Vector3.ONE * b.sc * maxf(0.01, b.mT / 0.4)
				b.blinkHidden = true
				if b.mT <= 0:
					sparks(b.node.global_position, def.glow, 30)
					p = Vector3(rand(-BX * 0.7, BX * 0.7), rand(-BY * 0.3, BY * 0.6) + 2, rand(-68, -52))
					b.mode = "blinkIn"
					b.mT = 0.4
			"blinkIn":
				if b.mT <= 0:
					b.blinkHidden = false
					b.mode = "normal"
					b.blT = rand(5.5, 8)
			"flank":
				var k := minf(1, dt * 1.6)
				p.x += (b.side * (BX * 0.85) - p.x) * k
				p.y += (2 - p.y) * k
				p.z += (-40 - p.z) * k
				if b.mT <= 0:
					b.mode = "normal"
					b.flT = rand(8, 11)
		b.p = p
		b.spinBoost = maxf(1, b.spinBoost - dt * 0.6)
		for sp in b.node.get_meta("spin"):
			var o: Node3D = sp[0]
			var spd: float = sp[2]
			var ax: String = sp[1]
			var ai: int = {"x": 0, "y": 1, "z": 2}[ax]
			var rr: Vector3 = o.rotation
			if spd != 0.0:
				rr[ai] += spd * dt * (1.7 if enr else 1.0)
			else:
				rr[ai] = sin(b.t * (2.6 if enr else 1.6) + float(sp[3])) * 0.55
			o.rotation = rr
		if b.node.has_meta("worm"):
			var sg: Array = b.node.get_meta("worm")
			for i in sg.size():
				var ph: float = b.t * (2.4 if enr else 1.6) - i * 0.55
				sg[i].position = Vector3(sin(ph) * (3 + i * 0.9), cos(ph * 0.8) * (2 + i * 0.5) - i * 0.6, -i * 3.4)
				sg[i].rotation.z = ph * 0.3
			for e in b.parts:
				if e.seg >= 0:
					var off: Vector3 = sg[e.seg].position
					off.z += 4.5 if e.kind == "core" else 2.4
					e.off = off
		if b.has("doors"):
			var D: Dictionary = b.doors
			D.t += dt
			if D.t > (4.6 if D.open else 3.2):
				D.t = 0.0
				D.open = not D.open
				if D.open and not b.has("doorTold"):
					b.doorTold = true
					toast("PANZERTOR OFFEN – KERN TREFFEN!", Color(0.5, 1.0, 0.6))
			D.k += ((0.0 if D.open else 1.0) - D.k) * minf(1, dt * 5)
			D.L.position.x = -1.35 - (1 - D.k) * 3.4
			D.R.position.x = 1.35 + (1 - D.k) * 3.4
			D.L.rotation.y = -(1 - D.k) * 0.5
			D.R.rotation.y = (1 - D.k) * 0.5
			b.doorsClosed = D.k > 0.5
		var hp := 0.0
		for e in b.parts:
			if e.alive:
				hp += maxf(0, e.hp)
		hp /= b.maxhp
		if hp < 0.7 and rng.randf() < dt * (1 - hp) * 12:
			var q := w_of(b.p.x + rand(-9, 9) * b.sc * 0.7, b.p.y + rand(-5, 5) * b.sc * 0.7, b.p.z + rand(-2, 4))
			smoke(q, rand(1.6, 3))
			if rng.randf() < 0.4:
				sparks(q, Color(1.0, 0.7, 0.38), 5)
		if def.has("spin"):
			b.rot.z += def.spin * dt * (1.6 if enr else 1.0) * b.spinBoost
		elif b.mode == "flank":
			b.rot.y += (-b.side * 0.9 - b.rot.y) * minf(1, dt * 2)
		else:
			var ty: float = sin(b.ft * 0.42) * 0.38 + (p.x / BX) * -0.25
			b.rot.y += (ty - b.rot.y) * minf(1, dt * 2)
			b.rot.z += (-cos(b.ft * 0.35) * 0.32 - (p.x - b.get("lx", p.x)) * 0.6 - b.rot.z) * minf(1, dt * 3)
			b.rot.x = sin(b.ft * 0.3) * 0.12
			b.lx = p.x
	elif b.state == "dying":
		b.p = Vector3(b.p.x, b.p.y - dt * 4, b.p.z + dt * 8)
		b.rot.z += dt * 0.2
		b.rot.x += dt * 0.06
		if rng.randf() < dt * 12:
			smoke(w_of(b.p.x + rand(-12, 12) * b.sc, b.p.y + rand(-1, 3) * b.sc, b.p.z + rand(-5, 6)), rand(3, 5))
	if boss == null:
		return
	var sc: float = b.sc
	if b.mode == "blinkIn":
		sc = b.sc * minf(1, 1 - b.mT / 0.4 + 0.01)
	elif b.mode == "blinkOut":
		sc = b.sc * maxf(0.01, b.mT / 0.4)
	place(b.node, b.p.x, b.p.y, b.p.z, b.rot, sc)
	# Zielmarkierungen und Lebensbalken
	var tot := 0.0
	for e in b.parts:
		if e.alive:
			tot += maxf(0, e.hp)
	boss_bar.value = tot / b.maxhp * 100.0
	var cam: Camera3D = M.cam
	var vs := get_viewport().get_visible_rect().size
	var kk := 1280.0 / vs.x
	var mi := 0
	for e in b.parts:
		if mi >= markers.size():
			break
		var show: bool = e.alive and not e.invul and b.state != "dying" and not b.get("blinkHidden", false) and not b.get("decoy", false) and state == "play"
		if show:
			var wp: Vector3 = e.node.global_position
			if cam.is_position_behind(wp):
				continue
			var m: Label = markers[mi]
			mi += 1
			m.visible = true
			m.position = cam.unproject_position(wp) * kk - Vector2(30, 24)
			m.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25) if e.kind == "core" else (Color(0.38, 0.88, 1.0) if e.kind == "gen" else Color(0.25, 1.0, 0.31)))
	for j in range(mi, markers.size()):
		markers[j].visible = false

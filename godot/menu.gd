extends CanvasLayer
## Hauptmenü, Hangar, Weltauswahl, Einstellungen, Anleitung, Bestenliste, Pause

var M
var root: Control
var panel: Panel
var title: Label
var content: VBoxContainer

const UPG := [
	{"k": "armor", "n": "PANZERUNG", "d": "−10 % Schaden je Stufe"},
	{"k": "regen", "n": "SCHILDGENERATOR", "d": "Schild lädt 25 % schneller"},
	{"k": "gun", "n": "GRUNDWAFFE", "d": "+15 % Schaden"},
	{"k": "mis", "n": "RAKETENSCHACHT", "d": "+2 Raketen"},
	{"k": "roll", "n": "MANÖVRIERDÜSEN", "d": "Rolle 20 % schneller bereit"},
	{"k": "nuke", "n": "ATOMLAGER", "d": "+1 Atombombe zum Start je 2 Stufen"},
]
const UPCOST := [180, 420, 800, 1300]
const DIFFS := ["LEICHT", "NORMAL", "SCHWER"]

func setup(main) -> void:
	M = main
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

func _style(bg: Color, border: Color, rad := 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(rad)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func btn(txt: String, f: Callable, w := 420.0, h := 64.0, fs := 26) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(w, h)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_stylebox_override("normal", _style(Color(0.04, 0.1, 0.18, 0.78), Color(0.35, 0.85, 1.0, 0.85)))
	b.add_theme_stylebox_override("hover", _style(Color(0.08, 0.2, 0.32, 0.85), Color(0.5, 0.95, 1.0, 1.0)))
	b.add_theme_stylebox_override("pressed", _style(Color(0.15, 0.4, 0.55, 0.9), Color(0.7, 1.0, 1.0, 1.0)))
	b.add_theme_stylebox_override("disabled", _style(Color(0.05, 0.06, 0.08, 0.6), Color(0.3, 0.35, 0.4, 0.6)))
	b.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0))
	b.pressed.connect(func():
		M.audio.sfx("cube", -6.0, 0.0)
		f.call())
	return b

func lab(txt: String, fs := 22, col := Color(0.85, 0.95, 1.0)) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func clear() -> void:
	for c in root.get_children():
		c.queue_free()

func _frame(t: String, w := 760.0, h := 600.0) -> VBoxContainer:
	clear()
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.02, 0.05, 0.1, 0.82), Color(0.35, 0.85, 1.0, 0.7), 22))
	p.position = Vector2((1280 - w) / 2, (720 - h) / 2)
	p.size = Vector2(w, h)
	root.add_child(p)
	var v := VBoxContainer.new()
	v.position = Vector2(20, 16)
	v.size = Vector2(w - 40, h - 32)
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	p.add_child(v)
	v.add_child(lab(t, 38, Color(0.55, 0.95, 1.0)))
	return v

func _back(v: VBoxContainer) -> void:
	var c := CenterContainer.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(c)
	c.add_child(btn("ZURÜCK", show_main, 300, 58))

# ---------- Hauptmenü ----------
func show_main() -> void:
	clear()
	visible = true
	var t := lab("PRISMWING", 92, Color(0.55, 0.95, 1.0))
	t.position = Vector2(0, 40)
	t.size = Vector2(1280, 110)
	t.add_theme_constant_override("outline_size", 14)
	root.add_child(t)
	var s: Dictionary = M.get_save()
	var sub := lab("◆ %d KRISTALLE   ·   REKORD %d" % [int(s.get("cr", 0)), int(s.get("hs", 0))], 22, Color(1.0, 0.85, 0.4))
	sub.position = Vector2(0, 150)
	sub.size = Vector2(1280, 40)
	root.add_child(sub)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 22)
	g.add_theme_constant_override("v_separation", 16)
	g.position = Vector2(200, 230)
	root.add_child(g)
	g.add_child(btn("▶  SPIELEN", func(): M.start_game(int(s.get("world", 0)))))
	g.add_child(btn("◆  HANGAR", show_hangar))
	g.add_child(btn("🌍  WELT WÄHLEN", show_worlds))
	g.add_child(btn("⚙  EINSTELLUNGEN", show_settings))
	g.add_child(btn("?  ANLEITUNG", show_help))
	g.add_child(btn("★  BESTENLISTE", show_scores))
	var hint := lab("Steuern: linke Bildschirmhälfte ziehen  ·  Schießen automatisch", 18, Color(0.7, 0.85, 0.95, 0.8))
	hint.position = Vector2(0, 650)
	hint.size = Vector2(1280, 30)
	root.add_child(hint)

# ---------- Hangar ----------
func show_hangar() -> void:
	var v := _frame("HANGAR", 900, 640)
	var s: Dictionary = M.get_save()
	var cr := int(s.get("cr", 0))
	v.add_child(lab("◆ %d KRISTALLE  –  Kristalle gibt es für Bosse, große Gegner und komplette Würfelreihen" % cr, 18, Color(1.0, 0.85, 0.4)))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	var up: Dictionary = s.get("up", {})
	for u in UPG:
		var lv := int(up.get(u.k, 0))
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(420, 80)
		var info := Label.new()
		info.text = "%s  %s\n%s" % [u.n, "●".repeat(lv) + "○".repeat(4 - lv), u.d]
		info.add_theme_font_size_override("font_size", 17)
		info.custom_minimum_size = Vector2(270, 70)
		row.add_child(info)
		var cost: int = UPCOST[lv] if lv < 4 else 0
		var key: String = u.k
		var buy := func():
			var s2: Dictionary = M.get_save()
			var up2: Dictionary = s2.get("up", {})
			var l2 := int(up2.get(key, 0))
			if l2 >= 4 or int(s2.get("cr", 0)) < UPCOST[l2]:
				return
			M.put_save("cr", int(s2.get("cr", 0)) - UPCOST[l2])
			up2[key] = l2 + 1
			M.put_save("up", up2)
			show_hangar()
		var b := btn("MAX" if lv >= 4 else "◆ %d" % cost, buy, 140, 58, 20)
		b.disabled = lv >= 4 or cr < cost
		row.add_child(b)
		g.add_child(row)
	_back(v)

# ---------- Weltauswahl ----------
func show_worlds() -> void:
	var v := _frame("WELT WÄHLEN", 1000, 660)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	for i in M.WORLDS.size():
		var idx := i
		g.add_child(btn(M.WORLDS[i].name, func(): M.start_game(idx), 310, 62, 17))
	_back(v)

# ---------- Einstellungen ----------
func show_settings() -> void:
	var v := _frame("EINSTELLUNGEN", 640, 520)
	var s: Dictionary = M.get_save()
	var mus: bool = s.get("music", true)
	var snd: bool = s.get("sound", true)
	var dif := int(s.get("diff", 1))
	var c := VBoxContainer.new()
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_theme_constant_override("separation", 14)
	v.add_child(c)
	c.add_child(btn("MUSIK: " + ("AN" if mus else "AUS"), func():
		M.put_save("music", not mus)
		M.audio.set_music(not mus)
		show_settings()))
	c.add_child(btn("EFFEKTE: " + ("AN" if snd else "AUS"), func():
		M.put_save("sound", not snd)
		M.audio.sfx_on = not snd
		show_settings()))
	c.add_child(btn("SCHWIERIGKEIT: " + DIFFS[dif], func():
		M.put_save("diff", (dif + 1) % 3)
		show_settings()))
	c.add_child(btn("FORTSCHRITT ZURÜCKSETZEN", func():
		M.put_save("world", 0)
		show_settings()))
	_back(v)

# ---------- Anleitung ----------
func show_help() -> void:
	var v := _frame("ANLEITUNG", 960, 640)
	var t := lab("""STEUERN: Mit dem Finger auf der linken Bildschirmhälfte ziehen. Das Schiff schießt automatisch und visiert Gegner vor dir an (grüner Kreis).

RAKETEN: suchen sich die stärksten Gegner. Sie laden sich langsam wieder auf.
☢ ATOMBOMBE: zerstört alle Gegner und Schüsse im Bild.
ROLLE: kurz unverwundbar gegen Schüsse und schneller zur Seite.

POWER-UPS: LASER (blau), STREUFEUER (grün), PLASMA (pink) – mehrfach einsammeln für höhere Stufen. Treffer kosten Stufen.
Reparatur, Schutzschild, Raketen und Atombomben gibt es ebenfalls.

BOSSE: Erst die markierten Waffen zerstören, dann den Kern (gelb). Das Panzertor öffnet sich regelmäßig.
PASSAGEN: Grüne Schalter abschießen öffnet Tore und schaltet Laser ab.
ENERGIEWÜRFEL: Alle einer Reihe einsammeln gibt Kristalle für den Hangar.""", 19)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.custom_minimum_size = Vector2(900, 440)
	v.add_child(t)
	_back(v)

# ---------- Bestenliste ----------
func show_scores() -> void:
	var v := _frame("BESTENLISTE", 560, 600)
	var sv: Dictionary = M.get_save()
	var hs: Array = sv.get("hst", [])
	var txt := ""
	for i in mini(10, hs.size()):
		txt += "%2d.   %8d   Welle %d\n" % [i + 1, int(hs[i][0]), int(hs[i][1])]
	if txt == "":
		txt = "Noch keine Einträge – los geht's!"
	v.add_child(lab(txt, 24))
	_back(v)

# ---------- Pause ----------
func show_pause() -> void:
	var v := _frame("PAUSE", 520, 400)
	var c := VBoxContainer.new()
	c.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_theme_constant_override("separation", 16)
	v.add_child(c)
	c.add_child(btn("WEITER", func():
		clear()
		get_tree().paused = false))
	c.add_child(btn("HAUPTMENÜ", func():
		get_tree().paused = false
		M.to_menu()))

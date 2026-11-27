extends Node
## Musik (zwischen den Stücken ca. 2 s Pause) und Soundeffekte

var music: AudioStreamPlayer
var pool: Array = []
var pool_i := 0
var streams := {}
var tracks := {"menu": ["menu_zuendung"], "play": ["play_donnerschlag", "play_vollgas", "play_nachbrenner", "play_sternenwind"], "boss": ["boss_schlachtschiff", "boss_puls"]}
var cat := ""
var last_track := ""
var gap_t := -1.0
var last_play := {}
var music_on := true
var sfx_on := true

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.volume_db = -7.0
	add_child(music)
	music.finished.connect(func(): gap_t = 2.0)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)

func _load(n: String) -> AudioStream:
	if streams.has(n):
		return streams[n]
	var path := "res://audio/%s.ogg" % n
	if not ResourceLoader.exists(path):
		path = "res://audio/%s.wav" % n
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	streams[n] = s
	return s

func play_music(c: String) -> void:
	if c == cat and music.playing:
		return
	cat = c
	_next()

func _next() -> void:
	gap_t = -1.0
	if not music_on:
		music.stop()
		return
	var list: Array = tracks.get(cat, [])
	if list.is_empty():
		return
	var choice: String = list[randi() % list.size()]
	if list.size() > 1:
		while choice == last_track:
			choice = list[randi() % list.size()]
	last_track = choice
	var s := _load(choice)
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = false
	music.stream = s
	music.play()

func set_music(on: bool) -> void:
	music_on = on
	if on:
		_next()
	else:
		music.stop()

func _process(dt: float) -> void:
	if gap_t > 0:
		gap_t -= dt
		if gap_t <= 0:
			_next()

func sfx(n: String, vol := 0.0, pitch_var := 0.08, min_gap := 0.0) -> void:
	if not sfx_on:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if min_gap > 0 and now - float(last_play.get(n, -10.0)) < min_gap:
		return
	last_play[n] = now
	var s := _load(n)
	if s == null:
		return
	var p: AudioStreamPlayer = pool[pool_i]
	pool_i = (pool_i + 1) % pool.size()
	p.stream = s
	p.volume_db = vol
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

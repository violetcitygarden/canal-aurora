extends Node2D

var elapsed := 0.0
var duration := 1.85
var active := false
var font := SystemFont.new()
var sting := AudioStreamPlayer.new()

func _ready() -> void:
	font.font_names = PackedStringArray(["Arial"])
	font.font_weight = 900
	add_child(sting)
	sting.stream = AudioStreamMP3.load_from_file("res://music/transition.mp3")
	sting.volume_db = -5
	if sting.stream:
		duration = clampf(sting.stream.get_length(), 1.4, 2.6)

func begin() -> void:
	elapsed = 0
	active = true
	sting.play()
	queue_redraw()

func cancel() -> void:
	active = false
	sting.stop()
	queue_redraw()

func _process(delta: float) -> void:
	if active:
		elapsed += delta
		if elapsed >= duration:
			active = false
		queue_redraw()

func lettering(words: String, baseline: Vector2, size: int) -> void:
	var width := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := baseline - Vector2(width / 2, 0)
	for depth in range(9, 0, -1):
		draw_string(font, at + Vector2(depth, depth * 0.7), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#70502d"))
	draw_string_outline(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color("#f9e7ae"))
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#dfc187"))

func _draw() -> void:
	if not active:
		return
	var t := clampf(elapsed / duration, 0, 1)
	# Fast diagonal reveal, then a solid broadcast blue field.
	var cover := clampf(t / 0.12, 0, 1)
	draw_set_transform(Vector2((1 - cover) * 1000, 0))
	for y in range(600):
		var c := Color("#071329").lerp(Color("#245e9c"), sin(float(y) / 600 * PI))
		draw_rect(Rect2(0, y, 800, 1), c)
	for i in range(9):
		var x := fposmod(i * 150.0 + elapsed * 170, 1350) - 300
		draw_line(Vector2(x, 600), Vector2(x + 330, 0), Color(0.45, 0.65, 0.85, 0.13), 24)
	# Rotating projected wire globe, like a station ident rendered on early workstations.
	for latitude in range(-60, 61, 20):
		var points := PackedVector2Array()
		var lat := deg_to_rad(float(latitude))
		for j in range(97):
			var lon := j * TAU / 96 + elapsed * 0.9
			points.append(Vector2(400 + cos(lat) * cos(lon) * 235, 290 + sin(lat) * 210 + cos(lat) * sin(lon) * 48))
		draw_polyline(points, Color(0.55, 0.76, 0.95, 0.28), 1.2, true)
	for meridian in range(10):
		var points := PackedVector2Array()
		var lon := meridian * PI / 10 + elapsed * 0.9
		for j in range(97):
			var lat := j * TAU / 96
			points.append(Vector2(400 + cos(lat) * cos(lon) * 235, 290 + sin(lat) * 210 + cos(lat) * sin(lon) * 48))
		draw_polyline(points, Color(0.55, 0.76, 0.95, 0.24), 1.2, true)
	var arrival := 1.0 - pow(1.0 - clampf(t / 0.38, 0, 1), 3)
	var departure := pow(clampf((t - 0.77) / 0.23, 0, 1), 3)
	var center := Vector2(400 + (1 - arrival) * -900 + departure * 1050, 300 + (1 - arrival) * 130 - departure * 160)
	var zoom := lerpf(0.35, 1.0, arrival) + departure * 0.5
	draw_set_transform(center, (1 - arrival) * -0.3 + departure * 0.2, Vector2(zoom, zoom))
	lettering("JORNAL", Vector2(0, -20), 43)
	lettering("AURORA", Vector2(0, 62), 88)
	draw_line(Vector2(-233, 85), Vector2(233, 85), Color("#efd99e"), 3)
	draw_string(font, Vector2(-139, 114), "E D I Ç Ã O   R E G I O N A L", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#d7e4ef"))
	draw_set_transform(Vector2.ZERO)
	for y in range(0, 600, 3):
		draw_line(Vector2(0, y), Vector2(800, y), Color(0, 0, 0, 0.055))

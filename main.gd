extends Node2D

const GOLD = Color("#f2d989")
const WHITE = Color("#f3f1dc")
var font = SystemFont.new()
var bold = SystemFont.new()
var data: Dictionary
var elapsed := 0.0
var page_time := 0.0
var page := 0
var paused := false
var crt := true
var help := false
var audio := AudioStreamPlayer.new()
var ticker_width := 0.0
var capture_done := false

func _ready() -> void:
	font.font_names = PackedStringArray(["Arial", "Liberation Sans"])
	bold.font_names = font.font_names
	bold.font_weight = 700
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://weather.json"))
	if not parsed is Dictionary:
		push_error("weather.json inválido")
		get_tree().quit(1)
		return
	data = parsed
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--page="):
			page = clampi(int(arg.trim_prefix("--page=")), 0, 2)
	ticker_width = bold.get_string_size(data.ticker, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
	add_child(audio)
	audio.volume_db = -10
	audio.finished.connect(func(): audio.play())
	get_window().files_dropped.connect(_files_dropped)

func _process(delta: float) -> void:
	elapsed += delta
	if not paused:
		page_time += delta
		if page_time >= 14.0:
			page_time = 0
			page = (page + 1) % 3
	queue_redraw()
	if "--capture" in OS.get_cmdline_user_args() and elapsed > 1 and not capture_done:
		capture_done = true
		_capture()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://preview-%d.png" % page)
	get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_F2:
			get_tree().change_scene_to_file("res://news.tscn")
		KEY_RIGHT, KEY_SPACE:
			page = (page + 1) % 3
			page_time = 0
		KEY_LEFT:
			page = (page + 2) % 3
			page_time = 0
		KEY_P: paused = not paused
		KEY_C: crt = not crt
		KEY_H: help = not help
		KEY_M: audio.stream_paused = not audio.stream_paused
		KEY_F11:
			get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		KEY_ESCAPE:
			get_window().mode = Window.MODE_WINDOWED

func _files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	var path := files[0]
	var stream: AudioStream
	match path.get_extension().to_lower():
		"mp3": stream = AudioStreamMP3.load_from_file(path)
		"ogg": stream = AudioStreamOggVorbis.load_from_file(path)
		"wav": stream = AudioStreamWAV.load_from_file(path)
	if stream != null:
		audio.stream = stream
		audio.play()

func txt(s: String, x: float, y: float, size: int = 25, color: Color = WHITE, strong: bool = true) -> void:
	var f: Font = bold if strong else font
	draw_string(f, Vector2(x + 2, y + 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.015, 0.03, 0.09, 0.9))
	draw_string(f, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func gradient(rect: Rect2, top: Color, bottom: Color) -> void:
	var count := int(rect.size.y)
	for row in range(count):
		var c := top.lerp(bottom, float(row) / maxf(1, count - 1))
		draw_rect(Rect2(rect.position + Vector2(0, row), Vector2(rect.size.x, 1)), c)

func panel(rect: Rect2) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color("#041331"))
	gradient(rect, Color("#26559b"), Color("#101f56"))
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("#7d9ebf"), 2)
	draw_line(rect.position, rect.position + Vector2(0, rect.size.y), Color("#577fae"), 2)
	draw_line(rect.end - Vector2(rect.size.x, 0), rect.end, Color("#060e31"), 2)

func weather_icon(center: Vector2, scale_factor: float, rain: bool = false) -> void:
	draw_set_transform(center, 0, Vector2.ONE * scale_factor)
	if not rain:
		for i in range(12):
			var angle := i * TAU / 12
			draw_line(Vector2(cos(angle), sin(angle)) * 32 + Vector2(14, -16), Vector2(cos(angle), sin(angle)) * 43 + Vector2(14, -16), GOLD, 4, true)
		draw_circle(Vector2(16, -13), 28, Color("#99602e"))
		draw_circle(Vector2(13, -17), 27, Color("#f5d15a"))
	var spheres := [Vector3(-31, 10, 18), Vector3(-12, -3, 27), Vector3(15, 9, 24), Vector3(36, 17, 15)]
	for p in spheres:
		draw_circle(Vector2(p.x + 3, p.y + 5), p.z, Color("#102343"))
	for p in spheres:
		draw_circle(Vector2(p.x, p.y), p.z, Color("#90a8c0"))
	for p in spheres:
		draw_circle(Vector2(p.x - 2, p.y - 5), p.z * 0.84, Color("#eef0e5"))
	if rain:
		for i in range(5):
			var x := -29.0 + i * 15
			draw_line(Vector2(x, 40), Vector2(x - 7, 54), Color("#90c5e5"), 3, true)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if data.is_empty():
		return
	gradient(Rect2(0, 0, 800, 600), Color("#315ca0"), Color("#060f39"))
	# Wide restrained light bands, like an electronic broadcast background.
	for i in range(7):
		draw_line(Vector2(0, 157 + i * 5), Vector2(800, 109 + i * 5), Color(0.37, 0.57, 0.8, 0.035), 2)
	draw_rect(Rect2(34, 30, 105, 87), Color("#061338"))
	gradient(Rect2(31, 27, 105, 87), Color("#448aca"), Color("#16417c"))
	draw_rect(Rect2(31, 27, 105, 87), Color("#bfd0d9"), false, 2)
	txt("CANAL", 43, 51, 18)
	txt("AURORA", 39, 79, 21)
	txt("TEMPO", 48, 101, 15, GOLD)
	var titles := ["Condições atuais", "Previsão de 36 horas", "Próximos três dias"]
	txt(titles[page], 162, 70, 36)
	txt(data.region.to_upper(), 164, 103, 16, GOLD)
	var seconds := 18 * 3600 + 42 * 60 + int(elapsed)
	txt("SEX  17 SET 1993", 461, 132, 17)
	txt("%02d:%02d:%02d" % [seconds / 3600 % 24, seconds / 60 % 60, seconds % 60], 668, 132, 19)
	draw_line(Vector2(34, 143), Vector2(766, 143), Color("#9baac1"), 2)
	txt(data.city + " e região", 49, 181, 28, GOLD)
	panel(Rect2(35, 199, 730, 302))
	if page == 0:
		txt(data.condition, 62, 242, 28)
		weather_icon(Vector2(178, 327), 1.2)
		txt(str(int(data.temperature)) + "°", 111, 453, 76)
		draw_line(Vector2(329, 259), Vector2(329, 472), Color("#6684ad"), 1)
		var rows := [["Umidade", str(int(data.humidity)) + "%"], ["Vento", data.wind], ["Pressão", data.pressure + " hPa"], ["Visibilidade", "16 km"]]
		for i in range(rows.size()):
			txt(rows[i][0], 360, 296 + i * 50, 24, GOLD)
			txt(rows[i][1], 541, 296 + i * 50, 24)
	elif page == 1:
		var y := 242
		for item in data.forecast:
			txt(item.period, 60, y, 27, GOLD)
			y += 32
			for line in item.lines:
				txt(line, 60, y, 24, WHITE, false)
				y += 30
			y += 14
	else:
		for i in range(3):
			var x := 52 + i * 239
			if i > 0:
				draw_line(Vector2(x - 10, 218), Vector2(x - 10, 481), Color("#6684ad"), 1)
			var day: Dictionary = data.days[i]
			txt(day.name, x + 67, 241, 27, GOLD)
			weather_icon(Vector2(x + 100, 304), 0.85, day.rain)
			var lines: PackedStringArray = str(day.condition).replace("\n", "
").split("
")
			for j in range(lines.size()):
				txt(lines[j], x + 36, 378 + j * 27, 23)
			txt(str(int(day.high)) + "°", x + 31, 463, 43)
			txt(str(int(day.low)) + "°", x + 124, 463, 37, Color("#abc7e5"))
	# Continuous information strip is independent from the forecast page.
	gradient(Rect2(0, 523, 800, 45), Color("#254d84"), Color("#0d214b"))
	draw_line(Vector2(0, 522), Vector2(800, 522), Color("#b4bdc8"), 2)
	var scroll := fmod(elapsed * 47, ticker_width)
	txt(data.ticker, -scroll, 553, 21)
	txt(data.ticker, ticker_width - scroll, 553, 21)
	txt("AURORA  /  SERVIÇO REGIONAL DE METEOROLOGIA", 35, 588, 13, Color("#9fb6d0"))
	for i in range(3):
		draw_rect(Rect2(707 + i * 19, 577, 11, 5), GOLD if i == page else Color("#52729f"))
	if page_time < 0.5:
		draw_rect(Rect2(36, 200, 728, 300), Color(0.05, 0.13, 0.32, (1 - page_time / 0.5) * 0.65))
	if crt:
		for y in range(0, 600, 3):
			draw_line(Vector2(0, y), Vector2(800, y), Color(0, 0, 0, 0.035), 1)
	if help:
		draw_rect(Rect2(75, 213, 650, 242), Color("#08162e"))
		txt("CONTROLE DA TRANSMISSÃO", 101, 251, 23, GOLD)
		txt("← / →  telas     P  pausar     C  textura de TV", 101, 294, 21)
		txt("F11  tela cheia     M  silenciar     H  ajuda", 101, 332, 21)
		txt("Arraste um MP3, OGG ou WAV para tocar em loop.", 101, 380, 21)
		txt("Cidade e boletins fictícios • protótipo artístico", 101, 422, 19, GOLD)


extends Node2D

const CREAM := Color("#f3edd7")
const GOLD := Color("#e1c17d")
var font := SystemFont.new()
var regular := SystemFont.new()
var items: Array = []
var index := 0
var elapsed := 0.0
var entry := 0.0
var crt := true
var help := false
var show_caption := true
var audio := AudioStreamPlayer.new()
var weather_audio := AudioStreamPlayer.new()
var music_muted := false
var automatic := true
var received_first := false
var body_visible := false
var body_scroll := 0
var ident: Node2D
var pending_index := -1
var pre_read := -1.0
var awkward := false
var reporter_panel: Node2D
var weather_panel: Node2D
var news_music_on := true
var news_music_timer := 0.0
var news_music_next := 52.0

func _ready() -> void:
	font.font_names = PackedStringArray(["Arial", "Liberation Sans"])
	font.font_weight = 700
	regular.font_names = font.font_names
	reload_news()
	add_child(audio)
	audio.volume_db = -10
	audio.finished.connect(func(): audio.play())
	_drop_audio(PackedStringArray(["res://music/newsreportmusic.mp3"]))
	news_music_next = randf_range(38.0, 68.0)
	add_child(weather_audio)
	weather_audio.stream = AudioStreamMP3.load_from_file("res://music/tempo.mp3")
	weather_audio.volume_db = -80
	weather_audio.finished.connect(func():
		if weather_panel.visible:
			weather_audio.play()
	)
	weather_panel = Node2D.new()
	weather_panel.set_script(load("res://weather_panel.gd"))
	weather_panel.show_behind_parent = true
	add_child(weather_panel)
	reporter_panel = Node2D.new()
	reporter_panel.set_script(load("res://reporter_panel.gd"))
	reporter_panel.show_behind_parent = true
	add_child(reporter_panel)
	ident = Node2D.new()
	ident.set_script(load("res://transition.gd"))
	add_child(ident)
	get_window().files_dropped.connect(_drop_audio)
	NewsFeed.story_ready.connect(_story_ready)
	if not NewsFeed.queue.is_empty():
		_story_ready()

func _story_ready() -> void:
	if received_first and not NewsFeed.queue.is_empty() and NewsFeed.queue[0].get("kind", "") == "weather":
		_next_generated()
	elif automatic and not received_first:
		_next_generated()

func _next_generated() -> bool:
	if pending_index >= 0 or pre_read >= 0:
		return true
	var story: Dictionary = NewsFeed.take()
	if story.is_empty():
		return false
	items.append(story)
	if items.size() > 30:
		items.pop_front()
	received_first = true
	_switch_story(items.size() - 1)
	return true

func _switch_story(next_index: int) -> void:
	Narration.stop()
	pre_read = -1
	pending_index = next_index
	ident.begin()

func _update_handoff(delta: float) -> void:
	if pending_index >= 0:
		if ident.active:
			return
		index = pending_index
		weather_panel.set_story(items[index])
		reporter_panel.set_story(items[index])
		if weather_panel.visible and not weather_audio.playing:
			weather_audio.play()
		pending_index = -1
		entry = 0
		body_scroll = 0
		awkward = randf() < 0.28
		if "--test-pause" in OS.get_cmdline_user_args():
			awkward = true
		pre_read = randf_range(3.5, 6.5) if awkward else randf_range(0.3, 0.8)
	elif pre_read >= 0:
		pre_read -= delta
		if pre_read < 0:
			Narration.play_story(items[index])
			awkward = false

func _exit_tree() -> void:
	Narration.stop()

func reload_news() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://news.json"))
	if parsed is Dictionary and parsed.get("noticias") is Array:
		var valid: Array = []
		for item in parsed.noticias:
			if item is Dictionary and item.get("manchete") is String and item.get("texto") is String:
				valid.append(item)
		if not valid.is_empty():
			pending_index = -1
			pre_read = -1
			awkward = false
			if is_instance_valid(ident):
				ident.cancel()
			items = valid
			if is_instance_valid(weather_panel):
				weather_panel.set_story({})
			if is_instance_valid(reporter_panel):
				reporter_panel.set_story({})
			index = mini(index, items.size() - 1)
			entry = 0
			Narration.stop()
			return
	push_warning("news.json inválido: mantida a última notícia válida.")

func _process(delta: float) -> void:
	elapsed += delta
	entry += delta
	_update_handoff(delta)
	news_music_timer += delta
	if news_music_timer >= news_music_next:
		news_music_timer = 0.0
		news_music_on = not news_music_on
		news_music_next = randf_range(28.0, 58.0) if not news_music_on else randf_range(42.0, 78.0)
	var has_voice: bool = not items.is_empty() and items[index].has("_stream")
	var next_due := (not Narration.player.playing and Narration.silence >= 2.0) if has_voice else entry >= float(NewsFeed.config.get("seconds_per_story", 40))
	if automatic and next_due and pending_index < 0 and pre_read < 0:
		_next_generated()
	var music_level := -10.0
	if Narration.player.playing:
		music_level = -22.0
	if pending_index >= 0:
		music_level = -28.0
	if pre_read >= 0 and awkward:
		music_level = -38.0
	var is_weather: bool = weather_panel.visible
	var news_level := music_level if not is_weather and not music_muted and news_music_on else -80.0
	var weather_level := music_level if is_weather and not music_muted else -80.0
	audio.volume_db = move_toward(audio.volume_db, news_level, delta * 40)
	weather_audio.volume_db = move_toward(weather_audio.volume_db, weather_level, delta * 40)
	if not is_weather and weather_audio.volume_db <= -79:
		weather_audio.stop()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_RIGHT, KEY_SPACE:
			if not _next_generated():
				if not items.is_empty():
					_switch_story((index + 1) % items.size())
			entry = 0
			body_scroll = 0
		KEY_LEFT:
			if not items.is_empty() and pending_index < 0 and pre_read < 0:
				_switch_story((index - 1 + items.size()) % items.size())
			entry = 0
			body_scroll = 0
		KEY_A: automatic = not automatic
		KEY_E:
			NewsFeed.request_reporter()
		KEY_F3:
			if reporter_panel.visible:
				reporter_panel.cycle_location()
		KEY_W:
			NewsFeed.request_weather()
		KEY_G:
			if not _next_generated():
				NewsFeed.generate()
		KEY_T:
			body_visible = not body_visible
			body_scroll = 0
		KEY_DOWN: body_scroll += 1
		KEY_UP: body_scroll = maxi(0, body_scroll - 1)
		KEY_R: reload_news()
		KEY_C: crt = not crt
		KEY_H: help = not help
		KEY_L: show_caption = not show_caption
		KEY_M:
			music_muted = not music_muted
			if not music_muted and not audio.playing and audio.stream:
				audio.play()
		KEY_V: Narration.toggle_mute()
		KEY_F2: get_tree().change_scene_to_file("res://main.tscn")
		KEY_F11:
			get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		KEY_ESCAPE: get_window().mode = Window.MODE_WINDOWED

func _drop_audio(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	var stream: AudioStream
	match files[0].get_extension().to_lower():
		"mp3": stream = AudioStreamMP3.load_from_file(files[0])
		"wav": stream = AudioStreamWAV.load_from_file(files[0])
		"ogg": stream = AudioStreamOggVorbis.load_from_file(files[0])
	if stream:
		audio.stream = stream
		audio.play()

func gradient(r: Rect2, a: Color, b: Color) -> void:
	for y in range(int(r.size.y)):
		draw_rect(Rect2(r.position + Vector2(0, y), Vector2(r.size.x, 1)), a.lerp(b, y / r.size.y))

func text(value: String, position: Vector2, size: int, color := CREAM, strong := true) -> void:
	var f: Font = font if strong else regular
	draw_string(f, position + Vector2(2, 2), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#061326"))
	draw_string(f, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func wrapped(value: String, size: int, width: float) -> PackedStringArray:
	var result := PackedStringArray()
	var line := ""
	for word in value.replace("\n", " ").split(" ", false):
		var candidate := word if line.is_empty() else line + " " + word
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and not line.is_empty():
			result.append(line)
			line = word
		else:
			line = candidate
	if not line.is_empty():
		result.append(line)
	return result

func fitted(value: String, size: int, width: float) -> String:
	var output := value.replace("\n", " ")
	if font.get_string_size(output, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
		return output
	while output.length() > 0 and font.get_string_size(output + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		output = output.left(output.length() - 1)
	return output.strip_edges() + "…"

func _draw() -> void:
	if is_instance_valid(weather_panel) and weather_panel.visible:
		if help or body_visible:
			draw_rect(Rect2(48, 130, 704, 350), Color("#081b36"))
			text("TEMPO LOCAL • CONTROLES", Vector2(70, 165), 23, GOLD)
			text("Espaço próxima • W pedir tempo • T texto • H ajuda", Vector2(70, 199), 18)
			text("A automático • M música • V voz • F2 clássico", Vector2(70, 226), 18)
			var lines := wrapped(str(items[index].get("texto", "")) if body_visible else NewsFeed.status, 18, 650)
			body_scroll = clampi(body_scroll, 0, maxi(0, lines.size() - 8))
			for i in range(mini(8, lines.size() - body_scroll)):
				text(lines[body_scroll + i], Vector2(70, 261 + i * 25), 18)
		return
	text("CANAL AURORA", Vector2(37, 40), 14, Color("#c3ccda"))
	text("EDIÇÃO REGIONAL", Vector2(37, 59), 10, Color("#8fa5bf"))
	var seconds := 18 * 3600 + 42 * 60 + int(elapsed)
	text("%02d:%02d" % [seconds / 3600 % 24, seconds / 60 % 60], Vector2(703, 43), 20)
	if show_caption and not items.is_empty():
		var item: Dictionary = items[index]
		var offset := (1.0 - ease(clampf(entry / 0.55, 0, 1), 0.4)) * 820
		draw_set_transform(Vector2(-offset, 0))
		draw_rect(Rect2(38, 442, 730, 124), Color(0.01, 0.03, 0.09, 0.5))
		gradient(Rect2(35, 436, 730, 109), Color("#32669c"), Color("#10274f"))
		draw_line(Vector2(35, 436), Vector2(765, 436), Color("#b3cad9"), 2)
		draw_line(Vector2(35, 544), Vector2(765, 544), GOLD, 2)
		gradient(Rect2(35, 405, 285, 30), Color("#e0c997"), Color("#a78d59"))
		text(fitted(str(item.get("editoria", "REGIÃO")), 16, 261), Vector2(48, 426), 16, Color("#f8f0d4"))
		gradient(Rect2(35, 438, 122, 105), Color("#163b6a"), Color("#08182f"))
		text("JORNAL", Vector2(48, 475), 19)
		text("AURORA", Vector2(46, 502), 22, GOLD)
		text("REGIONAL", Vector2(53, 524), 12, Color("#a8bdd4"))
		var font_size := 29
		var lines := wrapped(item.manchete, font_size, 564)
		while lines.size() > 2 and font_size > 23:
			font_size -= 1
			lines = wrapped(item.manchete, font_size, 564)
		var y := 480 if lines.size() == 1 else 468
		for i in range(mini(lines.size(), 2)):
			var line := lines[i]
			if i == 1 and lines.size() > 2:
				line += "…"
			text(fitted(line, font_size, 564), Vector2(177, y + i * 34), font_size)
		text(fitted(str(item.get("resumo", "")), 15, 564), Vector2(177, 527), 15, Color("#d3dce4"))
		draw_set_transform(Vector2.ZERO)
	text("VALE DO CEDRO", Vector2(37, 581), 12, Color("#a2b5cc"))
	text("17 SET 1993", Vector2(674, 581), 12, Color("#a2b5cc"))
	if crt:
		for y in range(0, 600, 3):
			draw_line(Vector2(0, y), Vector2(800, y), Color(0, 0, 0, 0.045), 1)
	if body_visible and not items.is_empty():
		draw_rect(Rect2(55, 85, 690, 303), Color("#081b36"))
		text("TEXTO DA NOTÍCIA", Vector2(75, 114), 18, GOLD)
		var body_lines := wrapped(str(items[index].texto), 19, 645)
		body_scroll = clampi(body_scroll, 0, maxi(0, body_lines.size() - 8))
		for i in range(mini(8, body_lines.size() - body_scroll)):
			text(fitted(body_lines[body_scroll + i], 19, 645), Vector2(75, 147 + i * 26), 19)
		text("↑ / ↓ rolar   •   T fechar", Vector2(75, 374), 13, GOLD)
	if help:
		draw_rect(Rect2(74, 135, 652, 262), Color("#081b36"))
		text("CONTROLE DO JORNAL", Vector2(98, 205), 24, GOLD)
		text("A  automático: %s    G  próxima IA    T  ler texto" % ("SIM" if automatic else "NÃO"), Vector2(98, 241), 19)
		text("← / → manchete   L faixa   R exemplos   H ajuda", Vector2(98, 274), 19)
		text("E repórter  F3 cenário  W tempo  M música  V voz", Vector2(98, 307), 17)
		text(fitted(NewsFeed.status, 17, 600), Vector2(98, 345), 17, GOLD)
		text("Fila: %d • %s" % [NewsFeed.queue.size(), str(NewsFeed.config.get("model", ""))], Vector2(98, 375), 15)

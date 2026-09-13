extends Node
var view: SubViewport
var screen: TextureRect
var actors: Dictionary = {}
var cameras: Array[Camera3D] = []
var voice := AudioStreamPlayer.new()
var laughter := AudioStreamPlayer.new()
var ambience := AudioStreamPlayer.new()
var door_sound := AudioStreamPlayer.new()
var door_open_stream: AudioStream
var door_close_stream: AudioStream
var door_opened := false
var door_close_pending := false
var http := HTTPRequest.new()
var config: Dictionary = {}
var lines: Array = []
var line_index := -1
var last_scene_end_ms := 0
var active := ""
var envelope: Array = []
var state := "waiting"
var remaining := 0.0
var fetch_timer := 0.0
var fetching := false
var paused := false
var captions: Label
var status_label: Label
var help_label: Label
var heading: Label
var laughs: Array[AudioStream] = []
var server_port := 11450
var help := false
var vhs := true
var elapsed := 0.0
var scene_number := 0
var rng := RandomNumberGenerator.new()
var camera_index := 0
var forced_capture := false
var pending_scene: Dictionary = {}
var shot_left := 0.0
var shot_kind := 0
var shot_front := Vector3.FORWARD
var shot_focus := Vector3.ZERO
var shot_initializing := true
var special_camera: Camera3D
var staging_actor: Node3D
var ready_to_speak := false
var logged_state := ""
var diagnostic_left := 0.0
var server_progress := ""
var entrance_camera: Camera3D
var entrance_name: Label
var entrance_actor: Node3D
var entrance_left := 0.0
var entrance_jingle := AudioStreamPlayer.new()
var entrance_pause := false
const ENTRANCE_SECONDS := 3.2
func _ready() -> void:
	rng.randomize()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://config.json"))
	if parsed is Dictionary: config = parsed
	var port := OS.get_environment("PENSAO_PORT")
	if port.is_valid_int(): server_port = int(port)
	view = SubViewport.new()
	view.size = Vector2i(320,240)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var kitchen := Node3D.new()
	kitchen.set_script(load("res://kitchen.gd"))
	view.add_child(kitchen)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#343c35")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#e0d4ab")
	env.environment.ambient_light_energy = 0.75
	view.add_child(env)
	var light := OmniLight3D.new()
	light.position = Vector3(0,3.5,0)
	light.light_color = Color("#ffe4b0")
	light.light_energy = 1.5
	light.omni_range = 13
	view.add_child(light)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-30,0)
	sun.light_energy = 0.45
	view.add_child(sun)
	for id in ["NAIR","VALDIR","JESSICA","MAURO"]:
		var actor := Node3D.new()
		actor.set_script(load("res://actor.gd"))
		actor.identity = id
		view.add_child(actor)
		actors[id] = actor
	for pos in [Vector3(0,3.1,8.5),Vector3(-4.6,3.0,5.8),Vector3(4.6,3.2,5.8)]:
		var camera := Camera3D.new()
		camera.position = pos
		camera.fov = 58
		view.add_child(camera)
		camera.look_at(Vector3(0,1.25,-1))
		cameras.append(camera)
	special_camera = Camera3D.new()
	view.add_child(special_camera)
	entrance_camera = Camera3D.new()
	view.add_child(entrance_camera)
	# Render the credit at TV resolution so it shares the pixelation and VHS.
	var credit_layer := CanvasLayer.new()
	view.add_child(credit_layer)
	entrance_name = make_label(credit_layer, Vector2(12,165), Vector2(296,38), 23)
	var credit_font := SystemFont.new()
	credit_font.font_names = PackedStringArray(["Arial", "Liberation Sans"])
	credit_font.font_weight = 900
	credit_font.font_italic = true
	entrance_name.add_theme_font_override("font", credit_font)
	entrance_name.add_theme_color_override("font_color", Color("#fff04a"))
	entrance_name.add_theme_color_override("font_outline_color", Color("#54205f"))
	entrance_name.add_theme_constant_override("outline_size", 3)
	entrance_name.add_theme_color_override("font_shadow_color", Color("#d93878"))
	entrance_name.add_theme_constant_override("shadow_offset_x", 3)
	entrance_name.add_theme_constant_override("shadow_offset_y", 3)
	entrance_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entrance_name.pivot_offset = Vector2(148,19)
	entrance_name.rotation = deg_to_rad(-3)
	entrance_name.hide()
	cameras[0].current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	screen = TextureRect.new()
	screen.texture = view.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.size = Vector2(960,720)
	var shader := ShaderMaterial.new()
	shader.shader = preload("res://vhs.gdshader")
	screen.material = shader
	layer.add_child(screen)
	var logo := Control.new()
	logo.set_script(preload("res://logo.gd"))
	logo.position = Vector2(25,18)
	logo.size = Vector2(250,140)
	layer.add_child(logo)
	heading = make_label(layer,Vector2(33,164),Vector2(240,28),16)
	heading.text = ""
	captions = make_label(layer,Vector2(70,580),Vector2(710,110),24)
	captions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	captions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label = make_label(layer,Vector2(30,505),Vector2(900,70),16)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.text = "Preparando a próxima conversa…"
	help_label = make_label(layer,Vector2(30,200),Vector2(850,100),18)
	help_label.text = "ESPAÇO pausa • C câmera • V VHS • H ajuda\nDiálogos cotidianos • Risadas por sorteio, sem avaliar o texto"
	help_label.hide()
	add_child(voice)
	voice.volume_db = -2
	add_child(laughter)
	laughter.volume_db = -10
	add_child(ambience)
	ambience.volume_db = float(config.get("ambience_volume_db", -20.0))
	ambience.stream = load_recording("res://audio/ambiencia1.mp3", true)
	if ambience.stream: ambience.play()
	add_child(door_sound)
	add_child(entrance_jingle)
	entrance_jingle.stream = load_recording("res://audio/jingle.mp3")
	entrance_jingle.volume_db = float(config.get("entrance_jingle_volume_db", -12.0))
	door_sound.volume_db = float(config.get("door_volume_db", -14.0))
	door_open_stream = load_recording("res://audio/creaking_door.mp3")
	door_close_stream = load_recording("res://audio/close_door.mp3")
	add_child(http)
	http.timeout = 8
	http.body_size_limit = 24*1024*1024
	http.request_completed.connect(_received)
	# User recordings are read directly; no imported resource or synthetic cache needed.
	var recordings := DirAccess.get_files_at("res://audio")
	recordings.sort()
	for filename in recordings:
		if not filename.to_lower().begins_with("laugh"): continue
		var path := "res://audio/" + filename
		var stream: AudioStream
		if filename.get_extension().to_lower() == "mp3":
			var mp3 := AudioStreamMP3.new()
			mp3.data = FileAccess.get_file_as_bytes(path)
			stream = mp3
		elif filename.get_extension().to_lower() == "wav":
			stream = AudioStreamWAV.load_from_file(path)
		if stream and stream.get_length() > 0:
			laughs.append(stream)
	if laughs.is_empty():
		push_warning("Nenhuma risada válida em pensao/audio (MP3 ou WAV).")
	forced_capture = "--capture" in OS.get_cmdline_user_args()
	if forced_capture:
		state = "capture"
		status_label.text = ""
func load_recording(path: String, looping := false) -> AudioStream:
	if not FileAccess.file_exists(path): return null
	var stream := AudioStreamMP3.new()
	stream.data = FileAccess.get_file_as_bytes(path)
	stream.loop = looping
	return stream if stream.get_length() > 0 else null

func open_door_sound() -> void:
	door_opened = true
	door_close_pending = false
	if door_open_stream:
		door_sound.stream = door_open_stream
		door_sound.play()

func make_label(parent: Node, at: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("#ece8ca"))
	label.add_theme_color_override("font_shadow_color",Color("#202723"))
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	parent.add_child(label)
	return label
func _process(delta: float) -> void:
	elapsed += delta
	diagnostic_left -= delta
	if state != logged_state or diagnostic_left <= 0:
		logged_state = state
		diagnostic_left = 10.0
		var movement := ""
		if is_instance_valid(staging_actor) and staging_actor.staging:
			movement = " actor=%s move_seconds=%.1f position=%s target=%s" % [staging_actor.identity, staging_actor.stage_elapsed, staging_actor.position, staging_actor.stage_target]
		print("PENSAO_STATE time=", Time.get_datetime_string_from_system(), " scene=", scene_number, " line=", line_index, " state=", state, " paused=", paused, " voice=", voice.playing, " laughter=", laughter.playing, " prefetched=", not pending_scene.is_empty(), " fetching=", fetching, movement)
	if forced_capture and elapsed>1.0:
		forced_capture = false
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/pensao-preview.png")
		get_tree().quit()
	if paused: return
	if door_close_pending and not door_sound.playing:
		door_close_pending = false
		if door_close_stream:
			door_sound.stream = door_close_stream
			door_sound.play()
	update_shot(delta)
	if state != "capture" and pending_scene.is_empty():
		fetch_timer -= delta
		if fetch_timer <= 0 and not fetching:
			fetch_timer = 2
			fetching = true
			if http.request("http://127.0.0.1:%d/next" % server_port) != OK:
				fetching = false
	if state == "transition":
		if staging_actor.staging and not door_opened and staging_actor.position.distance_to(Vector3(4.8,0,-3.4)) < 1.2:
			open_door_sound()
		if staging_actor.stage_elapsed > 6:
			status_label.text = "Aguardando " + staging_actor.identity.capitalize() + " passar…"
		if not staging_actor.staging:
			if door_opened:
				door_close_pending = true
				door_opened = false
			if entrance_pause:
				if entrance_jingle.playing and entrance_jingle.get_playback_position() < 9.0: return
				entrance_pause = false
				ready_to_speak = false
				print("PENSAO_ENTRANCE_SPEECH jingle_seconds=", entrance_jingle.get_playback_position(), " actor=", staging_actor.identity)
				start_line()
				return
			status_label.text = ""
			state = "gap"
			remaining = 0.6
			ready_to_speak = true
		return
	for actor in actors.values(): actor.opening = 0
	if state == "speaking":
		if voice.playing:
			var frame := int(maxf(0,voice.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())/0.02)
			actors[active].opening = float(envelope[frame]) if frame<envelope.size() else 0
		else:
			finish_line()
	elif state == "laughing":
		if not laughter.playing:
			state = "gap"
	elif state == "gap" or state == "silent_line":
		remaining -= delta
		if remaining<=0:
			if state == "silent_line": finish_line()
			elif ready_to_speak:
				ready_to_speak = false
				start_line()
			else: next_line()
	elif state == "waiting" and not pending_scene.is_empty():
		begin_scene()
func _received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	fetching = false
	if code == 202:
		var progress = JSON.parse_string(body.get_string_from_utf8())
		if progress is Dictionary:
			var description := str(progress.get("status", "")) + " " + str(progress.get("error", ""))
			if description != server_progress:
				server_progress = description
				print("PENSAO_GENERATION time=", Time.get_datetime_string_from_system(), " progress=", description)
		if state == "waiting" and progress is Dictionary:
			status_label.text = str(progress.get("status","Preparando…"))
			if progress.get("error","") != "": status_label.text += " — " + str(progress.error).left(170)
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		print("PENSAO_HTTP_ERROR result=", result, " code=", code, " state=", state)
		if state == "waiting": status_label.text = "Servidor indisponível; tentando novamente…"
		return
	var payload = JSON.parse_string(body.get_string_from_utf8())
	if not payload is Dictionary or not payload.get("lines") is Array: return
	var validated: Array = []
	for line in payload.lines:
		if line is Dictionary and actors.has(str(line.get("speaker",""))) and line.get("text") is String:
			validated.append(line)
	if validated.is_empty(): return
	payload.lines = validated
	pending_scene = payload
	if state == "waiting": begin_scene()
func begin_scene() -> void:
	var gap_ms := Time.get_ticks_msec() - last_scene_end_ms if last_scene_end_ms > 0 else 0
	print("PENSAO_SCENE id=", pending_scene.get("scene_id", 0), " lines=", pending_scene.lines.size(), " wait_ms=", gap_ms)
	heading.text = "DEMO" if pending_scene.get("demo",false) else ""
	lines = pending_scene.lines
	var present: Array = pending_scene.get("present", actors.keys())
	for id in actors:
		actors[id].visible = id in present
	pending_scene = {}
	fetch_timer = 0
	line_index = -1
	scene_number += 1
	status_label.text = ""
	next_line()
func next_line() -> void:
	for actor in actors.values(): actor.talking = false
	line_index += 1
	if line_index>=lines.size():
		last_scene_end_ms = Time.get_ticks_msec()
		captions.text = ""
		state = "waiting"
		fetch_timer = 2.5
		cameras[0].current = true
		return
	var line: Dictionary = lines[line_index]
	if line.has("event"):
		var event: Dictionary = line.event
		staging_actor = actors[event.speaker]
		staging_actor.change_presence(event.action == "enter")
		entrance_pause = event.action == "enter"
		door_opened = false
		if event.action == "enter": open_door_sound()
		state = "transition"
		cameras[0].current = true
		shot_left = 0
		captions.text = ""
		end_entrance()
		if event.action == "enter": begin_entrance(staging_actor)
		return
	start_line()
func start_line() -> void:
	var line: Dictionary = lines[line_index]
	active = line.speaker
	actors[active].talking = true
	captions.text = "%s: %s" % [active.capitalize(),line.text]
	if entrance_left <= 0 and not line.get("continuation",false) and (line_index==0 or rng.randf()<0.4):
		camera_index = rng.randi_range(0,cameras.size()-1)
		cameras[camera_index].current = true
	if entrance_left <= 0 and not line.get("continuation",false) and rng.randf() < 0.65:
		shot_kind = rng.randi_range(0,2)
		shot_front = actors[active].global_transform.basis.z.normalized()
		shot_initializing = true
		shot_left = rng.randf_range(2,5)
		update_shot(0.0)
		special_camera.current = true
	var stream: AudioStreamWAV
	if line.get("wav") is String:
		stream = AudioStreamWAV.load_from_buffer(Marshalls.base64_to_raw(line.wav))
	if stream:
		print("PENSAO_VOICE scene=", scene_number, " line=", line_index, " actor=", active, " seconds=", stream.get_length())
		status_label.text = ""
		voice.stream = stream
		envelope = line.get("envelope",[])
		voice.play()
		if paused: voice.stream_paused = true
		state = "speaking"
	else:
		print("PENSAO_VOICE_MISSING scene=", scene_number, " line=", line_index, " actor=", active)
		status_label.text = "Voz indisponível para " + active.capitalize() + "; exibindo legenda."
		remaining = maxf(2, str(line.text).length()/13.0)
		state = "silent_line"
func should_laugh() -> bool:
	# Intentionally independent of text, speaker, topic, sentiment and punchlines.
	return rng.randf()<clampf(float(config.get("laugh_probability",0.3)),0,1)
func finish_line() -> void:
	actors[active].talking = false
	if lines[line_index].get("continues",false):
		remaining = 0.12
		state = "gap"
		return
	remaining = rng.randf_range(float(config.get("pause_min",0.5)),float(config.get("pause_max",1.7)))
	if rng.randf()<float(config.get("awkward_probability",0.13)):
		remaining += float(config.get("awkward_seconds",3.0))
	var selected := should_laugh()
	if selected and not laughs.is_empty():
		laughter.stream = laughs[rng.randi_range(0,laughs.size()-1)]
		laughter.pitch_scale = 1.0
		laughter.play()
		state = "laughing"
	else:
		state = "gap"
func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	match event.keycode:
		KEY_SPACE:
			paused = not paused
			voice.stream_paused = paused
			laughter.stream_paused = paused
			ambience.stream_paused = paused
			door_sound.stream_paused = paused
			entrance_jingle.stream_paused = paused
			for actor in actors.values(): actor.set_process(not paused)
			heading.text = "PAUSADO" if paused else ""
		KEY_C:
			end_entrance()
			camera_index = (camera_index+1)%cameras.size()
			cameras[camera_index].current = true
		KEY_V:
			vhs = not vhs
			screen.material.set_shader_parameter("enabled",vhs)
		KEY_H:
			help = not help
			help_label.visible = help
		KEY_F11:
			get_window().mode = Window.MODE_WINDOWED if get_window().mode==Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN

func begin_entrance(actor: Node3D) -> void:
	if entrance_jingle.stream:
		entrance_jingle.play()
		print("PENSAO_ENTRANCE_JINGLE actor=", actor.identity, " seconds=", entrance_jingle.stream.get_length())
	entrance_actor = actor
	entrance_left = ENTRANCE_SECONDS
	entrance_name.text = {"NAIR":"Dona Nair", "VALDIR":"Valdir", "JESSICA":"Jéssica", "MAURO":"Mauro"}.get(actor.identity, actor.identity)
	entrance_name.show()
	entrance_camera.position = actor.global_position + Vector3(-1.4,2.1,4.2)
	entrance_camera.look_at(actor.global_position + Vector3(0,1.2,0))
	entrance_camera.current = true
	update_entrance(0.0)

func end_entrance() -> void:
	entrance_left = 0
	entrance_name.hide()
	if entrance_camera.current: cameras[camera_index].current = true

func update_entrance(delta: float) -> void:
	entrance_left = maxf(0, entrance_left - delta)
	if entrance_left <= 0 or not is_instance_valid(entrance_actor) or not entrance_actor.visible:
		end_entrance()
		return
	var age := ENTRANCE_SECONDS - entrance_left
	var zoom := smoothstep(0.0, 2.2, age)
	entrance_camera.fov = lerpf(54.0, 47.0, zoom)
	var desired := entrance_actor.global_position + Vector3(-1.4,2.1,4.2)
	entrance_camera.position = entrance_camera.position.lerp(desired, 1.0-exp(-4.0*delta))
	entrance_camera.look_at(entrance_actor.global_position + Vector3(0,1.2,0))
	var arrival := clampf(age/0.45, 0.0, 1.0)
	entrance_name.position.x = lerpf(-310.0, 12.0, 1.0-pow(1.0-arrival, 3))
	entrance_name.scale = Vector2.ONE * (1.0 + sin(arrival*PI)*0.1)
	entrance_name.modulate.a = minf(1.0, entrance_left/0.4)

func update_shot(delta: float) -> void:
	if entrance_left > 0:
		update_entrance(delta)
		return
	if shot_left <= 0 or active == "": return
	shot_left -= delta
	if shot_left <= 0:
		cameras[camera_index].current = true
		return
	var actor: Node3D = actors[active]
	var face: Vector3 = actor.head.global_position
	# Lock the side of the shot at the cut: stepped actor turns must not orbit the camera.
	var desired: Vector3
	if shot_kind == 0:
		desired = face + shot_front*0.95 + Vector3(0,-0.05,0)
		special_camera.fov = 42
	elif shot_kind == 1:
		desired = actor.global_position + shot_front*1.4 + Vector3(0,0.25,0)
		special_camera.fov = 68
	else:
		desired = Vector3(1.6,1.35,-3.5)
		special_camera.fov = 75
	var weight := 1.0 if shot_initializing else 1.0 - exp(-5.0 * delta)
	special_camera.position = special_camera.position.lerp(desired, weight)
	shot_focus = shot_focus.lerp(face, weight)
	shot_initializing = false
	special_camera.look_at(shot_focus)
	special_camera.rotation.z = -0.12 if shot_kind == 1 else 0.04

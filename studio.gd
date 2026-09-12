extends Node3D

var overlay: Node2D
var globe: Node3D
var elapsed := 0.0
var capturing := false

func material(color: String, metal := 0.0, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.metallic = metal
	m.roughness = 0.38
	if glow > 0:
		m.emission_enabled = true
		m.emission = Color(color)
		m.emission_energy_multiplier = glow
	return m

func box(at: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.material_override = mat
	item.position = at
	add_child(item)
	return item

func cylinder(at: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 64
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.position = at
	item.material_override = mat
	add_child(item)
	return item

func wall_text(words: String, at: Vector3, font_size: int, pixel_size: float, tint: Color) -> void:
	var label := Label3D.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial", "Liberation Sans"])
	font.font_weight = 700
	label.font = font
	label.text = words
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = tint
	label.outline_size = 8
	label.outline_modulate = Color("#07142c")
	label.position = at
	add_child(label)

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("#06142c")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("#87a9ce")
	settings.ambient_light_energy = 0.55
	environment.environment = settings
	add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.95, 9.1)
	camera.fov = 49
	add_child(camera)
	camera.look_at(Vector3(0, 1.75, -1.0))
	camera.current = true
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_color = Color("#ffecd1")
	key.light_energy = 1.15
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-3, 3, 1)
	fill.light_color = Color("#4a92ff")
	fill.light_energy = 2.0
	fill.omni_range = 9
	add_child(fill)
	var blue := material("#163f75", 0.25)
	var dark := material("#0a1f3d", 0.15)
	var gold := material("#b9a16a", 0.55)
	var silver := material("#829bb0", 0.65)
	var light_strip := material("#83b9ee", 0, 1.2)
	box(Vector3(0, -0.13, 0), Vector3(20, 0.2, 18), material("#182c49", 0.35))
	box(Vector3(0, 2.6, -3.5), Vector3(12, 5.4, 0.2), dark)
	# Three wall panels and metal mullions form the physical studio backdrop.
	for x in [-3.9, 0.0, 3.9]:
		box(Vector3(x, 2.5, -3.32), Vector3(3.7, 4.5, 0.15), blue)
	for x in [-5.85, -1.95, 1.95, 5.85]:
		box(Vector3(x, 2.5, -3.13), Vector3(0.07, 4.65, 0.10), silver)
	for y in [0.35, 0.46, 4.45, 4.55]:
		box(Vector3(0, y, -3.09), Vector3(11.8, 0.035, 0.10), gold)
	for x in [-6.0, 6.0]:
		var wing := box(Vector3(x, 2, -1.8), Vector3(2.4, 4.3, 0.2), dark)
		wing.rotation_degrees.y = 30 if x < 0 else -30
	# Wall emblem: a slowly rotating wire globe, deliberately simple broadcast geometry.
	globe = Node3D.new()
	globe.position = Vector3(-2.75, 2.95, -2.98)
	add_child(globe)
	var lines := ImmediateMesh.new()
	var wire := StandardMaterial3D.new()
	wire.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wire.albedo_color = Color("#809cc3")
	lines.surface_begin(Mesh.PRIMITIVE_LINES, wire)
	for latitude in range(-60, 61, 20):
		var a := deg_to_rad(float(latitude))
		for i in range(72):
			for j in [i, i + 1]:
				var b: float = j * TAU / 72
				lines.surface_add_vertex(Vector3(cos(a) * cos(b), sin(a), cos(a) * sin(b)) * 1.02)
	for longitude in range(0, 180, 20):
		var b := deg_to_rad(float(longitude))
		for i in range(72):
			for j in [i, i + 1]:
				var a: float = j * TAU / 72
				lines.surface_add_vertex(Vector3(cos(a) * cos(b), sin(a), cos(a) * sin(b)) * 1.02)
	lines.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = lines
	globe.add_child(grid)
	wall_text("JORNAL", Vector3(1.7, 3.53, -3.05), 65, 0.009, Color("#e0d4b7"))
	wall_text("AURORA", Vector3(1.7, 2.92, -3.03), 86, 0.009, Color("#f1e9d5"))
	wall_text("E D I Ç Ã O   R E G I O N A L", Vector3(1.7, 2.42, -3.01), 22, 0.009, Color("#a8c3df"))
	# Empty anchor position, platform and broad curved desk.
	cylinder(Vector3(0, 0.01, 0), 3.55, 0.12, silver).scale.z = 0.64
	cylinder(Vector3(0, 0.08, 0), 3.47, 0.12, dark).scale.z = 0.64
	box(Vector3(0, 0.99, -0.23), Vector3(1.0, 1.0, 0.19), dark)
	cylinder(Vector3(0, 0.68, 0.35), 2.39, 1.04, blue).scale.z = 0.43
	cylinder(Vector3(0, 1.21, 0.35), 2.57, 0.12, gold).scale.z = 0.45
	cylinder(Vector3(0, 1.30, 0.35), 2.62, 0.10, material("#172838", 0.45)).scale.z = 0.45
	cylinder(Vector3(0, 0.27, 0.35), 2.40, 0.035, light_strip).scale.z = 0.432
	box(Vector3(-0.4, 1.358, 0.32), Vector3(0.36, 0.008, 0.25), material("#dad6be"))
	# Two discreet desk-front trim lines.
	box(Vector3(0, 0.82, 1.383), Vector3(1.8, 0.025, 0.02), gold)
	box(Vector3(0, 0.74, 1.383), Vector3(1.8, 0.013, 0.02), silver)
	var canvas := CanvasLayer.new()
	var presenter := Node3D.new()
	presenter.name = "Augusto"
	presenter.set_script(load("res://presenter.gd"))
	presenter.position = Vector3(-0.8, 1.32, -0.40)
	presenter.scale = Vector3.ONE * 1.3
	add_child(presenter)
	add_child(canvas)
	overlay = Node2D.new()
	overlay.set_script(load("res://news_overlay.gd"))
	canvas.add_child(overlay)
	if "--preview-reporter" in OS.get_cmdline_user_args():
		overlay.preview_reporter(0)
	if "--capture-weather" in OS.get_cmdline_user_args():
		overlay.weather_panel.set_story(preload("res://weather_segment.gd").create())
	if "--capture-transition" in OS.get_cmdline_user_args():
		overlay.ident.begin()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--news-index="):
			overlay.index = clampi(int(arg.trim_prefix("--news-index=")), 0, overlay.items.size() - 1)

func _process(delta: float) -> void:
	elapsed += delta
	if "--test-feed" in OS.get_cmdline_user_args():
		if overlay.received_first and not capturing:
			capturing = true
			overlay.automatic = false
			var waiting_since := Time.get_ticks_msec()
			while overlay.pending_index >= 0 or overlay.pre_read >= 0:
				if Narration.player.playing:
					push_error("VOICE_STARTED_DURING_TRANSITION_OR_PAUSE")
					get_tree().quit(1)
					return
				await get_tree().process_frame
			var waited := (Time.get_ticks_msec() - waiting_since) / 1000.0
			if "--test-pause" in OS.get_cmdline_user_args() and waited < 4.8:
				push_error("AWKWARD_PAUSE_TOO_SHORT")
				get_tree().quit(1)
				return
			if overlay.audio.stream == null or overlay.ident.sting.stream == null:
				push_error("BROADCAST_MUSIC_MISSING")
				get_tree().quit(1)
				return
			print("TRANSITION_AND_PAUSE_OK seconds=", waited)
			if "--test-weather" in OS.get_cmdline_user_args():
				if not overlay.weather_panel.visible or overlay.items[overlay.index].get("voice") != "thalita":
					push_error("WEATHER_VOICE_OR_PANEL_FAILED")
					get_tree().quit(1)
					return
				print("WEATHER_PANEL_AND_THALITA_OK")
			if not Narration.player.playing:
				push_error("VOICE_NOT_PLAYING")
				get_tree().quit(1)
				return
			var maximum_open := 0.0
			while Narration.player.playing:
				maximum_open = maxf(maximum_open, Narration.mouth_open)
				await get_tree().process_frame
			await get_tree().create_timer(0.3).timeout
			if maximum_open < 0.1 or Narration.mouth_open > 0.01:
				push_error("VOICE_MOUTH_FAILED")
				get_tree().quit(1)
				return
			print("VOICE_PLAYBACK_OK peak_mouth=", maximum_open, " resting_mouth=", Narration.mouth_open)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://preview-news-live.png")
			get_tree().quit()
		elif elapsed > 150:
			push_error("NEWS_FEED_TIMEOUT")
			get_tree().quit(1)
	if is_instance_valid(globe):
		globe.rotation.y = elapsed * 0.015
	var capture_at := 0.8 if "--capture-transition" in OS.get_cmdline_user_args() else 1.5
	if "--capture-news" in OS.get_cmdline_user_args() and elapsed > capture_at and not capturing:
		capturing = true
		await RenderingServer.frame_post_draw
		var capture_path := "res://preview-transition.png" if "--capture-transition" in OS.get_cmdline_user_args() else "res://preview-news-%d.png" % overlay.index
		if "--capture-weather" in OS.get_cmdline_user_args():
			capture_path = "res://preview-weather.png"
		get_viewport().get_texture().get_image().save_png(capture_path)
		get_tree().quit()

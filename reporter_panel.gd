extends Node2D
## Independent 3D exterior, drawn beneath the existing broadcast graphics.
var viewport: SubViewport
var scenery: Node3D
var host: Node3D
var location := 0
var world: Environment
var sunlight: DirectionalLight3D

func material(color: String, glow := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = Color(color)
	result.roughness = 0.95
	if glow:
		result.emission_enabled = true
		result.emission = Color(color)
	return result

var batches: Dictionary = {}
var rng := RandomNumberGenerator.new()

func box(at: Vector3, size: Vector3, color: String, glow := false) -> void:
	var key := color + ("_lit" if glow else "")
	if not batches.has(key):
		batches[key] = {"material": material(color, glow), "transforms": []}
	batches[key].transforms.append(Transform3D(Basis.IDENTITY.scaled(size), at))

func flush_boxes() -> void:
	# Thousands of distant windows share a handful of draw calls.
	for batch in batches.values():
		var mesh := BoxMesh.new()
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = mesh
		instances.instance_count = batch.transforms.size()
		for i in range(instances.instance_count):
			instances.set_instance_transform(i, batch.transforms[i])
		var item := MultiMeshInstance3D.new()
		item.multimesh = instances
		item.material_override = batch.material
		scenery.add_child(item)
	batches.clear()

func rock(at: Vector3, size: Vector3, color: String) -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 7
	mesh.rings = 3
	mesh.radius = 1
	mesh.height = 2
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.position = at
	item.scale = size
	item.material_override = material(color)
	scenery.add_child(item)

func tree_at(x: float, z: float, scale_factor := 1.0) -> void:
	box(Vector3(x, scale_factor, z), Vector3(0.23, 2, 0.23) * scale_factor, "#685241")
	for offset in [Vector3(-0.55, 2.25, 0), Vector3(0.5, 2.5, 0.25), Vector3(0, 3.0, -0.2)]:
		rock(Vector3(x, 0, z) + offset * scale_factor, Vector3(0.95, 1.0, 0.85) * scale_factor, "#436b46")

func ridge(z: float, base: float, height: float, width: float, color: String, seed_value: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tops: Array[Vector3] = []
	for i in range(25):
		tops.append(Vector3(-width / 2 + width * i / 24, base + height * random.randf_range(0.4, 1.0), z))
	for i in range(24):
		for vertex in [Vector3(tops[i].x, base - 50, z), tops[i + 1], tops[i], Vector3(tops[i].x, base - 50, z), Vector3(tops[i + 1].x, base - 50, z), tops[i + 1]]:
			mesh.add_vertex(vertex)
	mesh.generate_normals()
	var item := MeshInstance3D.new()
	item.mesh = mesh.commit()
	var tint := material(color)
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	item.material_override = tint
	scenery.add_child(item)

func sign_text(words: String, at: Vector3, scale_factor: float, color := "#f0e3b7") -> void:
	var label := Label3D.new()
	label.text = words
	label.font_size = 36
	label.pixel_size = scale_factor
	label.position = at
	label.modulate = Color(color)
	label.outline_size = 2
	scenery.add_child(label)

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 600)
	viewport.own_world_3d = true
	add_child(viewport)
	var environment := WorldEnvironment.new()
	world = Environment.new()
	world.background_mode = Environment.BG_COLOR
	world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment = world
	viewport.add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.8, 10)
	camera.fov = 49
	camera.far = 700
	viewport.add_child(camera)
	camera.look_at(Vector3(0, 0.65, 0))
	camera.current = true
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-35, -30, 0)
	viewport.add_child(sunlight)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1, 3, 3)
	fill.light_color = Color("#ffe3c5")
	fill.light_energy = 1.5
	fill.omni_range = 7
	viewport.add_child(fill)
	host = Node3D.new()
	host.set_script(load("res://reporter.gd"))
	host.position = Vector3(-0.65, 1.67, 0)
	host.scale = Vector3.ONE * 1.15
	viewport.add_child(host)
	var picture := TextureRect.new()
	picture.texture = viewport.get_texture()
	picture.size = Vector2(800, 600)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	build_location()
	set_story({})

func set_story(story: Dictionary) -> void:
	visible = story.get("kind", "") == "reporter"
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	host.set_process(visible)
	if visible:
		location = clampi(int(story.get("location", 0)), 0, 2)
		build_location()

func cycle_location() -> void:
	location = (location + 1) % 3
	build_location()

func build_location() -> void:
	if is_instance_valid(scenery):
		viewport.remove_child(scenery)
		scenery.queue_free()
	scenery = Node3D.new()
	viewport.add_child(scenery)
	batches.clear()
	rng.seed = 1993 + location
	var night := location == 2
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#080e27" if night else "#568eb2")
	sky_material.sky_horizon_color = Color("#414767" if night else "#d5d9c4")
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = Color("#17252b" if night else "#6b8061")
	sky_material.sun_angle_max = 0
	var sky := Sky.new()
	sky.sky_material = sky_material
	world.sky = sky
	world.background_mode = Environment.BG_SKY
	world.ambient_light_color = Color("#9ba8cd" if night else "#e1e3d2")
	world.ambient_light_energy = 0.48 if night else 0.72
	sunlight.light_color = Color("#8198c5" if night else "#ffe0ad")
	sunlight.light_energy = 0.22 if night else 0.95
	match location:
		0: build_street()
		1: build_field()
		2: build_hilltop()
	flush_boxes()

func build_street() -> void:
	# Sidewalk occupies the foreground; the avenue recedes diagonally beside it.
	box(Vector3(0, -0.28, -100), Vector3(300, 0.3, 280), "#898b7e")
	box(Vector3(7.6, -0.13, -76), Vector3(7, 0.10, 180), "#454c50")
	box(Vector3(3.95, -0.02, -70), Vector3(0.24, 0.26, 165), "#d1cbb8")
	for row in range(30):
		for column in range(8):
			box(Vector3(-3.6 + column, -0.015, 4.0 - row), Vector3(0.975, 0.03, 0.975), "#bab6a5" if (column + row) % 3 else "#aaa997")
	# Drain, tactile paving, seams and a utility cover are only modeled nearby.
	for row in range(20):
		box(Vector3(2.7, 0.018, 3.0 - row * 0.7), Vector3(0.4, 0.02, 0.64), "#d2af54")
	for i in range(9):
		box(Vector3(3.7, 0.015, -1.5 - i * 0.07), Vector3(0.32, 0.025, 0.035), "#3e4545")
	box(Vector3(1.3, 0.01, -2.1), Vector3(0.65, 0.04, 0.9), "#777d75")
	for z in range(0, -160, -6):
		box(Vector3(7.5, -0.065, z), Vector3(0.1, 0.015, 2.8), "#dbc27f")
	for i in range(7):
		box(Vector3(7.5, -0.06, -9.0 - i * 0.65), Vector3(6, 0.02, 0.3), "#c9c6b4")
	# Shopfronts opposite the avenue and a near corner storefront.
	for i in range(12):
		var z := -12.0 - i * 10
		var height := rng.randf_range(3.8, 8)
		box(Vector3(14, height / 2 - 0.1, z), Vector3(5, height, 8.8), ["#af9b80", "#7d9990", "#b79b8d"][i % 3])
		for level in range(1, int(height)):
			box(Vector3(11.45, level, z + 2), Vector3(0.025, 0.65, 1.25), "#45616b")
	box(Vector3(-4.8, 2.15, -8), Vector3(4.6, 4.3, 3), "#d0b590")
	box(Vector3(-4.8, 1.5, -6.46), Vector3(3.6, 2.5, 0.06), "#46656a")
	for x in [-6.5, -5.35, -4.2, -3.1]:
		box(Vector3(x, 1.5, -6.4), Vector3(0.065, 2.5, 0.06), "#c5cab7")
	box(Vector3(-4.8, 3.05, -6.15), Vector3(4.4, 0.55, 0.35), "#447363")
	sign_text("PADARIA CEDRO", Vector3(-4.8, 3.06, -5.94), 0.006)
	for i in range(8):
		var z := -5.0 - i * 17
		box(Vector3(3.35, 2.5, z), Vector3(0.16, 5, 0.16), "#757a73")
		box(Vector3(4.0, 4.9, z), Vector3(1.45, 0.07, 0.08), "#626d70")
		box(Vector3(4.65, 4.83, z), Vector3(0.5, 0.14, 0.3), "#c9cbbb")
		if i < 4:
			tree_at(-2.8, z - 11, 1.1)
	# Parked compact car, curbside bin and bus-stop sign.
	box(Vector3(10, 0.48, -16), Vector3(1.7, 0.8, 3.6), "#a3b6b3")
	box(Vector3(10, 1.0, -16.3), Vector3(1.5, 0.65, 1.7), "#52717b")
	for x in [9.1, 10.9]:
		for z in [-17.1, -14.9]:
			rock(Vector3(x, 0.22, z), Vector3(0.14, 0.3, 0.3), "#282f32")
	box(Vector3(2.9, 0.6, -4.8), Vector3(0.5, 0.9, 0.45), "#39655c")
	box(Vector3(3.2, 1.65, -8), Vector3(0.08, 3.3, 0.08), "#667272")
	box(Vector3(3.2, 2.9, -7.9), Vector3(0.72, 0.65, 0.07), "#386588")
	sign_text("ÔNIBUS", Vector3(3.2, 2.92, -7.84), 0.003)
	ridge(-250, 0, 38, 420, "#879d9a", 10)

func build_field() -> void:
	box(Vector3(0, -0.16, -95), Vector3(360, 0.3, 230), "#71915a")
	ridge(-370, 0, 50, 650, "#a3b7ad", 22)
	ridge(-245, -3, 30, 440, "#819d89", 28)
	ridge(-150, -5, 19, 270, "#628368", 26)
	for i in range(46):
		var z := 5.0 - i * 3
		var x := 2.6 + sin(i * 0.09) * 7
		box(Vector3(x, 0.004, z), Vector3(2.6, 0.025, 3.1), "#b3a077")
		box(Vector3(x + 2.6, 0.65, z), Vector3(0.12, 1.3, 0.12), "#948773")
		for y in [0.4, 0.8, 1.15]:
			box(Vector3(x + 2.6, y, z - 1.5), Vector3(0.025, 0.025, 3.1), "#bcb69a")
	for i in range(24):
		tree_at(rng.randf_range(-65, -12), rng.randf_range(-110, -18), rng.randf_range(0.7, 1.5))
	tree_at(-4.8, -4, 1.35)
	box(Vector3(18, 2.2, -68), Vector3(10, 4.4, 6), "#b39375")
	box(Vector3(18, 4.5, -68), Vector3(11, 0.55, 7), "#9b624a")
	box(Vector3(18, 1.4, -64.95), Vector3(1.6, 2.8, 0.08), "#514e40")
	for i in range(130):
		var x := rng.randf_range(-8, 8)
		var z := rng.randf_range(-12, 5)
		if absf(x + 0.65) < 0.7 or (x > 1.2 and x < 5):
			continue
		box(Vector3(x, 0.12, z), Vector3(0.035, rng.randf_range(0.12, 0.3), 0.025), "#527340")
		if i % 6 == 0:
			rock(Vector3(x, 0.23, z), Vector3(0.045, 0.035, 0.045), "#e4d396")

func build_hilltop() -> void:
	# A short plateau ends behind the reporter. The valley is genuinely far below.
	box(Vector3(0, -0.3, 4), Vector3(32, 0.6, 14), "#414d40")
	box(Vector3(0, -18, -160), Vector3(550, 0.4, 330), "#1c2d3c")
	ridge(-480, -8, 65, 850, "#39435f", 55)
	ridge(-360, -15, 47, 650, "#2c3853", 61)
	ridge(-270, -18, 33, 490, "#243249", 73)
	# Low-density outskirts behind the closer city core, with sparse lit windows.
	for i in range(150):
		var x := rng.randf_range(-130, 130)
		var z := rng.randf_range(-245, -75)
		var base := -17.0
		var height := rng.randf_range(2.0, 16.0) if i % 4 else rng.randf_range(18, 32)
		var width := rng.randf_range(2.0, 5.0)
		box(Vector3(x, base + height / 2, z), Vector3(width, height, width), "#26374a" if z < -160 else "#1b2a3d")
		for floor_index in range(int(height / 1.7)):
			for column in range(3):
				if rng.randf() < 0.43:
					box(Vector3(x - width * 0.3 + column * width * 0.3, base + 1 + floor_index * 1.7, z + width / 2 + 0.02), Vector3(0.32, 0.45, 0.035), "#dbb572" if rng.randf() < 0.8 else "#a8c6d0", true)
	# Lines of tiny street lights reveal the scale and shape of the valley.
	for row in range(9):
		for i in range(65):
			var x := -130.0 + i * 4
			var z := -85.0 - row * 17 + sin(i * 0.12) * 8
			box(Vector3(x, -16.3, z), Vector3(0.25, 0.25, 0.25), "#e6ae64", true)
	# Foreground texture: stones, weeds and rough wooden posts at the overlook.
	for i in range(22):
		var x := rng.randf_range(-12, 12)
		var z := rng.randf_range(-2.6, 4)
		if absf(x + 0.65) > 1:
			rock(Vector3(x, 0.06, z), Vector3(rng.randf_range(0.1, 0.5), 0.13, 0.3), "#66685a")
	for x in [-7.0, -4.0, 3.8, 6.8]:
		box(Vector3(x, 0.55, -2.8), Vector3(0.17, 1.1, 0.17), "#726e60")
		for y in [0.4, 0.85]:
			box(Vector3(x + 1.5, y, -2.8), Vector3(3, 0.055, 0.06), "#898477")
	for i in range(100):
		var x := rng.randf_range(-13, 13)
		var z := rng.randf_range(-2.6, 4)
		if absf(x + 0.65) > 1.1:
			box(Vector3(x, 0.14, z), Vector3(0.025, rng.randf_range(0.15, 0.35), 0.04), "#67704e")
	# A distant moon and faint stars, far beyond the mountains.
	rock(Vector3(110, 140, -550), Vector3(8, 8, 2), "#c5cbd6")
	for i in range(80):
		box(Vector3(rng.randf_range(-320, 320), rng.randf_range(70, 230), -570), Vector3(0.26, 0.26, 0.1), "#919eb7", true)

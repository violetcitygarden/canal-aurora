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

func box(at: Vector3, size: Vector3, color: String, glow := false) -> void:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = material(color, glow)
	item.position = at
	scenery.add_child(item)

func tree_at(x: float, z: float) -> void:
	box(Vector3(x, 1, z), Vector3(0.26, 2, 0.26), "#70583d")
	var crown := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.2
	mesh.height = 2.5
	mesh.radial_segments = 7
	mesh.rings = 4
	crown.mesh = mesh
	crown.material_override = material("#39764a")
	crown.position = Vector3(x, 2.6, z)
	scenery.add_child(crown)

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
	camera.position = Vector3(0, 2.5, 7)
	camera.fov = 46
	viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.7, 0))
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
	host.set_script(load("res://presenter.gd"))
	host.reporter_host = true
	host.position = Vector3(-0.65, 1.1, 0)
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
	var night := location == 2
	world.background_color = Color("#101b38" if night else "#91b9ca")
	world.ambient_light_color = Color("#8a9abd" if night else "#d0e1e2")
	world.ambient_light_energy = 0.38 if night else 0.65
	sunlight.light_energy = 0.3 if night else 1.0
	box(Vector3(0, -0.1, -8), Vector3(70, 0.2, 65), "#254336" if night else ("#6b9750" if location == 1 else "#969588"))
	if location == 1:
		# Winding farm track, fence and clustered low-poly trees.
		for i in range(10):
			box(Vector3(2.7 + i * 0.32, 0.015, -i * 2.5), Vector3(2.0, 0.025, 2.6), "#b5a278")
			box(Vector3(5.5, 0.55, -i * 2.0), Vector3(0.12, 1.1, 0.12), "#dfd0a3")
		box(Vector3(5.5, 0.75, -9), Vector3(0.1, 0.1, 20), "#dfd0a3")
		for i in range(9):
			tree_at(-5.0 - (i % 3) * 2.0, -5.0 - i * 2.5)
		box(Vector3(5, 1, -22), Vector3(4, 2, 3), "#a75c47")
		box(Vector3(5, 2.15, -22), Vector3(4.4, 0.3, 3.4), "#54473b")
	else:
		box(Vector3(0, 0.02, -6), Vector3(60, 0.04, 5), "#343e48")
		for i in range(-7, 8):
			box(Vector3(i * 4, 0.05, -6), Vector3(1.7, 0.02, 0.1), "#d2c393")
			var height := 2.5 + posmod(i * 7, 6)
			var z := -16.0 if night else -11.0
			box(Vector3(i * 3.3, height / 2, z), Vector3(3, height, 3), "#26344b" if night else ["#b29477", "#7c9690", "#d0bc96"][posmod(i, 3)])
			for row in range(int(height)):
				for column in range(3):
					box(Vector3(i * 3.3 - 0.9 + column * 0.9, 0.7 + row, z + 1.52), Vector3(0.4, 0.55, 0.03), "#e6bd72" if night else "#405d6c", night)
		for x in [-4.0, 4.0]:
			box(Vector3(x, 1.8, -3), Vector3(0.1, 3.6, 0.1), "#414b50")
			box(Vector3(x, 3.65, -3), Vector3(0.5, 0.16, 0.4), "#ffe1a1", true)
		if night:
			box(Vector3(0, 0.7, -2), Vector3(18, 0.12, 0.12), "#596573")
			for x in range(-8, 9, 2):
				box(Vector3(x, 0.35, -2), Vector3(0.08, 0.7, 0.08), "#596573")
		else:
			tree_at(6, -3)
			tree_at(-6, -3)

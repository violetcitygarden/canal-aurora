extends Node2D

var story: Dictionary = {}
var font := SystemFont.new()
var portrait: SubViewport
var host: Node3D
const POSITIONS := [Vector2(173, 188), Vector2(392, 216), Vector2(238, 327), Vector2(422, 409)]
const REGIONS := [
	[Vector2(77,147),Vector2(142,114),Vector2(244,138),Vector2(295,190),Vector2(269,267),Vector2(155,266),Vector2(93,222)],
	[Vector2(244,138),Vector2(337,126),Vector2(391,153),Vector2(476,148),Vector2(511,229),Vector2(451,283),Vector2(351,273),Vector2(269,267),Vector2(295,190)],
	[Vector2(93,222),Vector2(155,266),Vector2(269,267),Vector2(351,273),Vector2(324,360),Vector2(299,443),Vector2(222,464),Vector2(149,416),Vector2(110,334)],
	[Vector2(351,273),Vector2(451,283),Vector2(496,324),Vector2(529,381),Vector2(491,452),Vector2(413,468),Vector2(365,447),Vector2(299,443),Vector2(324,360)]
]

func _ready() -> void:
	font.font_names = PackedStringArray(["Arial"])
	font.font_weight = 700
	portrait = SubViewport.new()
	portrait.size = Vector2i(310, 430)
	portrait.transparent_bg = true
	portrait.own_world_3d = true
	portrait.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(portrait)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.45
	camera.position = Vector3(0, 0.10, 6)
	portrait.add_child(camera)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-25, -25, 0)
	light.light_energy = 1.3
	portrait.add_child(light)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#d0dbed")
	world.environment.ambient_light_energy = 0.65
	portrait.add_child(world)
	host = Node3D.new()
	host.set_script(load("res://presenter.gd"))
	host.weather_host = true
	portrait.add_child(host)
	var image := TextureRect.new()
	image.texture = portrait.get_texture()
	image.position = Vector2(496, 95)
	image.size = Vector2(310, 430)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	set_story({})

func set_story(value: Dictionary) -> void:
	story = value
	visible = story.get("kind", "") == "weather"
	portrait.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	host.set_process(visible)
	queue_redraw()

func text(words: String, at: Vector2, size: int, tint := Color("#f5efd7")) -> void:
	if tint.get_luminance() > 0.3:
		draw_string(font, at + Vector2(2, 2), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color("#10202b"))
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func icon(at: Vector2, condition: int) -> void:
	if condition == 0:
		for i in range(8):
			var direction := Vector2.from_angle(i * TAU / 8)
			draw_line(at + direction * 16, at + direction * 22, Color("#e9bd59"), 3, true)
		draw_circle(at, 13, Color("#ffd66d"))
	var cloud := at + Vector2(12, 9)
	for offset in [Vector2(-15, 0), Vector2(-4,-7), Vector2(8,-3), Vector2(18,2)]:
		draw_circle(cloud + offset + Vector2(2,3), 10, Color("#365466"))
		draw_circle(cloud + offset, 10, Color("#e4ecea"))
	if condition == 2:
		for i in range(4):
			draw_line(cloud + Vector2(-13 + i * 10, 14), cloud + Vector2(-18 + i * 10, 25), Color("#a7dcff"), 3, true)

func _draw() -> void:
	if story.is_empty():
		return
	for y in range(600):
		draw_rect(Rect2(0, y, 800, 1), Color("#061b39").lerp(Color("#255b90"), sin(y / 600.0 * PI)))
	for x in range(35, 800, 35):
		draw_line(Vector2(x, 100), Vector2(x, 494), Color(0.5,0.7,0.9,0.07))
	for y in range(110, 490, 35):
		draw_line(Vector2(35, y), Vector2(770, y), Color(0.5,0.7,0.9,0.07))
	draw_rect(Rect2(30, 27, 740, 57), Color("#122c50"))
	draw_rect(Rect2(30, 27, 8, 57), Color("#dac287"))
	text("TEMPO LOCAL", Vector2(51, 64), 32)
	text("SANTA IRENE", Vector2(526, 54), 22, Color("#ead296"))
	text("VALE DO CEDRO  •  PRÓXIMAS 24H", Vector2(526, 74), 11)
	var colors := [Color("#598b60"),Color("#719a62"),Color("#608758"),Color("#82a071")]
	for i in range(REGIONS.size()):
		var polygon := PackedVector2Array(REGIONS[i])
		draw_colored_polygon(polygon, colors[i])
		polygon.append(polygon[0])
		draw_polyline(polygon, Color("#b5c39b"), 2, true)
	# Same geography every bulletin: the Cedro river crosses the municipal districts.
	draw_polyline(PackedVector2Array([Vector2(284,146),Vector2(313,204),Vector2(297,249),Vector2(320,285),Vector2(309,333),Vector2(343,374),Vector2(352,431),Vector2(401,463)]), Color("#234f75"), 9, true)
	draw_polyline(PackedVector2Array([Vector2(284,146),Vector2(313,204),Vector2(297,249),Vector2(320,285),Vector2(309,333),Vector2(343,374),Vector2(352,431),Vector2(401,463)]), Color("#83c0cb"), 3, true)
	text("N", Vector2(53, 113), 13, Color("#c5d3d9"))
	draw_line(Vector2(58,119), Vector2(58,147), Color("#c5d3d9"), 2)
	for i in range(story.get("districts", []).size()):
		var district: Dictionary = story.districts[i]
		var at: Vector2 = POSITIONS[i]
		icon(at - Vector2(24, 6), int(district.condition))
		draw_rect(Rect2(at + Vector2(16,-24), Vector2(56,32)), Color("#eee2b7"))
		text("%d°" % district.temperature, at + Vector2(23, 1), 25, Color("#182e37"))
		var width := font.get_string_size(str(district.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		text(str(district.name), at + Vector2(-width / 2, 47), 17)
	text("HELENA DUARTE", Vector2(577, 506), 17, Color("#ead296"))
	draw_rect(Rect2(30, 526, 740, 47), Color("#102c51"))
	draw_line(Vector2(30,526),Vector2(770,526),Color("#d6bd83"),2)
	text("AMANHÃ", Vector2(47, 556), 19)
	text("MÍN %d°    MÁX %d°" % [story.get("low", 0), story.get("high", 0)], Vector2(187, 557), 25)
	text("CANAL AURORA", Vector2(593, 555), 16, Color("#d6bd83"))
	for y in range(0,600,3):
		draw_line(Vector2(0,y),Vector2(800,y),Color(0,0,0,0.035))

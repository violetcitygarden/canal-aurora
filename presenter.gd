extends Node3D
## Shared low-poly host geometry and narration-driven idle/lip animation.
var weather_host := false
var reporter_host := false
var head: Node3D
var torso: Node3D
var eyes: Array[Node3D] = []
var pupils: Array[Node3D] = []
var right_hand: Node3D
var time := 0.0
var last_tick := -1
var mouth: Node3D
var jaw: Node3D

func mat(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.92
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func shape(parent: Node3D, at: Vector3, size: Vector3, material: Material, sides := 10) -> MeshInstance3D:
	# Triangles have separate vertices/normals for visible flat facets.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 7
	for r in range(rings):
		var a := -PI / 2 + PI * r / rings
		var b := -PI / 2 + PI * (r + 1) / rings
		for s in range(sides):
			var c := TAU * s / sides
			var d := TAU * (s + 1) / sides
			var p := Vector3(cos(a) * cos(c), sin(a), cos(a) * sin(c)) * size
			var q := Vector3(cos(b) * cos(c), sin(b), cos(b) * sin(c)) * size
			var u := Vector3(cos(b) * cos(d), sin(b), cos(b) * sin(d)) * size
			var v := Vector3(cos(a) * cos(d), sin(a), cos(a) * sin(d)) * size
			for vertex in [p, u, q, p, v, u]:
				surface.set_smooth_group(-1)
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func block(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	item.mesh = mesh
	item.material_override = material
	item.position = at
	parent.add_child(item)
	return item

func patch(parent: Node3D, points: Array, material: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, points.size() - 1):
		for vertex in [points[0], points[i], points[i + 1]]:
			st.add_vertex(vertex)
	st.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = material
	parent.add_child(node)

func limb(a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var node := shape(torso, (a + b) / 2, Vector3(radius, a.distance_to(b) / 2 + 0.07, radius), material, 8)
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())

func _ready() -> void:
	var skin := mat("#dcaa83")
	var cheek := mat("#ce9475")
	var hair := mat("#6b3827" if weather_host else "#3e302c")
	var gray := mat("#a89885")
	var suit := mat("#328b91" if weather_host else "#747973")
	if reporter_host:
		suit = mat("#294d64")
	var lapel := mat("#73bab2" if weather_host else "#9a9e8d")
	var shirt := mat("#e5d8b7")
	var tie := mat("#864742")
	torso = Node3D.new()
	add_child(torso)
	shape(torso, Vector3(0, 0.25, 0), Vector3(0.63, 0.56, 0.28), suit)
	shape(torso, Vector3(0, 0.70, 0), Vector3(0.16, 0.22, 0.15), skin, 8)
	patch(torso, [Vector3(-0.23,0.66,0.23),Vector3(0.23,0.66,0.23),Vector3(0.13,0.02,0.29),Vector3(-0.13,0.02,0.29)], shirt)
	patch(torso, [Vector3(-0.28,0.65,0.24),Vector3(-0.48,0.47,0.24),Vector3(-0.26,0.38,0.31),Vector3(-0.34,0.30,0.31),Vector3(-0.04,-0.05,0.32)], lapel)
	patch(torso, [Vector3(0.28,0.65,0.24),Vector3(0.48,0.47,0.24),Vector3(0.26,0.38,0.31),Vector3(0.34,0.30,0.31),Vector3(0.04,-0.05,0.32)], lapel)
	if not weather_host:
		shape(torso, Vector3(0,0.49,0.29), Vector3(0.075,0.085,0.035), tie, 5)
		patch(torso, [Vector3(-0.045,0.46,0.31),Vector3(0.045,0.46,0.31),Vector3(0.07,0.04,0.32),Vector3(0,-0.04,0.32),Vector3(-0.07,0.04,0.32)], tie)
	else:
		shape(torso, Vector3(0, -0.42, 0), Vector3(0.47, 0.53, 0.25), suit, 8)
		for side in [-1, 1]:
			shape(torso, Vector3(side * 0.19, -1.01, 0), Vector3(0.105, 0.30, 0.11), skin, 8)
			block(torso, Vector3(side * 0.19, -1.28, 0.08), Vector3(0.18, 0.09, 0.32), mat("#163d49"))
		shape(torso, Vector3(0, 0.51, 0.32), Vector3(0.06, 0.06, 0.025), mat("#e1bc69"), 6)
	block(torso, Vector3(-0.32,0.31,0.29), Vector3(0.13,0.025,0.015), shirt)
	shape(torso, Vector3(0.29,0.49,0.30), Vector3(0.024,0.042,0.027), mat("#202d35"), 6)
	for side in [-1,1]:
		if reporter_host:
			var elbow := Vector3(side * 0.62, -0.08, 0.08)
			var wrist := Vector3(0.19, 0.28, 0.58) if side == 1 else Vector3(-0.50, -0.48, 0.16)
			limb(Vector3(side * 0.48, 0.48, 0), elbow, 0.16, suit)
			limb(elbow, wrist, 0.12, suit)
			var hand := shape(torso, wrist, Vector3(0.10, 0.13, 0.10), skin, 8)
			if side == 1:
				right_hand = hand
				block(hand, Vector3(0, 0.14, 0), Vector3(0.06, 0.36, 0.06), mat("#202932"))
				block(hand, Vector3(0, 0.25, 0), Vector3(0.19, 0.14, 0.15), mat("#d7bc7c"))
				shape(hand, Vector3(0, 0.39, 0), Vector3(0.11, 0.14, 0.10), mat("#151d24"), 8)
			continue
		if weather_host:
			var elbow := Vector3(side * 0.69, 0.04, 0)
			var wrist := Vector3(-1.02, 0.29, 0.05) if side == -1 else Vector3(0.48, -0.35, 0.1)
			limb(Vector3(side * 0.48, 0.48, 0), elbow, 0.16, suit)
			limb(elbow, wrist, 0.12, suit)
			var hand := shape(torso, wrist, Vector3(0.15, 0.07, 0.10), skin, 8)
			if side == -1:
				right_hand = hand
			continue
		limb(Vector3(side*0.48,0.48,0), Vector3(side*0.68,0.01,0.18),0.18,suit)
		limb(Vector3(side*0.68,0.01,0.18),Vector3(side*0.38,0.06,0.83),0.135,suit)
		block(torso,Vector3(side*0.37,0.07,0.77),Vector3(0.21,0.10,0.10),shirt)
		var hand := shape(torso,Vector3(side*0.32,0.055,0.92),Vector3(0.17,0.07,0.16),skin,8)
		for finger in range(3):
			block(hand,Vector3(-0.075+finger*0.07,0.026,0.10),Vector3(0.009,0.01,0.08),cheek)
		if side == 1:
			right_hand = hand
	head = Node3D.new()
	head.position = Vector3(0,1.03,0.005)
	torso.add_child(head)
	shape(head,Vector3.ZERO,Vector3(0.36,0.45,0.30),skin,10)
	jaw = shape(head,Vector3(0,-0.27,0.12),Vector3(0.27,0.19,0.22),skin,8)
	for side in [-1,1]:
		shape(head,Vector3(side*0.35,0,0),Vector3(0.083,0.15,0.065),skin,7)
		shape(head,Vector3(side*0.365,0,0.047),Vector3(0.035,0.077,0.012),cheek,6)
		shape(head,Vector3(side*0.22,-0.10,0.22),Vector3(0.11,0.115,0.075),cheek,7)
		var eye := Node3D.new()
		eye.position = Vector3(side*0.145,0.095,0.271)
		head.add_child(eye)
		eyes.append(eye)
		shape(eye,Vector3.ZERO,Vector3(0.106,0.064,0.038),shirt,8)
		var pupil := shape(eye,Vector3(-side*0.008,0,0.033),Vector3(0.032,0.040,0.012),hair,8)
		pupils.append(pupil)
		block(eye,Vector3(-0.008,0.016,0.044),Vector3(0.011,0.012,0.008),shirt)
		var brow := block(head,Vector3(side*0.15,0.20,0.269),Vector3(0.21,0.044,0.032),hair)
		brow.rotation.z = side * -0.10
		block(head,Vector3(side*0.305,0.16,0.03),Vector3(0.06,0.27,0.19),hair)
		if not weather_host:
			block(head,Vector3(side*0.327,0.14,0.065),Vector3(0.022,0.14,0.11),gray)
		else:
			shape(head, Vector3(side * 0.34, -0.09, -0.04), Vector3(0.13, 0.40, 0.25), hair, 7)
			shape(head, Vector3(side * 0.37, -0.16, 0.08), Vector3(0.033, 0.063, 0.025), mat("#efca74"), 6)
	# Prominent faceted nose, neat moustache and an over-rehearsed closed smile.
	shape(head,Vector3(0,-0.005,0.326),Vector3(0.085,0.135,0.135),skin,6)
	for side in [-1,1]:
		if weather_host or reporter_host:
			continue
		var moustache := block(head,Vector3(side*0.075,-0.14,0.303),Vector3(0.15,0.048,0.038),hair)
		moustache.rotation.z = side*0.10
	mouth = shape(head,Vector3(0,-0.242,0.337),Vector3(0.145,0.019,0.018),mat("#983f49" if weather_host else "#4f2929"),8)
	block(head,Vector3(0,-0.235,0.355),Vector3(0.18,0.017,0.01),shirt)
	shape(head,Vector3(0,0.345,-0.025),Vector3(0.37,0.17,0.295),hair,9)
	var sweep := shape(head,Vector3(-0.09,0.35,0.18),Vector3(0.27,0.11,0.16),hair,7)
	sweep.rotation.z = -0.20
	if not weather_host:
		block(head,Vector3(0.18,0.418,0.12),Vector3(0.015,0.012,0.20),gray).rotation.z = -0.18

func _process(delta: float) -> void:
	time += delta
	# A restrained 12 fps puppet rhythm, with an oddly late double blink.
	var tick := int(time * 12)
	if tick == last_tick:
		return
	last_tick = tick
	var opening := Narration.mouth_open
	var pose := 0.0 if opening < 0.08 else (0.5 if opening < 0.45 else 1.0)
	mouth.scale.y = 1.0 + pose * 4.0
	mouth.position.y = -0.242 - pose * 0.035
	jaw.position.y = -0.27 - pose * 0.045
	var t := tick / 12.0
	torso.position.y = sin(t * 1.35) * 0.006
	head.rotation.y = sin(t * 0.46) * 0.055
	head.rotation.z = sin(t * 0.29) * 0.025 - 0.02
	var cycle := fmod(t, 13.0)
	head.rotation.x = sin(clampf((cycle-8.0)*1.8,0,PI)) * 0.13
	var blink := fmod(t, 5.7)
	for i in range(eyes.size()):
		var closed := (blink > 4.7+i*0.06 and blink < 4.87+i*0.06) or (blink > 5.10 and blink < 5.19)
		eyes[i].scale.y = 0.12 if closed else 1.0
		pupils[i].position.x = sin(t * 0.31) * 0.012
	right_hand.rotation.x = sin(clampf((cycle-10.0)*2,0,TAU)) * 0.12

extends "res://presenter.gd"
## Separate field correspondent. Shares only mesh helpers and lip/idle animation.
func _ready() -> void:
	var skin := mat("#a9704e")
	var cheek := mat("#925a41")
	var hair := mat("#211c1c")
	var jacket := mat("#b77336")
	var collar := mat("#d99a55")
	var shirt := mat("#e3dfcd")
	var trousers := mat("#283c48")
	var shoes := mat("#302a27")
	torso = Node3D.new()
	add_child(torso)
	shape(torso, Vector3(0, 0.20, 0), Vector3(0.46, 0.53, 0.23), jacket, 8)
	shape(torso, Vector3(0, 0.66, 0), Vector3(0.12, 0.21, 0.12), skin, 8)
	block(torso, Vector3(0, 0.30, 0.225), Vector3(0.22, 0.61, 0.05), shirt)
	for side in [-1, 1]:
		var flap := block(torso, Vector3(side * 0.18, 0.54, 0.26), Vector3(0.15, 0.23, 0.05), collar)
		flap.rotation.z = side * -0.30
		block(torso, Vector3(side * 0.31, 0.17, 0.225), Vector3(0.17, 0.19, 0.055), collar)
		block(torso, Vector3(side * 0.31, 0.23, 0.26), Vector3(0.17, 0.035, 0.025), jacket)
	# Full hips, separate trouser legs and grounded shoes.
	shape(torso, Vector3(0, -0.32, 0), Vector3(0.35, 0.24, 0.22), trousers, 8)
	block(torso, Vector3(0, -0.20, 0.21), Vector3(0.64, 0.065, 0.035), shoes)
	block(torso, Vector3(0, -0.20, 0.24), Vector3(0.10, 0.07, 0.025), mat("#c3ae7e"))
	for side in [-1, 1]:
		var ankle := Vector3(side * 0.22, -1.29, 0.02)
		limb(Vector3(side * 0.18, -0.37, 0), Vector3(side * 0.21, -0.84, 0.02), 0.17, trousers)
		limb(Vector3(side * 0.21, -0.84, 0.02), ankle, 0.13, trousers)
		block(torso, ankle + Vector3(0, -0.09, 0.10), Vector3(0.25, 0.16, 0.43), shoes)
		block(torso, ankle + Vector3(0, -0.18, 0.10), Vector3(0.26, 0.035, 0.44), mat("#171e24"))
		var elbow := Vector3(side * 0.53, -0.04, 0.02)
		var wrist := Vector3(0.19, 0.28, 0.46) if side == 1 else Vector3(-0.46, -0.43, 0.12)
		limb(Vector3(side * 0.38, 0.46, 0), elbow, 0.15, jacket)
		limb(elbow, wrist, 0.11, jacket)
		var hand := shape(torso, wrist, Vector3(0.09, 0.12, 0.09), skin, 8)
		if side == 1:
			right_hand = hand
			block(hand, Vector3(0, 0.12, 0), Vector3(0.06, 0.30, 0.06), mat("#202932"))
			block(hand, Vector3(0, 0.23, 0), Vector3(0.18, 0.14, 0.15), mat("#24486c"))
			var logo := Label3D.new()
			logo.text = "A"
			logo.font_size = 40
			logo.pixel_size = 0.003
			logo.position = Vector3(0, 0.23, 0.08)
			logo.modulate = Color("#f2d58b")
			hand.add_child(logo)
			shape(hand, Vector3(0, 0.36, 0), Vector3(0.105, 0.12, 0.10), mat("#151d24"), 8)
	head = Node3D.new()
	head.position = Vector3(0, 1.0, 0)
	torso.add_child(head)
	shape(head, Vector3.ZERO, Vector3(0.285, 0.38, 0.255), skin, 8)
	jaw = shape(head, Vector3(0, -0.27, 0.10), Vector3(0.21, 0.12, 0.17), skin, 8)
	for side in [-1, 1]:
		shape(head, Vector3(side * 0.28, -0.015, 0), Vector3(0.055, 0.095, 0.06), skin, 6)
		shape(head, Vector3(side * 0.19, -0.10, 0.18), Vector3(0.07, 0.075, 0.065), cheek, 7)
		var eye := Node3D.new()
		eye.position = Vector3(side * 0.12, 0.07, 0.228)
		head.add_child(eye)
		eyes.append(eye)
		shape(eye, Vector3.ZERO, Vector3(0.075, 0.039, 0.03), shirt, 8)
		var pupil := shape(eye, Vector3(0, 0, 0.028), Vector3(0.023, 0.029, 0.012), hair, 7)
		pupils.append(pupil)
		var brow := block(head, Vector3(side * 0.12, 0.16, 0.24), Vector3(0.15, 0.033, 0.027), hair)
		brow.rotation.z = side * 0.13
	shape(head, Vector3(0, -0.02, 0.26), Vector3(0.065, 0.10, 0.075), skin, 6)
	mouth = shape(head, Vector3(0, -0.242, 0.28), Vector3(0.105, 0.017, 0.02), mat("#59342e"), 8)
	# High, cropped curls give a different silhouette from Augusto's side part.
	shape(head, Vector3(0, 0.28, -0.045), Vector3(0.30, 0.19, 0.24), hair, 8)
	for row in range(3):
		for column in range(5):
			shape(head, Vector3(-0.23 + column * 0.115, 0.33 + (column % 2) * 0.035, -0.16 + row * 0.14), Vector3(0.085, 0.095, 0.08), hair, 6)

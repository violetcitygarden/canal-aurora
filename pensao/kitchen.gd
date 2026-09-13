extends "res://geometry.gd"
func _ready() -> void:
	# Open fourth wall, warm plaster and faded ceramic tiles.
	box(Vector3(0,4.15,2),Vector3(12,0.2,16),"#b9b18e")
	beam(Vector3(0,4.05,-0.3),Vector3(0,3.5,-0.3),0.025,"#726b54")
	cylinder(Vector3(0,3.48,-0.3),0.26,0.08,"#e3d9ae")
	box(Vector3(0, -0.12, 0), Vector3(12, 0.22, 10), "#9b8d75")
	textured_box(Vector3(0,0,0),Vector3(12,0.025,10),"#d9cba6",load_texture("res://assets/floor.png"),Vector2(6,5))
	box(Vector3(0, 2.0, -4.6), Vector3(12, 4, 0.16), "#cdc69e")
	box(Vector3(-5.9, 2.0, 0), Vector3(0.16, 4, 9.2), "#b9b48d")
	textured_box(Vector3(0,1,-4.49),Vector3(12,2,0.03),"#91b9a3",load_texture("res://assets/tiles.png"),Vector2(8,2))
	# Corridor to bedrooms at the right edge.
	box(Vector3(5.8, 2, -2.8), Vector3(0.2, 4, 3.6), "#9e9a7e")
	box(Vector3(4.8, 3.6, -4.35), Vector3(2.1, 0.65, 0.3), "#958974")
	box(Vector3(4.8, 1.55, -4.42), Vector3(1.8, 3.1, 0.08), "#383d36")
	box(Vector3(4.8, 1.4, -4.32), Vector3(1.3, 2.8, 0.07), "#76654d")
	label("QUARTOS", Vector3(4.8, 3.15, -4.17), 0.004)
	# Sink and cabinets, enamel stove, old refrigerator.
	box(Vector3(-1.6, 0.55, -3.9), Vector3(4.9, 1.1, 1.0), "#b4ae88")
	box(Vector3(-1.6, 1.13, -3.87), Vector3(5.1, 0.12, 1.12), "#777c74")
	for x in [-3.3, -2.2, -1.1, 0.0]:
		box(Vector3(x, 0.6, -3.36), Vector3(0.97, 0.87, 0.04), "#d3cba9")
		box(Vector3(x + 0.3, 0.83, -3.31), Vector3(0.14, 0.045, 0.06), "#505e55")
	box(Vector3(-2.1, 1.2, -3.9), Vector3(1.1, 0.04, 0.65), "#3b5256")
	beam(Vector3(-2.1,1.2,-4.2), Vector3(-2.1,1.65,-4.2),0.055,"#a9b9b2")
	beam(Vector3(-2.1,1.65,-4.2), Vector3(-2.1,1.65,-3.9),0.055,"#a9b9b2")
	box(Vector3(1.6, 0.58, -3.86), Vector3(1.25, 1.16, 1.0), "#d5d3b6")
	box(Vector3(1.6, 0.52, -3.32), Vector3(0.95, 0.58, 0.05), "#37464a")
	for x in [1.3,1.9]:
		for z in [-4.1,-3.6]:
			cylinder(Vector3(x, 1.19, z), 0.18, 0.025, "#323b36")
	cylinder(Vector3(1.3,1.34,-4.1),0.21,0.3,"#a8afaa")
	cylinder(Vector3(1.3,1.51,-4.1),0.23,0.035,"#d1d1bd")
	box(Vector3(3.1, 1.15, -3.9), Vector3(1.3, 2.3, 1.1), "#d7d9bc")
	box(Vector3(3.1, 1.55, -3.32), Vector3(1.18, 0.06, 0.035), "#747d72")
	for y in [0.95,1.9]:
		box(Vector3(2.68, y, -3.27), Vector3(0.075, 0.3, 0.07), "#596961")
	box(Vector3(3.22, 1.14, -3.25), Vector3(0.5, 0.62, 0.015), "#e4d8ab")
	label("NOME\nNOS POTES", Vector3(3.22,1.15,-3.23),0.0025)
	# Brazilian clay water filter and glass; embroidered cloth suggestion.
	box(Vector3(-0.3,1.21,-3.85),Vector3(0.85,0.025,0.75),"#e3daba")
	cylinder(Vector3(-0.3,1.55,-3.85),0.24,0.66,"#b77549")
	cylinder(Vector3(-0.3,1.9,-3.85),0.26,0.05,"#8c5737")
	box(Vector3(-0.3,1.43,-3.57),Vector3(0.065,0.065,0.14),"#dadac3")
	cylinder(Vector3(0.2,1.34,-3.8),0.07,0.22,"#9eb5a8")
	# Window with grille and short gingham-like curtains.
	box(Vector3(-2.1, 2.7, -4.35), Vector3(2.2, 1.45, 0.06), "#637f78")
	for x in [-3.15,-2.45,-1.75,-1.05]:
		box(Vector3(x,2.7,-4.28),Vector3(0.045,1.5,0.05),"#d0ccb3")
	box(Vector3(-2.1,2.7,-4.28),Vector3(2.2,0.045,0.05),"#d0ccb3")
	for x in [-3.15,-1.05]:
		box(Vector3(x,2.65,-4.15),Vector3(0.42,1.55,0.07),"#dbca9f")
		for y in range(7):
			box(Vector3(x,2+y*0.2,-4.1),Vector3(0.42,0.07,0.02),"#a56d54")
	# Formica table leaves clear walking lanes around its perimeter.
	box(Vector3(0,0.92,0.3),Vector3(2.5,0.12,1.5),"#c9b276")
	for x in [-1.0,1.0]:
		for z in [-0.25,0.85]:
			box(Vector3(x,0.45,z),Vector3(0.055,0.9,0.055),"#737d76")
	for spec in [[Vector3(-1.95,0,0.3),PI/2,Vector3(-3.2,0,0.3)], [Vector3(1.95,0,0.3),-PI/2,Vector3(3.5,0,0.3)], [Vector3(0,0,1.85),PI,Vector3(0,0,2.7)]]:
		var chair := Node3D.new()
		add_child(chair)
		chair.position = spec[0]
		chair.rotation.y = spec[1]
		chair.add_to_group("chairs")
		chair.set_meta("approach", spec[2])
		box(Vector3(0,0.51,0),Vector3(0.65,0.1,0.65),"#8a5843",chair)
		# Actors face local +Z; the backrest belongs behind them.
		box(Vector3(0,1.0,-0.29),Vector3(0.65,0.65,0.08),"#99724b",chair)
		for x in [-0.25,0.25]:
			for z in [-0.25,0.25]:
				box(Vector3(x,0.25,z),Vector3(0.045,0.5,0.045),"#747f75",chair)
	cylinder(Vector3(0.2,1.05,0.25),0.27,0.07,"#d8d6b8")
	sphere(Vector3(0.2,1.12,0.25),Vector3(0.19,0.09,0.14),"#bb854b")
	cylinder(Vector3(-0.65,1.17,0.2),0.11,0.4,"#693f33")
	# Hanging fern: chain, suspended pot and thirty drooping segmented fronds.
	beam(Vector3(-4.35,4,-1.2),Vector3(-4.35,2.95,-1.2),0.035,"#5d6558")
	cylinder(Vector3(-4.35,2.87,-1.2),0.3,0.27,"#9b603b")
	for i in range(22):
		var angle := TAU * i / 22
		var previous := Vector3(-4.35,3.03,-1.2)
		for j in range(1,7):
			var t := j/6.0
			var point := Vector3(-4.35+cos(angle)*t*0.92,3.03+sin(t*PI)*0.17-t*t*0.65,-1.2+sin(angle)*t*0.92)
			beam(previous,point,0.025,"#455e32")
			var leaf := box(point,Vector3(0.18*(1-t*0.6),0.025,0.08),"#557b3b" if i%2 else "#6a8845")
			leaf.rotation.y = -angle
			previous = point
	label("PENSÃO NAIR\nCOZINHA ATÉ 22h",Vector3(0.4,2.8,-4.35),0.004)
	# Crooked wall clock.
	cylinder(Vector3(-4.65,2.85,-4.3),0.3,0.04,"#ddd2a6").rotation_degrees.x=90
	beam(Vector3(-4.65,2.85,-4.25),Vector3(-4.65,3.05,-4.25),0.02,"#414737")
	beam(Vector3(-4.65,2.85,-4.25),Vector3(-4.49,2.8,-4.25),0.02,"#414737")

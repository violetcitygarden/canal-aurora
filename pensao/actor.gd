extends "res://geometry.gd"
var identity := "NAIR"
var mouth: Node3D
var body: Node3D
var head: Node3D
var legs: Array[Node3D] = []
var opening := 0.0
var talking := false
var elapsed := 0.0
var tick := -1
var destination := Vector3.ZERO
var wait_left := 2.0
var point_index := 0
const STOPS := [Vector3(-3.1,0,-1.9),Vector3(0,0,-2.1),Vector3(3.5,0,-1.8),Vector3(3.5,0,2.7),Vector3(-3.2,0,2.7)]
func _ready() -> void:
	body = Node3D.new()
	add_child(body)
	var skin := "#bd8c65"
	var clothes := "#85668a"
	var hair := "#a5a294"
	if identity == "VALDIR":
		skin = "#cfab82"; clothes = "#bca974"; hair = "#63584a"
	elif identity == "JESSICA":
		skin = "#9a6547"; clothes = "#789a91"; hair = "#322925"
	elif identity == "MAURO":
		skin = "#c89369"; clothes = "#a57650"; hair = "#46392b"
	var belly := 0.41 if identity == "VALDIR" else 0.31
	sphere(Vector3(0,1.08,0),Vector3(belly,0.44,0.23),clothes,body)
	if identity == "NAIR":
		sphere(Vector3(0,0.58,0),Vector3(0.38,0.48,0.25),clothes,body)
		box(Vector3(0,0.96,0.235),Vector3(0.37,0.6,0.025),"#bdb491",body)
	else:
		box(Vector3(0,0.77,0),Vector3(0.49,0.3,0.32),"#475969",body)
	for side in [-1,1]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.15,0.68,0)
		body.add_child(leg)
		legs.append(leg)
		box(Vector3(0,-0.28,0),Vector3(0.18,0.56,0.19),skin if identity=="NAIR" else "#475969",leg)
		box(Vector3(0,-0.59,0.07),Vector3(0.23,0.14,0.36),"#3e4138",leg)
		beam(Vector3(side*0.31,1.33,0),Vector3(side*0.43,0.92,0.05),0.17,clothes,body)
		beam(Vector3(side*0.43,0.92,0.05),Vector3(side*0.42,0.69,0.11),0.11,skin,body)
		sphere(Vector3(side*0.42,0.68,0.11),Vector3(0.08,0.1,0.07),skin,body)
	head = Node3D.new()
	head.position = Vector3(0,1.69,0)
	body.add_child(head)
	sphere(Vector3.ZERO,Vector3(0.25,0.31,0.23),skin,head)
	for side in [-1,1]:
		box(Vector3(side*0.095,0.055,0.216),Vector3(0.08,0.04,0.025),"#dad8bc",head)
		box(Vector3(side*0.095,0.055,0.235),Vector3(0.026,0.035,0.015),"#302e28",head)
		var brow := box(Vector3(side*0.1,0.13,0.22),Vector3(0.11,0.027,0.025),hair,head)
		brow.rotation.z = side * (0.22 if identity=="NAIR" else -0.1)
	sphere(Vector3(0,-0.01,0.245),Vector3(0.045,0.075,0.07),skin,head)
	mouth = box(Vector3(0,-0.135,0.218),Vector3(0.105,0.021,0.025),"#633e35",head)
	if identity == "NAIR":
		sphere(Vector3(0,0.24,-0.05),Vector3(0.27,0.14,0.22),hair,head)
		sphere(Vector3(0,0.28,-0.23),Vector3(0.14,0.13,0.12),hair,head)
		for side in [-1,1]:
			for y in [0.02,0.1]:
				box(Vector3(side*0.105,y,0.255),Vector3(0.14,0.017,0.015),"#675a42",head)
			for x in [side*0.04,side*0.17]:
				box(Vector3(x,0.06,0.255),Vector3(0.014,0.08,0.015),"#675a42",head)
	elif identity == "VALDIR":
		for side in [-1,1]:
			sphere(Vector3(side*0.21,0.13,-0.02),Vector3(0.065,0.15,0.21),hair,head)
		box(Vector3(0,-0.08,0.255),Vector3(0.15,0.035,0.025),hair,head)
	elif identity == "JESSICA":
		sphere(Vector3(0,0.21,-0.04),Vector3(0.27,0.16,0.23),hair,head)
		sphere(Vector3(0,0.0,-0.28),Vector3(0.14,0.31,0.13),hair,head)
	else:
		sphere(Vector3(0,0.25,-0.04),Vector3(0.26,0.14,0.22),hair,head)
		box(Vector3(0,1.25,0.24),Vector3(0.06,0.35,0.035),"#d4cba9",body)
	point_index = ["NAIR","VALDIR","JESSICA","MAURO"].find(identity)
	position = STOPS[point_index]
	destination = position
	wait_left = randf_range(3,7)
func _process(delta: float) -> void:
	elapsed += delta
	var current_tick := int(elapsed*10)
	if tick == current_tick:
		return
	var dt := float(current_tick-tick)/10.0 if tick >= 0 else 0.1
	tick = current_tick
	mouth.scale.y = 1.0 + (floor(opening*3)/3.0)*5.0
	head.rotation.z = sin(elapsed*0.7)*0.035
	if position.distance_to(destination) > 0.03:
		var direction := (destination-position).normalized()
		rotation.y = snappedf(atan2(direction.x,direction.z), PI/8)
		position = position.move_toward(destination,dt*0.52)
		body.position.y = absf(sin(elapsed*5))*0.018
		for i in range(legs.size()):
			legs[i].rotation.x = sin(elapsed*5+i*PI)*0.22
	else:
		wait_left -= dt
		for leg in legs:
			leg.rotation.x = 0
		if wait_left <= 0:
			point_index = (point_index+1)%STOPS.size()
			destination = STOPS[point_index]
			wait_left = randf_range(7,16)
		elif talking and fmod(elapsed,5.0)<0.1:
			rotation.y = 0 if randf()<0.65 else PI/2

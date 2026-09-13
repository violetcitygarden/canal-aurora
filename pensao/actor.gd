extends "res://geometry.gd"
var staging := false
var stage_target := Vector3.ZERO
var stage_aisle := false
var leaving := false
var identity := "NAIR"
var mouth: Node3D
var body: Node3D
var head: Node3D
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var seat: Node3D
var seat_phase := ""
var seated := false
var seated_left := 0.0
var blocked_time := 0.0
const PERSONAL_SPACE := 0.9
var opening := 0.0
var talking := false
var elapsed := 0.0
var tick := -1
var destination := Vector3.ZERO
var wait_left := 2.0
var point_index := 0
const STOPS := [Vector3(-3.1,0,-1.9),Vector3(0,0,-2.1),Vector3(3.5,0,-1.8),Vector3(3.5,0,2.7),Vector3(-3.2,0,2.7)]
func _ready() -> void:
	add_to_group("pensao_actors")
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
		box(Vector3(0,-0.14,0),Vector3(0.18,0.28,0.19),skin if identity=="NAIR" else "#475969",leg)
		var knee := Node3D.new()
		knee.position.y = -0.28
		leg.add_child(knee)
		knees.append(knee)
		box(Vector3(0,-0.14,0),Vector3(0.18,0.28,0.19),skin if identity=="NAIR" else "#475969",knee)
		box(Vector3(0,-0.31,0.07),Vector3(0.23,0.14,0.36),"#3e4138",knee)
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
	if not visible:
		release_seat()
		return
	if staging:
		var direction := stage_target - position
		rotation.y = snappedf(atan2(direction.x,direction.z), PI/8)
		move_with_space(stage_target, delta * 1.5)
		for i in range(legs.size()): legs[i].rotation.x = sin(elapsed*7+i*PI)*0.25
		elapsed += delta
		tick = int(elapsed*10)
		if position.distance_to(stage_target)<0.05:
			if stage_aisle:
				stage_aisle = false
				stage_target = Vector3(4.8,0,-3.4)
				return
			staging = false
			visible = not leaving
			destination = position
			wait_left = 5
		return
	elapsed += delta
	var current_tick := int(elapsed*10)
	if tick == current_tick:
		return
	var dt := float(current_tick-tick)/10.0 if tick >= 0 else 0.1
	tick = current_tick
	mouth.scale.y = 1.0 + (floor(opening*3)/3.0)*5.0
	head.rotation.z = sin(elapsed*0.7)*0.035
	if seated:
		seated_left -= dt
		if seated_left <= 0 and not talking:
			seated = false
			body.position.y = 0
			for knee in knees: knee.rotation.x = 0
			for leg in legs: leg.rotation.x = 0
			seat_phase = "exit"
			destination = seat.get_meta("approach")
		return
	# Give entering/leaving actors priority through a crowded aisle.
	if seat_phase.is_empty() and position.distance_to(destination) < 0.03:
		for other in get_tree().get_nodes_in_group("pensao_actors"):
			if other != self and other.visible and other.staging and position.distance_to(other.position) < 1.5:
				choose_stop()
				break
	if position.distance_to(destination) > 0.03:
		var direction := (destination-position).normalized()
		rotation.y = snappedf(atan2(direction.x,direction.z), PI/8)
		if not move_with_space(destination,dt*0.52):
			blocked_time += dt
			if blocked_time > 3 and seat_phase != "exit":
				release_seat()
				choose_stop()
				blocked_time = 0
		else:
			blocked_time = 0
		body.position.y = absf(sin(elapsed*5))*0.018
		for i in range(legs.size()):
			legs[i].rotation.x = sin(elapsed*5+i*PI)*0.22
	else:
		if seat_phase == "approach":
			seat_phase = "arrive"
			destination = seat.position
			return
		if seat_phase == "arrive":
			seated = true
			seat_phase = "seated"
			rotation.y = seat.rotation.y
			body.position.y = -0.08
			for leg in legs: leg.rotation.x = -PI/2
			for knee in knees: knee.rotation.x = PI/2
			seated_left = randf_range(20,55)
			return
		if seat_phase == "exit":
			release_seat()
			destination = STOPS[point_index]
			wait_left = randf_range(7,16)
			return
		wait_left -= dt
		for leg in legs:
			leg.rotation.x = 0
		if wait_left <= 0:
			if randf() < 0.45 and reserve_nearby_seat():
				return
			choose_stop()
			wait_left = randf_range(7,16)
		elif talking and fmod(elapsed,5.0)<0.1:
			rotation.y = 0 if randf()<0.65 else PI/2

func change_presence(entering: bool) -> void:
	# Walk back to the aisle before taking the exit route.
	var aisle: Vector3 = seat.get_meta("approach") if is_instance_valid(seat) else position
	stage_aisle = not entering and is_instance_valid(seat)
	release_seat()
	staging = true
	leaving = not entering
	visible = true
	if entering:
		position = Vector3(4.8,0,-3.4)
		stage_target = Vector3(4.6,0,-1.8)
		for candidate in [Vector3(3.5,0,-1.8), Vector3(4.6,0,-1.8), Vector3(4.6,0,0)]:
			if space_available(candidate, true):
				stage_target = candidate
				break
	else:
		stage_target = aisle if stage_aisle else Vector3(4.8,0,-3.4)

func reserve_nearby_seat() -> bool:
	for chair in get_tree().get_nodes_in_group("chairs"):
		var occupant = chair.get_meta("occupant") if chair.has_meta("occupant") else null
		if is_instance_valid(occupant) and occupant.visible: continue
		var approach: Vector3 = chair.get_meta("approach")
		# Only approach from the adjacent aisle, never across the table.
		if position.distance_to(approach) > 3.3: continue
		if approach.x < -2 and position.x > -2: continue
		if approach.x > 2 and position.x < 2: continue
		if absf(approach.x) < 1 and position.z < 2.5: continue
		seat = chair
		seat.set_meta("occupant", self)
		seat_phase = "approach"
		destination = approach
		return true
	return false

func release_seat() -> void:
	if is_instance_valid(seat) and seat.has_meta("occupant") and seat.get_meta("occupant") == self:
		seat.remove_meta("occupant")
	seat = null
	seated = false
	seat_phase = ""
	if is_instance_valid(body): body.position.y = 0
	for leg in legs: leg.rotation.x = 0
	for knee in knees: knee.rotation.x = 0

func _exit_tree() -> void:
	release_seat()

func space_available(at: Vector3, include_destinations := false) -> bool:
	for other in get_tree().get_nodes_in_group("pensao_actors"):
		if other == self or not other.visible: continue
		if at.distance_to(other.position) < PERSONAL_SPACE: return false
		if include_destinations and at.distance_to(other.destination) < PERSONAL_SPACE:
			return false
	return true

func choose_stop() -> void:
	for offset in range(1, STOPS.size()+1):
		var index := (point_index+offset)%STOPS.size()
		if space_available(STOPS[index], true):
			point_index = index
			destination = STOPS[index]
			return
	destination = position
	wait_left = randf_range(2,4)

func move_with_space(target: Vector3, distance: float) -> bool:
	var next := position.move_toward(target, distance)
	if space_available(next):
		position = next
		return true
	# Yield instead of pushing another actor or stepping through furniture.
	return false

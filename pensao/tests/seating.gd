extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	seed(17)
	var kitchen = load("res://kitchen.gd").new()
	root.add_child(kitchen)
	var actors: Array = []
	for id in ["NAIR", "VALDIR", "JESSICA", "MAURO"]:
		var actor = load("res://actor.gd").new()
		actor.identity = id
		root.add_child(actor)
		actor.set_process(false)
		actors.append(actor)
	var a = actors[0]
	assert(a.reserve_nearby_seat())
	var chair = a.seat
	actors[1].position = Vector3(-3.2,0,2.7)
	actors[1].reserve_nearby_seat()
	assert(actors[1].seat != chair, "Chair was reserved twice")
	actors[1].release_seat()
	actors[1].position = Vector3(0,0,-2.1)
	for i in range(100): a._process(0.1)
	assert(a.seated, "Actor failed to sit")
	assert(a.head.global_position.y < 1.69)
	assert(absf(a.knees[0].rotation.x - PI/2) < 0.01)
	a.seated_left = 0
	for i in range(50): a._process(0.1)
	assert(not a.seated and a.seat == null, "Chair not released after standing")
	var saw_seated := false
	for frame in range(6000):
		for actor in actors:
			actor._process(0.1)
			saw_seated = saw_seated or actor.seated
		for i in range(actors.size()):
			for j in range(i+1,actors.size()):
				assert(actors[i].position.distance_to(actors[j].position) >= 0.899, "Actors overlapped")
	assert(saw_seated)
	a.release_seat()
	a.position = Vector3(-3.1,0,-1.9)
	for actor in actors.slice(1): actor.visible = false
	assert(a.reserve_nearby_seat())
	a.visible = false
	a._process(0.1)
	assert(a.seat == null)
	print("SEATING_OK reservation pose release hidden_actor 600_seconds_no_overlap")
	quit()

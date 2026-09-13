extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var kitchen = load("res://kitchen.gd").new()
	root.add_child(kitchen)
	var actor = load("res://actor.gd").new()
	root.add_child(actor)
	actor.set_process(false)
	# Independent collision volume: tabletop expanded by actor clearance.
	var table := AABB(Vector3(-1.79, -1, -0.99), Vector3(3.58, 3, 2.58))
	var points: Array = actor.STOPS.duplicate()
	points.append(Vector3(4.8,0,-3.4))
	for chair in get_nodes_in_group("chairs"):
		points.append(chair.position)
		points.append(chair.get_meta("approach"))
	var journeys := 0
	for start in points:
		for target in points:
			actor.position = start
			actor.route.clear()
			for step in range(400):
				var before: Vector3 = actor.position
				actor.move_with_space(target, 0.15 if step % 2 else 0.7)
				assert(table.intersects_segment(before, actor.position) == null, "Crossed the table")
				if actor.position.distance_to(target) < 0.03:
					break
			assert(actor.position.distance_to(target) < 0.03, "Failed to reach destination")
			journeys += 1
	# A seated resident must stand, return to the aisle and leave around the table.
	for chair in get_nodes_in_group("chairs"):
		actor.position = chair.position
		actor.seat = chair
		chair.set_meta("occupant", actor)
		actor.change_presence(false)
		for step in range(300):
			var before: Vector3 = actor.position
			actor._process(0.1)
			assert(table.intersects_segment(before, actor.position) == null, "Exit crossed the table")
			if not actor.staging:
				break
		assert(not actor.staging and not actor.visible, "Failed to leave from chair")
	print("TABLE_PATHS_OK journeys=", journeys, " all_chair_exits=OK")
	quit()

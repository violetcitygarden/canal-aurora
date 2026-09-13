extends SceneTree

func _initialize() -> void:
	call_deferred("check")

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func check() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for actor in scene.actors.values():
		actor.set_process(false)
		actor.visible = false
	var a = scene.actors.NAIR
	var b = scene.actors.VALDIR
	a.visible = true
	b.visible = true
	# Two people walking toward one another in the aisle beside the table.
	a.position = Vector3(3.5, 0, -1.8)
	b.position = Vector3(3.5, 0, 2.7)
	var target_a: Vector3 = b.position
	var target_b: Vector3 = a.position
	for step in range(600):
		a.replan_left = maxf(0, a.replan_left - 0.1)
		b.replan_left = maxf(0, b.replan_left - 0.1)
		a.move_with_space(target_a, 0.052)
		b.move_with_space(target_b, 0.052)
		if not require(a.position.distance_to(b.position) >= 0.899, "Head-on actors overlapped"): return
		if not require(not a.TableRoute.BLOCKED.has_point(a.position) and not a.TableRoute.BLOCKED.has_point(b.position), "Actor entered table"): return
		if a.position.distance_to(target_a) < 0.03 and b.position.distance_to(target_b) < 0.03: break
	if not require(a.position.distance_to(target_a) < 0.03 and b.position.distance_to(target_b) < 0.03, "Head-on actors never passed each other"): return
	# A stationary person must be bypassed during a scene exit, before timeout.
	a.position = Vector3(3.5, 0, 2.7)
	b.position = Vector3(3.5, 0, 0.0)
	a.change_presence(false)
	for step in range(200):
		a._process(0.1)
		if not require(a.position.distance_to(b.position) >= 0.899, "Exit crossed stationary person"): return
		if not a.staging: break
	if not require(not a.visible and a.stage_elapsed < 20, "Exit did not navigate around blocker"): return
	# Even an impossible transition must release playback, including a queued scene.
	scene.pending_scene = {"present":["NAIR", "VALDIR"], "lines":[
		{"speaker":"NAIR", "text":"Já volto."},
		{"speaker":"VALDIR", "text":"Agora consigo terminar.", "event":{"speaker":"NAIR", "action":"exit"}}]}
	scene.begin_scene()
	scene.next_line()
	a.stage_target = Vector3.ZERO # Deliberately unreachable inside the table.
	scene.pending_scene = {"lines":[{"speaker":"VALDIR", "text":"Próxima conversa."}]}
	for step in range(270):
		a._process(0.1)
		if scene.state == "transition" or scene.state == "gap": scene._process(0.1)
	if not require(not a.staging and not a.visible, "Transition watchdog failed"): return
	if not require(scene.active == "VALDIR" and scene.state == "silent_line", "Playback did not resume after blocked transition"): return
	if not require(not scene.pending_scene.is_empty(), "Recovery discarded prefetched scene"): return
	print("TRAFFIC_OK head_on stationary_blocker bounded_transition playback_resumed prefetch_preserved")
	quit()

extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(240).timeout.connect(func(): push_error("Playback timed out"); quit(1))
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.actors.size()==4)
	scene.config["laugh_probability"] = 0.0
	for i in range(100): assert(not scene.should_laugh())
	scene.config["laugh_probability"] = 1.0
	for i in range(100): assert(scene.should_laugh())
	scene.config["laugh_probability"] = 0.3
	scene.rng.seed = 1993
	var count := 0
	for i in range(10000):
		if scene.should_laugh(): count+=1
	assert(count>2800 and count<3200)
	scene.config["laugh_probability"] = 1.0
	var speakers: Dictionary = {}
	var saw_laugh := false
	var saw_mouth := false
	var first_position: Vector3 = scene.actors.NAIR.position
	while scene.line_index<4:
		await create_timer(0.05).timeout
		if scene.voice.playing:
			speakers[scene.active] = true
			if scene.actors[scene.active].opening>0.1: saw_mouth=true
		if scene.laughter.playing:
			saw_laugh=true
			assert(not scene.voice.playing)
	assert(speakers.size()>=2 and saw_laugh and saw_mouth)
	assert(scene.actors.NAIR.position.distance_to(first_position)>0.1)
	var event := InputEventKey.new()
	event.keycode=KEY_SPACE
	event.pressed=true
	scene._unhandled_key_input(event)
	var position: Vector3 = scene.actors.NAIR.position
	var line: int = scene.line_index
	await create_timer(0.4).timeout
	assert(scene.paused and scene.line_index==line and scene.actors.NAIR.position==position)
	print("PENSAO_OK real_speakers=",speakers.keys()," laughs=",saw_laugh," mouth=",saw_mouth," probability_count=",count," pause=OK")
	quit()

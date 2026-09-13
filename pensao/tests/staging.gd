extends SceneTree
func _initialize() -> void:
	call_deferred("check")
func check() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.pending_scene = {"present":["NAIR","JESSICA"],"lines":[{"speaker":"NAIR","text":"Cadê o Valdir?"},{"speaker":"VALDIR","text":"Cheguei.","event":{"action":"enter","speaker":"VALDIR"}},{"speaker":"NAIR","text":"Até depois.","event":{"action":"exit","speaker":"VALDIR"}}]}
	scene.begin_scene()
	assert(not scene.actors.VALDIR.visible)
	assert(scene.actors.NAIR.visible and scene.actors.JESSICA.visible)
	var next = {"present":["NAIR","JESSICA"],"lines":[{"speaker":"JESSICA","text":"E agora?"}]}
	scene._received(0,200,PackedStringArray(),JSON.stringify(next).to_utf8_buffer())
	assert(scene.lines.size()==3 and not scene.pending_scene.is_empty(),"Prefetch substituiu a cena atual")
	scene.next_line()
	assert(scene.state=="transition" and scene.actors.VALDIR.visible)
	assert(not scene.actors.VALDIR.talking,"Falou antes de entrar")
	for i in range(30): scene.actors.VALDIR._process(0.1)
	assert(not scene.actors.VALDIR.staging)
	scene._process(0.1)
	assert(scene.state == "transition", "Falou durante o jingle")
	scene.entrance_jingle.seek(8.0)
	scene._process(3.3) # Let the title expire; speech follows audio position, not delta.
	assert(scene.state == "transition" and scene.active != "VALDIR", "Falou antes do segundo nove")
	scene.entrance_jingle.seek(9.1)
	scene._process(0.1)
	assert(scene.active=="VALDIR")
	assert(scene.entrance_jingle.playing, "Jingle foi interrompido pela fala")
	assert(not scene.entrance_name.visible, "Nome não desapareceu")
	for shot in range(3):
		scene.shot_kind=shot
		scene.shot_left=3
		scene.update_shot(0.1)
		assert(scene.special_camera.position.is_finite())
	# A 180-degree actor turn must not swing the tracking camera around the face.
	scene.shot_kind=0
	scene.shot_left=5
	scene.shot_front=Vector3(0,0,1)
	scene.shot_initializing=true
	scene.update_shot(0.016)
	var previous_position: Vector3=scene.special_camera.position
	scene.actors.VALDIR.rotation.y += PI
	scene.update_shot(0.016)
	assert(scene.special_camera.position.distance_to(previous_position)<0.001,"Camera orbited with actor")
	scene.actors.VALDIR.position.x += 0.2
	scene.update_shot(0.016)
	var step: float=scene.special_camera.position.distance_to(previous_position)
	assert(step>0 and step<0.05,"Camera followed stepped movement without smoothing")
	scene.next_line()
	for i in range(30): scene.actors.VALDIR._process(0.1)
	assert(not scene.actors.VALDIR.visible)
	print("STAGING_OK entry_exit prefetch cameras speaker_timing speech_at_jingle_second_nine")
	quit()

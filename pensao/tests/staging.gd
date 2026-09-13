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
	scene._process(1)
	assert(scene.active=="VALDIR")
	for shot in range(3):
		scene.shot_kind=shot
		scene.shot_left=3
		scene.update_shot(0.1)
		assert(scene.special_camera.position.is_finite())
	scene.next_line()
	for i in range(30): scene.actors.VALDIR._process(0.1)
	assert(not scene.actors.VALDIR.visible)
	print("STAGING_OK entry_exit prefetch cameras speaker_timing")
	quit()

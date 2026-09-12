extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(100).timeout.connect(func(): quit(1))
	var scene = load("res://news.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var feed = root.get_node("NewsFeed")
	var voice = root.get_node("Narration")
	var overlay = scene.overlay
	voice.stop()
	feed.queue.clear()
	feed.draft = {"kind": "reporter", "broadcast_id": 100, "location": 0, "manchete": "Direto do centro", "texto": "Boa tarde. Estamos ao vivo no centro de Santa Irene. De volta ao estúdio.", "texto_narrado": "Boa tarde. Estamos ao vivo no centro de Santa Irene. De volta ao estúdio."}
	feed.phase = "voice"
	feed._voice_ready({})
	assert(feed.queue.is_empty() and feed.phase == "voice_retry")
	assert(feed.draft.texto_narrado.begins_with("Boa tarde"))
	print("FAILED_JEFF_NOT_QUEUED_TEXT_PRESERVED_OK")
	feed.enabled = true
	feed.retry_at = 0
	feed._process(0)
	feed.enabled = false
	await voice.prepared
	assert(feed.queue.size() == 1 and feed.queue[0].voice == "jeff")
	assert(feed.queue[0]._stream.get_length() > 1)
	feed.reporter_requested = true
	feed.return_to_studio = false
	overlay._next_generated()
	overlay.ident.cancel()
	overlay._update_handoff(0)
	overlay._update_handoff(10)
	assert(overlay.reporter_panel.visible and voice.player.playing)
	var peak := 0.0
	for i in range(100):
		await create_timer(0.02).timeout
		peak = maxf(peak, voice.mouth_open)
	assert(peak > 0.1)
	print("REAL_HTTP_JEFF_QUEUE_HANDOFF_PLAYBACK_LIPS_OK peak=", peak)
	quit()

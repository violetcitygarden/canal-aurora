extends SceneTree
# Run: godot --headless --path . --script res://tests/broadcast_cycle.gd -- --preview-reporter
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://news.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var feed = root.get_node("NewsFeed")
	var voice = root.get_node("Narration")
	var overlay = scene.overlay
	for auto in [true, false]:
		overlay.preview_reporter(0)
		var stream := AudioStreamWAV.new()
		stream.mix_rate = 8000
		stream.format = AudioStreamWAV.FORMAT_8_BITS
		var pcm := PackedByteArray()
		pcm.resize(80000)
		pcm.fill(128)
		stream.data = pcm
		overlay.items[0]["_stream"] = stream
		voice.play_story(overlay.items[0])
		overlay.received_first = true
		overlay.automatic = auto
		feed.queue.clear()
		feed.queue.append({"kind": "weather"})
		overlay._story_ready()
		assert(voice.player.playing)
		assert(overlay.pending_index == -1)
	print("READY_NEVER_INTERRUPTS_OK")
	voice.stop()
	overlay.automatic = false
	feed.queue.clear()
	feed.aired.clear()
	feed.return_to_studio = false
	feed.studio_since_reporter = 0
	feed.news_since_weather = 0
	feed.next_weather_at = 12
	for i in range(5):
		feed.story_aired({"broadcast_id": i, "kind": "studio"})
	assert(feed.desired_kind() == "reporter")
	feed.story_aired({"broadcast_id": 4, "kind": "studio"})
	assert(feed.studio_since_reporter == 5 and feed.news_since_weather == 5)
	feed.queue.append({"broadcast_id": 5, "kind": "reporter", "location": 0})
	var reporter = feed.take()
	assert(feed.has_kind("reporter"))
	assert(feed.studio_since_reporter == 5)
	feed.story_aired(reporter)
	assert(feed.return_to_studio and feed.studio_since_reporter == 0)
	feed.weather_requested = true
	feed.queue.append({"broadcast_id": 6, "kind": "weather"})
	assert(feed.take().is_empty())
	feed.queue.append({"broadcast_id": 7, "kind": "studio"})
	var studio = feed.take()
	assert(studio.kind == "studio")
	feed.story_aired(studio)
	assert(not feed.return_to_studio)
	assert(feed.take().kind == "weather")
	assert(feed.news_since_weather == 7)
	feed.story_aired({"broadcast_id": 6, "kind": "weather"})
	assert(feed.news_since_weather == 0)
	assert(feed.next_weather_at >= 12 and feed.next_weather_at <= 22)
	assert(feed.studio_since_reporter == 1)
	feed.draft = {"kind": "reporter"}
	feed._fail("simulated generation failure")
	assert(feed.studio_since_reporter == 1 and feed.news_since_weather == 0)
	print("COUNTERS_RETRY_RESERVATION_AND_STUDIO_RETURN_OK")
	# Verify the automatic handoff waits for the post-speech delay.
	feed.return_to_studio = false
	feed.weather_requested = true
	feed.queue.clear()
	feed.queue.append({"broadcast_id": 8, "kind": "weather", "manchete": "Tempo", "texto": "", "districts": [], "low": 10, "high": 20})
	overlay.automatic = true
	voice.silence = 1.9
	overlay._process(0.01)
	assert(overlay.pending_index == -1)
	voice.silence = 2.1
	overlay._process(0.01)
	assert(overlay.pending_index >= 0)
	print("POST_SPEECH_DELAY_OK")
	quit()

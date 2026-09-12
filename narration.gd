extends Node

signal prepared(payload: Dictionary)
var request: HTTPRequest
var player := AudioStreamPlayer.new()
var envelope: Array = []
var step := 0.02
var mouth_open := 0.0
var silence := 0.0
var muted := false
var preparing := false

func _ready() -> void:
	add_child(player)
	player.volume_db = -2
	request = HTTPRequest.new()
	request.timeout = 90
	request.body_size_limit = 24 * 1024 * 1024
	add_child(request)
	request.request_completed.connect(_completed)

func prepare(text: String, voice := "cadu") -> void:
	preparing = true
	var error := request.request("http://127.0.0.1:11436/synthesize", PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify({"text": text, "voice": voice}))
	if error != OK:
		preparing = false
		prepared.emit({})

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	preparing = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("Cadu indisponível: notícia exibida sem voz. HTTP %s" % code)
		prepared.emit({})
		return
	var payload = JSON.parse_string(body.get_string_from_utf8())
	if not payload is Dictionary or not payload.get("wav") is String or not payload.get("envelope") is Array:
		prepared.emit({})
		return
	var stream := AudioStreamWAV.load_from_buffer(Marshalls.base64_to_raw(payload.wav))
	if stream == null:
		prepared.emit({})
		return
	prepared.emit({"_stream": stream, "_envelope": payload.envelope, "_step": float(payload.get("step", 0.02)), "voice": str(payload.get("voice", "cadu")), "audio_seconds": stream.get_length()})

func play_story(story: Dictionary) -> void:
	stop()
	if story.get("_stream") is AudioStream:
		player.stream = story._stream
		envelope = story.get("_envelope", [])
		step = maxf(float(story.get("_step", 0.02)), 0.001)
		player.play()

func stop() -> void:
	player.stop()
	player.stream = null
	envelope = []
	mouth_open = 0
	silence = 0

func _process(delta: float) -> void:
	if player.playing:
		silence = 0
		var position := maxf(0, player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
		var frame := int(position / step)
		var target := float(envelope[frame]) if frame < envelope.size() else 0.0
		mouth_open = move_toward(mouth_open, target, delta * 12)
	else:
		silence += delta
		mouth_open = move_toward(mouth_open, 0, delta * 18)

func toggle_mute() -> void:
	muted = not muted
	player.volume_db = -80 if muted else -2

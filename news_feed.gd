extends Node

signal story_ready
var config: Dictionary = {}
var queue: Array[Dictionary] = []
var status := "Preparando redação"
var request: HTTPRequest
var phase := ""
var draft: Dictionary = {}
var retry_at := 0
var failures := 0
var enabled := true
var serial := 0
var weather_requested := false
var next_weather_at := 0
const TOPICS := ["obras e manutenção de ruas", "horários da biblioteca", "comércio e feira municipal", "previsão do tempo", "transporte entre bairros", "agenda do centro cultural", "abastecimento de água", "assembleia da associação de moradores"]
const ANOMALIES := ["um objeto comum se recusa a cumprir seu horário", "um endereço mudou de lugar sem avisar aos moradores", "uma fila continua existindo depois que todos foram embora", "a mesma tarde aconteceu duas vezes e gerou uma taxa municipal", "um animal recebeu um cargo público e só atende mediante agendamento", "um prédio está alguns centímetros atrasado em relação ao restante da cidade", "o silêncio precisa ser retirado pessoalmente na repartição", "algo que deveria ser sólido começou a ser vendido por minuto", "os moradores precisam devolver uma cor emprestada", "um serviço municipal funciona apenas quando ninguém está olhando", "um objeto doméstico entrou com um pedido administrativo", "uma parte do bairro foi confundida com uma pessoa"]

func _ready() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://llm.json"))
	if parsed is Dictionary:
		config = parsed
	else:
		enabled = false
		status = "llm.json inválido"
		return
	enabled = not "--capture-news" in OS.get_cmdline_user_args()
	request = HTTPRequest.new()
	request.timeout = 90
	request.body_size_limit = 1024 * 1024
	add_child(request)
	request.request_completed.connect(_completed)
	Narration.prepared.connect(_voice_ready)
	weather_requested = "--test-weather" in OS.get_cmdline_user_args() or "--start-weather" in OS.get_cmdline_user_args()
	next_weather_at = randi_range(12, 22)

func request_weather() -> void:
	# Keep the request pending if a news or speech job is already running.
	if not phase.is_empty() and draft.get("kind", "") == "weather":
		return
	for i in range(queue.size()):
		if queue[i].get("kind", "") == "weather":
			var ready_weather: Dictionary = queue[i]
			queue.remove_at(i)
			queue.push_front(ready_weather)
			status = "Previsão pronta para a próxima troca"
			return
	weather_requested = true
	status = "Previsão solicitada; preparando próximo quadro"

func _process(_delta: float) -> void:
	if enabled and phase.is_empty() and (queue.size() < 2 or weather_requested) and Time.get_ticks_msec() >= retry_at:
		generate()

func generate() -> void:
	if not enabled or not phase.is_empty() or (queue.size() >= 2 and not weather_requested):
		return
	if weather_requested or serial >= next_weather_at:
		var priority_weather := weather_requested
		weather_requested = false
		serial += 1
		next_weather_at = serial + randi_range(12, 22)
		draft = preload("res://weather_segment.gd").create()
		draft["priority"] = priority_weather
		draft["model"] = config.model
		phase = "weather_body"
		status = "BRD está escrevendo a previsão da Helena"
		_send(preload("res://weather_segment.gd").prompt(draft), int(config.get("weather_tokens", 350)), str(config.get("weather_system", config.system)))
		return
	var topic: String = TOPICS.pick_random()
	var anomaly: String = ANOMALIES.pick_random()
	serial += 1
	draft = {"editoria": "SANTA IRENE", "model": config.model, "pauta": topic, "anomalia": anomaly}
	phase = "headline"
	status = "Escrevendo manchete"
	var prompt := "Pauta: %s. Acontecimento: %s. Invente os detalhes e escreva uma única manchete com até 12 palavras, tratando isso como rotina municipal. Apenas a manchete, sem introdução, aspas ou lista." % [topic, anomaly]
	_send(prompt, 64)

func _send(prompt: String, limit: int, system_override := "") -> void:
	var payload := {
		"model": config.model, "system": config.system if system_override.is_empty() else system_override, "prompt": prompt,
		"stream": false, "keep_alive": "5m",
		"options": {"num_ctx": int(config.get("num_ctx", 2048)), "num_predict": limit,
			"temperature": float(config.get("temperature", 0.85)), "repeat_penalty": float(config.get("repeat_penalty", 1.0))}
	}
	var error := request.request(str(config.endpoint), PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_fail("Não foi possível iniciar o pedido: %s" % error)

func _completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_fail("Ollama indisponível (%s / HTTP %s)" % [result, code])
		return
	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response is Dictionary or not response.get("response") is String or response.response.strip_edges().is_empty():
		_fail("O modelo devolveu uma resposta vazia ou inválida")
		return
	var value: String = response.response.strip_edges()
	if phase == "headline":
		draft["raw_headline"] = value
		# Only normalize display markup; keep the model's wording.
		draft["manchete"] = value.split("\n", false)[0].replace("**", "").trim_prefix("# ").strip_edges().left(220)
		phase = "body"
		status = "Escrevendo notícia"
		_send.call_deferred("Manchete: %s\nO fato central que aconteceu de verdade nesta cidade: %s. Escreva esta notícia em aproximadamente 100 palavras. Relate esse fato impossível como rotina, sem transformar em metáfora. Acrescente um prazo preciso, uma consequência banal e uma declaração muito séria de um morador ou funcionário inventado. Apenas o texto que o apresentador vai ler, sem título, sem saudações e sem explicar a piada." % [draft.manchete, draft.anomalia], int(config.get("body_tokens", 350)))
	else:
		draft["texto"] = value
		draft["resumo"] = value.replace("\n", " ").split(". ")[0].left(180)
		draft["generated_at"] = Time.get_datetime_string_from_system()
		draft["done_reason"] = response.get("done_reason", "")
		phase = "voice"
		var is_weather: bool = draft.get("kind", "") == "weather"
		status = "Thalita está preparando a previsão" if is_weather else "Cadu está preparando a leitura"
		var spoken_text := value
		if not is_weather:
			var headline: String = str(draft.manchete).strip_edges()
			if not headline.ends_with(".") and not headline.ends_with("!") and not headline.ends_with("?"):
				headline += "."
			spoken_text = headline + "\n\n" + value
		draft["texto_narrado"] = spoken_text
		Narration.prepare.call_deferred(spoken_text, "thalita" if is_weather else "cadu")

func _voice_ready(payload: Dictionary) -> void:
	if phase != "voice":
		return
	var archive := draft.duplicate(true)
	archive["voice"] = payload.get("voice", "unavailable")
	archive["audio_seconds"] = payload.get("audio_seconds", 0)
	_archive(archive)
	draft.merge(payload)
	if draft.get("priority", false):
		queue.push_front(draft.duplicate(true))
	else:
		queue.append(draft.duplicate(true))
	phase = ""
	failures = 0
	status = "Quadro pronto com " + str(payload.get("voice", "voz indisponível"))
	story_ready.emit()
	if "--test-feed" in OS.get_cmdline_user_args():
		print("NEWS_FEED_OK ", JSON.stringify(archive))
		enabled = false

func take() -> Dictionary:
	if queue.is_empty():
		return {}
	return queue.pop_front()

func _fail(message: String) -> void:
	if draft.get("kind", "") == "weather":
		weather_requested = true
	phase = ""
	failures += 1
	retry_at = Time.get_ticks_msec() + mini(120, 10 * failures) * 1000
	status = message + "; nova tentativa em breve"
	push_warning(status)

func _archive(story: Dictionary) -> void:
	var path := "user://noticias-geradas.jsonl"
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(story))
	else:
		push_warning("Não foi possível salvar o arquivo de notícias")

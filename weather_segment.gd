extends RefCounted
## Map data only. All spoken weather text is written by the configured LLM.
const DISTRICTS := ["Alto do Cedro", "Vila das Antenas", "Centro", "Jardim da Represa"]
const CONDITIONS := ["sol entre nuvens", "céu nublado", "chuva passageira"]

static func create() -> Dictionary:
	var districts: Array[Dictionary] = []
	var baseline := randi_range(23, 29)
	for district in DISTRICTS:
		districts.append({"name": district, "temperature": baseline + randi_range(-3, 3), "condition": randi_range(0, 2)})
	return {"kind": "weather", "editoria": "TEMPO LOCAL", "manchete": "Previsão para Santa Irene", "resumo": "", "texto": "", "districts": districts, "low": baseline - 7, "high": baseline + 3}

static func prompt(story: Dictionary) -> String:
	var data := "Dados do mapa de Santa Irene:\n"
	for district in story.districts:
		data += "%s: %d graus, %s.\n" % [district.name, district.temperature, CONDITIONS[int(district.condition)]]
	data += "Amanhã: mínima %d, máxima %d graus.\n" % [story.low, story.high]
	return data + "Escreva a fala completa de Helena Duarte, apresentadora do tempo, em aproximadamente 120 palavras. Use os dados do mapa como referência. Invente fenômenos meteorológicos impossíveis, detalhes desconcertantes e uma despedida estranha, com tranquilidade absoluta. Apenas o que ela vai falar, sem título, lista, rubricas ou explicações."

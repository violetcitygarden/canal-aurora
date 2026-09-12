extends RefCounted

const DISTRICTS := ["Alto do Cedro", "Vila das Antenas", "Centro", "Jardim da Represa"]
const CONDITIONS := ["sol entre nuvens", "céu nublado", "chuva passageira"]
const ODDITIES := [
	"A chuva vai começar dentro das casas e, se houver tempo, sair para a rua. Não é necessário abrir a porta.",
	"A neblina de hoje contém algumas pessoas de terça-feira. Elas não precisam de informações. Já sabem o caminho.",
	"A sombra da caixa d'água chegou antes da caixa d'água. Pedimos aos moradores que não comentem a diferença de horário.",
	"Na represa, a água continua reconhecendo os moradores pelo primeiro nome. Quem mudou de nome deve evitar corrigir a água.",
	"Às seis e doze, todas as janelas mostrarão a mesma cozinha. A pessoa sentada à mesa não faz parte da previsão.",
	"O vento trará uma voz conhecida. Ela vai perguntar se você já almoçou. A orientação continua sendo dizer que sim.",
	"A umidade será maior nos quartos em que ninguém dorme. As camas desses quartos já foram avisadas.",
	"A máxima de amanhã foi observada no rosto de um senhor que não quis se identificar. O termômetro pediu para ficar com ele.",
	"Uma segunda lua será visível entre os prédios. É a menor, aquela que parece estar esperando alguma coisa.",
	"A frente fria tem a altura exata da sua mãe. Isso não altera a temperatura, mas dificulta a despedida.",
	"O céu ficará baixo o suficiente para ouvir a televisão dos vizinhos. Não aumente o volume. O céu está acompanhando.",
	"O último ônibus vai chover por dentro, mesmo sem passageiros. A empresa considera essa uma forma de ocupação.",
	"As nuvens permanecerão imóveis enquanto alguém estiver contando. Se perder a conta, comece de onde elas mandarem.",
	"O sol deve se pôr atrás de uma casa que ainda não foi construída. O terreno já está escuro.",
	"Amanhã terá o mesmo cheiro de um domingo da sua infância. As medições confirmam que não era domingo.",
	"Há previsão de uma porta no meio da chuva. Ela abre para o mesmo lugar, mas com os móveis um pouco mais perto."
]
const LOCAL_DETAILS := ["A sensação térmica será de estar sendo esperado.", "Há uma pequena chance de ontem no fim da tarde.", "A temperatura cai quando se pronuncia o nome do bairro.", "A chuva só aparece no reflexo das poças.", "O céu está limpo, mas ainda não está vazio.", "Os guarda-chuvas devem permanecer fechados quando ouvirem o próprio nome."]
const SIGNOFFS := ["Eu continuo aqui depois que a imagem muda. Boa noite.", "Se me encontrarem amanhã, eu ainda não vou saber desta previsão. Boa noite.", "Da próxima vez, talvez o mapa esteja do outro lado. Voltamos ao jornal.", "O Augusto acredita que este quadro já terminou. Vamos respeitar.", "Era isso que eu tinha permissão para chamar de tempo. Boa noite.", "Não guardem a minha voz junto das outras. Até a próxima."]
static var last_oddity := -1

static func create() -> Dictionary:
	var districts: Array[Dictionary] = []
	var text := "Boa noite. Eu sou Helena Duarte, e esta é a previsão para Santa Irene. "
	var baseline := randi_range(23, 29)
	var strange_district := randi_range(0, DISTRICTS.size() - 1)
	for district in DISTRICTS:
		var temperature := baseline + randi_range(-3, 3)
		var condition := randi_range(0, 2)
		districts.append({"name": district, "temperature": temperature, "condition": condition})
		text += "Em %s, %s, com %d graus. " % [district, CONDITIONS[condition], temperature]
		if districts.size() - 1 == strange_district:
			text += str(LOCAL_DETAILS.pick_random()) + " "
	var oddity_index := randi_range(0, ODDITIES.size() - (2 if last_oddity >= 0 else 1))
	if oddity_index >= last_oddity and last_oddity >= 0:
		oddity_index += 1
	last_oddity = oddity_index
	var oddity: String = ODDITIES[oddity_index]
	var low := baseline - 7
	var high := baseline + 3
	text += "Amanhã, mínima de %d e máxima de %d graus. %s %s" % [low, high, oddity, SIGNOFFS.pick_random()]
	return {"kind": "weather", "editoria": "TEMPO LOCAL", "manchete": "Previsão para Santa Irene", "resumo": oddity, "texto": text, "districts": districts, "low": low, "high": high, "model": "procedural", "generated_at": Time.get_datetime_string_from_system()}

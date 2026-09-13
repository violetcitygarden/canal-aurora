# Pensão Nair — MVP

## Treino da voz da Nair

O notebook [`treino_nair_colab.ipynb`](treino_nair_colab.ipynb) abre no Google Colab e conduz o fine-tuning com GPU, checkpoints no Drive e exportação ONNX. Abra diretamente no Colab: https://colab.research.google.com/github/violetcitygarden/canal-aurora/blob/main/pensao/treino_nair_colab.ipynb

Projeto Godot 4.4+ independente, dentro desta pasta apenas para facilitar a entrega no mesmo repositório. Abra `pensao/project.godot` ou dê dois cliques em `INICIAR-PENSAO.bat`. O jornal não carrega a pensão (a pasta possui `.gdignore`). Você pode copiar esta pasta para outro lugar e colocar nela `godot-path.txt` com o caminho do Godot.

## Primeira execução no Windows

1. Instale Python 3.10 ou superior e Godot 4.4+.
2. Use `INICIAR-PENSAO.bat`. Ele cria `.venv` própria, instala as dependências, baixa os modelos necessários e abre o projeto. O `godot-path.txt` da pasta do jornal é aceito se não houver um local.
3. Todas as conversas, inclusive a primeira, são geradas pelo Ollama, com o modelo de `config.json` (por padrão, o mesmo BRD local já usado no canal). O programa inicia o Ollama se encontrá-lo instalado, mas não instala nem importa o modelo.
4. A primeira preparação de áudio pode levar alguns minutos. Downloads e vozes são reaproveitados nas próximas execuções. O terminal mostra o progresso; a janela só abre quando a primeira conversa e todos os seus áudios estão prontos.

Para demonstração com duas conversas fixas, executadas uma vez, sem depender de Ollama: `INICIAR-PENSAO.bat -Demo`. As vozes femininas ainda precisam de internet na primeira síntese de cada fala.

## Controles

- Espaço: pausar/retomar fala, risada e movimentação.
- C: alternar as três câmeras fixas.
- V: ligar/desligar o tratamento VHS.
- H: mostrar ajuda.
- F11: tela cheia.

## O que está implementado

Cozinha brasileira com azulejo esverdeado, piso antigo, mesa de fórmica, filtro de barro, fogão com panela, geladeira com bilhete, cortina, relógio e samambaia pendurada. Quatro personagens com rostos, roupas e silhuetas distintas: Dona Nair, Valdir, Jéssica e Mauro. Resolução 320×240 ampliada, filtro nearest, vértices quantizados, cores reduzidas, ruído, desalinhamento de cor e faixa de tracking VHS.

Os personagens percorrem pontos em volta da mesa, param, giram em passos e caminham em poses de 10 fps. Os trajetos são deliberadamente mecânicos. As câmeras são sorteadas entre planos fixos. Falas têm pausas variadas e, ocasionalmente, silêncio mais longo.

`config.json` contém o prompt completo, o modelo, o endpoint, a temperatura e `laugh_probability`. A risada é **somente um sorteio por fala**: não há classificador, detecção de piada, análise semântica ou marcação pelo modelo. `0.30` é 30% de chance; `0` desliga; `1` ri após todas as falas. O sorteio não garante uma cota por cena. A próxima fala espera a risada terminar.

As risadas são os arquivos MP3 ou WAV com nome começando em `laugh` na pasta `audio/`, carregados diretamente e sorteados após as falas. Os três MP3s adicionados ao projeto já são usados. Para trocar ou acrescentar risadas, use esse prefixo e reinicie. Os demais efeitos não entram no sorteio. Não há geração de plateia sintética; os antigos `cache/laugh_*.wav` não são usados. A probabilidade continua definida em `config.json`, sem análise do diálogo.

`audio/ambiencia1.mp3` toca em loop com volume de fundo (`ambience_volume_db: -20` em `config.json`). `creaking_door.mp3` acompanha a entrada ou a aproximação da porta na saída; `close_door.mp3` toca ao concluir a passagem, esperando o rangido terminar. O volume da porta é `door_volume_db: -14`. Espaço pausa e retoma esses sons junto com a cena. Reinicie pelo BAT após alterar os volumes ou arquivos.

Entradas pela porta recebem um crédito de 3,2 segundos com o nome do personagem em amarelo inclinado, contorno roxo, sombra rosa e animação lateral, renderizado na resolução da TV com VHS. Uma câmera dedicada acompanha a chegada com zoom leve e depois devolve o plano normal. C encerra esse enquadramento; Espaço pausa também a animação.

`audio/jingle.mp3` toca inteiro em cada entrada (`entrance_jingle_volume_db: -12`). A fala começa no segundo 9 do áudio, com o restante do jingle tocando por baixo. Se a caminhada ainda estiver em andamento, a fala aguarda sua conclusão. Sem jingle disponível, basta concluir a caminhada. Saídas não recebem crédito nem jingle. O log registra `PENSAO_ENTRANCE_JINGLE` e `PENSAO_ENTRANCE_SPEECH`.

O lançador abre o jogo diretamente, sem executar o editor/importador antes. Cenas e shaders são recursos nativos; texturas, risadas e falas são carregadas diretamente, permitindo abrir mesmo sem cache de importação. `cache/.gdignore` impede o editor de importar os áudios temporários e modelos quando o projeto é aberto para edição.

## Vozes e geração

- Nair: Piper local, modelo `pt_BR-nair-medium.zip` fornecido pelo usuário. Extraído automaticamente para `cache/models`, com os mesmos parâmetros da amostra aprovada. O cache da Nair tem uma versão própria para não reutilizar a Francisca antiga.
- Jéssica: Microsoft Thalita, via Edge TTS.
- Valdir: Piper Faber, CPU local.
- Mauro: Piper Jeff, CPU local.

Piper: modelos de https://huggingface.co/rhasspy/piper-voices/tree/main/pt/pt_BR. Modelos do jornal são reutilizados quando já existem; caso contrário, a pensão baixa seus próprios. As falas femininas são enviadas ao serviço Edge TTS pela internet. O diálogo é escrito pelo Ollama local. O servidor da pensão usa apenas loopback, em uma porta livre entre 11450 e 11460, e é encerrado pelo lançador ao fechar o Godot.

A geração pede 4–6 falas por trecho, com personagens respondendo uns aos outros. O experimento atual pede punchlines em toda fala e passivo-agressividade extrema, preservando o cotidiano e a continuidade. A configuração anterior e a versão exagerada estão salvas em [`prompt_presets/`](prompt_presets/README.md), com instruções para alternar. Respostas inválidas recebem nova tentativa; não são anunciadas como uma cena pronta. Entre cenas, só é enviado o assunto anterior como contexto, sem copiar as falas. Durante a mesma cena, o segundo trecho recebe o primeiro para continuar a conversa. A fila prepara até duas cenas enquanto a atual toca.

Se uma voz falhar, o erro é registrado e a fala aparece com legenda e aviso de áudio indisponível. Se o Ollama falhar, a cozinha continua animada enquanto tenta novamente. As falas originais são arquivadas em `cache/dialogues.jsonl`; áudio e logs ficam em `cache/`, fora do Git. Esse cache cresce durante uso prolongado e pode ser apagado com a aplicação fechada.

## Validação

- `python tests/test_dialogue.py`: parser, participantes e rejeição de monólogos.
- Com `python server.py --demo --port 11450` aberto: `godot --headless --path . --script res://tests/playback.gd` testa HTTP, reprodução real, movimento labial, risadas sem sobreposição, pausa e distribuição probabilística.
- `godot --path . -- --capture` salva uma captura em `/tmp/pensao-preview.png` (opção de desenvolvimento para Linux).

As texturas CC0 baixadas e suas transformações estão descritas em `assets/SOURCES.md`.

## Presença, câmeras e preparação antecipada

A cena inicial sorteia dois moradores e gera uma conversa nova. Na geração contínua, o servidor mantém quem ficou na cozinha e planeja uma entrada ou saída no meio da próxima cena. O prompt informa presentes e ausentes em cada trecho. O servidor gera dois trechos com listas de presentes separadas e insere a movimentação entre eles. O modelo não precisa escrever marcações ENTRA/SAI. Falas de ausentes e formatos inválidos recebem uma nova tentativa antes da síntese. Os moradores podem mencionar quem está fora; o modelo é orientado a reconhecer chegadas e despedidas. O modo Demo executa suas duas cenas fixas uma vez e termina com um aviso; a tela identifica esse modo como DEMO.

O Godot espera a caminhada de entrada/saída terminar antes da fala seguinte. Além dos planos gerais, sorteia closes de rosto, câmera baixa inclinada e um plano sobre o fogão por 2–5 segundos, voltando ao plano aberto. O lado do close fica fixo durante o plano e o acompanhamento é suavizado, sem orbitar junto com os giros bruscos do personagem. C continua alternando os planos gerais.

Os caminhos contornam a mesa e são recalculados ao encontrar outro morador, com espaço para passar sem sobreposição. Entradas/saídas têm limite de 25 segundos: em caso de bloqueio persistente, uma saída é concluída com um corte e uma chegada termina na posição alcançada, liberando a próxima fala. Após seis segundos de caminhada, a tela informa quem está sendo aguardado.

## Diagnóstico de interrupções

Cada abertura pelo BAT salva `cache/player-AAAAmmdd-HHMMSS-PORTA.log`, cujo caminho aparece no terminal. Ele registra mudanças de estado e um resumo a cada dez segundos: cena/fala atual, pausa, reprodução de voz/risada, próxima cena preparada e personagem em deslocamento. `PENSAO_MOVE_REPLAN` identifica desvios; `PENSAO_MOVE_END recovered=true` identifica uma caminhada encerrada pelo limite de tempo. `PENSAO_VOICE` registra a duração do áudio; `PENSAO_VOICE_MISSING` indica uso de legenda sem voz. O log também inclui progresso da geração e erros HTTP.

Os detalhes do servidor continuam em `cache/server-PORTA-error.log`, e os textos em `cache/dialogues.jsonl`. Para investigar uma interrupção, preserve o log `player` da sessão e o log do servidor antes de reabrir: o primeiro tem nome por sessão, mas o segundo é substituído ao reutilizar a porta.

`godot --headless --path pensao --script res://tests/traffic.gd`, a partir do repositório, verifica encontro de frente, desvio de uma pessoa parada e retomada da fala após uma transição impossível, preservando a próxima cena preparada.

O servidor prepara cenas enquanto a atual toca, com até quatro tarefas de áudio e um bloqueio por personagem para preservar os modelos e arquivos. O player também busca antecipadamente uma próxima cena. Isso reduz intervalos, mas a geração local ou serviços de voz lentos ainda podem esvaziar a fila. Durante espera, a tela exibe a etapa de geração, progresso de áudio ou erro recebido; os detalhes ficam nos logs `cache/server-PORTA-error.log`. Nenhuma conversa repetida é inserida automaticamente para esconder falhas.

Testes adicionais: `python tests/test_dialogue.py` verifica presença, transições e concorrência das vozes; `godot --headless --path . --script res://tests/staging.gd` verifica entrada/saída, instante da fala, prefetch e câmeras.

## Controle de repetição

Antes de sintetizar áudio, o servidor compara as respostas com até 100 falas anteriores e com o trecho atual. Rejeita blocos de frases curtas recicladas, repetições internas e falas longas muito semelhantes. Respostas breves naturais, como “tá bom”, continuam permitidas. Após duas tentativas de diálogo completo, o servidor recupera o formato gerando quatro falas individuais, com personagens escolhidos pelo programa. A validação de repetição continua ativa. Se a recuperação falhar, o erro é exibido e uma nova cena é tentada. Os assuntos percorrem uma lista embaralhada antes de serem reutilizados. Esse filtro detecta repetição textual, mas não garante originalidade semântica de um modelo pequeno.

A abertura normal não usa roteiro fixo. O lançador aguarda até dez minutos pela primeira conversa com áudio e mostra o progresso no terminal. O modo `-Demo` continua disponível explicitamente para as duas cenas de teste. Respostas rejeitadas do modelo são registradas em `cache/generation-rejected.jsonl` para diagnóstico; erros antigos são limpos ao começar nova tentativa.

## Tamanho das falas

O prompt prefere 5–12 palavras, mas o tamanho não rejeita mais a resposta nem pede reescrita ao modelo. Textos longos são divididos localmente em blocos de até 18 palavras/110 caracteres, priorizando finais de frase e preservando todas as palavras. Cada bloco tem seu áudio; continuações recebem pausa curta e só o último bloco sorteia a risada. A entrada/saída permanece antes do primeiro bloco correspondente. Isso elimina novas chamadas ao escritor por comprimento, embora textos extensos ainda exijam mais síntese de voz. `short_line_words` e `short_line_chars` controlam a divisão.

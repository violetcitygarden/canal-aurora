# Pensão Nair — MVP

Projeto Godot 4.4+ independente, dentro desta pasta apenas para facilitar a entrega no mesmo repositório. Abra `pensao/project.godot` ou dê dois cliques em `INICIAR-PENSAO.bat`. O jornal não carrega a pensão (a pasta possui `.gdignore`). Você pode copiar esta pasta para outro lugar e colocar nela `godot-path.txt` com o caminho do Godot.

## Primeira execução no Windows

1. Instale Python 3.10 ou superior e Godot 4.4+.
2. Use `INICIAR-PENSAO.bat`. Ele cria `.venv` própria, instala as dependências, baixa os modelos necessários e abre o projeto. O `godot-path.txt` da pasta do jornal é aceito se não houver um local.
3. A primeira conversa tem texto fixo de apresentação. As seguintes são geradas pelo Ollama, com o modelo de `config.json` (por padrão, o mesmo BRD local já usado no canal). O programa inicia o Ollama se encontrá-lo instalado, mas não instala nem importa o modelo.
4. A primeira preparação de áudio pode levar alguns minutos. Downloads e vozes são reaproveitados nas próximas execuções. Há mensagem na tela enquanto a conversa fica pronta.

Para demonstração com duas conversas fixas alternadas, sem depender de Ollama: `INICIAR-PENSAO.bat -Demo`. As vozes femininas ainda precisam de internet na primeira síntese de cada fala.

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

As risadas são os arquivos MP3 ou WAV da pasta `audio/`, carregados diretamente e sorteados após as falas. Os três MP3s adicionados ao projeto já são usados. Para trocar ou acrescentar gravações, coloque os arquivos nessa pasta e reinicie. Não há geração de plateia sintética; os antigos `cache/laugh_*.wav` não são usados. A probabilidade continua definida em `config.json`, sem análise do diálogo.

O lançador importa os recursos antes de abrir. As texturas da cozinha também são lidas diretamente dos PNGs, permitindo abrir o cenário mesmo sem cache de importação.

## Vozes e geração

- Nair: Microsoft Francisca, mais lenta e grave, via Edge TTS.
- Jéssica: Microsoft Thalita, via Edge TTS.
- Valdir: Piper Faber, CPU local.
- Mauro: Piper Jeff, CPU local.

Piper: modelos de https://huggingface.co/rhasspy/piper-voices/tree/main/pt/pt_BR. Modelos do jornal são reutilizados quando já existem; caso contrário, a pensão baixa seus próprios. As falas femininas são enviadas ao serviço Edge TTS pela internet. O diálogo é escrito pelo Ollama local. O servidor da pensão usa apenas loopback, em uma porta livre entre 11450 e 11460, e é encerrado pelo lançador ao fechar o Godot.

A geração pede 10–16 falas cotidianas, com personagens respondendo uns aos outros, sem surrealismo obrigatório nem instrução para produzir piadas. O parser aceita 6–20 falas válidas e pelo menos dois participantes. Respostas inválidas recebem nova tentativa; não são anunciadas como uma cena pronta. Uma pequena lembrança das últimas falas é enviada à próxima geração. A fila prepara até duas cenas enquanto a atual toca.

Se uma voz falhar, o erro é registrado e a fala aparece com legenda e aviso de áudio indisponível. Se o Ollama falhar, a cozinha continua animada enquanto tenta novamente. As falas originais são arquivadas em `cache/dialogues.jsonl`; áudio e logs ficam em `cache/`, fora do Git. Esse cache cresce durante uso prolongado e pode ser apagado com a aplicação fechada.

## Validação

- `python tests/test_dialogue.py`: parser, participantes e rejeição de monólogos.
- Com `python server.py --demo --port 11450` aberto: `godot --headless --path . --script res://tests/playback.gd` testa HTTP, reprodução real, movimento labial, risadas sem sobreposição, pausa e distribuição probabilística.
- `godot --path . -- --capture` salva uma captura em `/tmp/pensao-preview.png` (opção de desenvolvimento para Linux).

As texturas CC0 baixadas e suas transformações estão descritas em `assets/SOURCES.md`.

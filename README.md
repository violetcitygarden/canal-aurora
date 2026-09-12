# Canal Aurora
O projeto abre no jornal: estúdio 3D, apresentador low poly, bancada e faixa de manchete em 4:3.
Apresentador original Augusto (nome provisório): geometria facetada gerada em presenter.gd, terno, bigode, cabelo com têmporas grisalhas, gravata e microfone de lapela. Animação a 12 poses por segundo: respiração, olhos, piscadas assimétricas, cabeça e mão. Voz Cadu via Piper local na CPU; boca e mandíbula em três poses acompanham a intensidade do áudio, incluindo pausas. Não é sincronização por fonema.
F2 alterna entre jornal e previsão. No jornal: setas/espaço trocam a notícia; L mostra/esconde a faixa; R relê news.json; H mostra ajuda.
news.json separa editoria, manchete, resumo (linha de apoio) e texto (corpo completo). Textos longos são ajustados e abreviados visualmente sem modificar os dados. JSON inválido mantém a última notícia válida. As notícias geradas recebem narração; as notícias iniciais do JSON continuam sem voz.
Estúdio: studio.gd. Composição da faixa: news_overlay.gd. Cena: news.tscn.

## Redação local com BRD
O Cadu narra primeiro a manchete, com pontuação de fim de frase e separação de parágrafo, e depois o corpo da notícia. O campo `texto` continua contendo apenas o corpo; `texto_narrado` registra a sequência completa enviada à voz. A Helena continua lendo a previsão inteira gerada pelo modelo.
Inicie o Ollama antes de abrir o Godot. O projeto usa a API local 127.0.0.1:11434 e o modelo já importado canal-aurora-brd:1b-q4. Não inicia/instala o Ollama por conta própria.
Configuração em llm.json (reinicie o projeto após editar): modelo, endpoint, instrução, temperatura, contexto, limite do corpo e duração de cada notícia.
O modelo gera primeiro a manchete e depois o corpo, em pedidos independentes; o aplicativo monta os campos sem exigir JSON do modelo. Resumo é a primeira frase do corpo. Repetições e palavras estranhas são preservadas; o corpo é limitado a 350 tokens e a manchete a 64 tokens. A faixa pode abreviar títulos longos visualmente. As respostas originais ficam arquivadas.
A primeira notícia aparece quando texto e voz estiverem prontos. A transmissão automática espera a narração terminar e mais dois segundos antes de avançar, mantendo a notícia atual se a fila estiver vazia. Sem voz, usa o intervalo de 40 segundos. A redação prepara até duas notícias adiante, com um pedido de cada vez. Falhas do modelo recebem novas tentativas com espera progressiva de 10 a 120 segundos; a imagem continua funcionando com a notícia anterior. Cada pedido tem timeout de 90 segundos.
A = pausar/retomar troca automática; G = exibir próxima notícia pronta ou solicitar geração; T = abrir texto completo; cima/baixo = rolar o texto; H = status de geração/fila. A pausa de A afeta a exibição, a redação ainda completa sua fila limitada. Trocar para previsão mantém a redação ativa.
Arquivo de saída: %APPDATA%/Godot/app_userdata/Canal Aurora — Previsão Local/noticias-geradas.jsonl (uma notícia por linha, incluindo texto bruto, modelo, data e duração da narração). Ao fechar o Godot, os pedidos pendentes são cancelados pelo cliente e o modelo expira no Ollama após o keep_alive de 5 minutos; os serviços Ollama e Piper permanecem disponíveis.

## Iniciar com voz
Para abrir tudo sem o Codex, dê dois cliques em `ABRIR-CANAL.bat`. Ele inicia o servidor Cadu/Thalita, inicia o Ollama se estiver fechado e abre o Godot no jornal. Uma janela de terminal pode permanecer aberta enquanto o canal estiver rodando; ela é o lançador. Feche o Godot pela janela ou pressione Alt+F4.

O quadro Tempo Local aparece em intervalos sorteados de 12 a 22 notícias. W solicita uma previsão manualmente. Helena usa Thalita e o mapa mantém os bairros fixos. `weather_segment.gd` sorteia apenas os dados do mapa e monta o contexto; o BRD escreve toda a fala, incluindo as anomalias e a despedida. O prompt específico está em `weather_system` e o limite em `weather_tokens`, no `llm.json`. A resposta é narrada sem reescrita, mesmo se o modelo repetir palavras ou divergir do mapa. Falhas de geração recebem novas tentativas, sem recorrer a textos prontos. O gerador autoral anterior está preservado em `archive/helena-previsoes-autorais-2026-09-12.gd` e não é usado pelo programa nem incluído no prompt. T mostra o texto durante o tempo.

A trilha `music/tempo.mp3` toca exclusivamente durante a Helena, com troca gradual entre ela e a música do jornal. A música do jornal alterna blocos de 42–78 segundos tocando e 28–58 segundos em silêncio, para não ficar constante; a trilha da Helena fica sempre presente. M silencia ambas, e o volume baixa durante as falas e pausas constrangedoras. A voz escolhida é Thalita (`pt-BR-ThalitaMultilingualNeural`), com os mesmos parâmetros da amostra 2. O serviço usa edge-tts e internet para gerar sua fala, e FFmpeg converte para WAV; a boca usa a intensidade do áudio, como a do Cadu. Se a geração falhar, o quadro aparece sem voz. Cadu continua usando Piper local. As amostras estão em `voice_samples/weather_auditions`. `--start-weather` força o tempo apenas quando passado explicitamente; o lançador normal abre com o jornal.

Entre notícias, uma vinheta de aproximadamente dois segundos exibe a logo dourada em voo, globo de linhas e fundo azul (`transition.gd`). Usa `music/transition.mp3`. A trilha `music/newsreportmusic.mp3` inicia automaticamente em loop e baixa durante a fala e a vinheta; arrastar outro áudio substitui a trilha nesta sessão.

Depois da vinheta, 28% das leituras têm uma pausa de 3,5 a 6,5 segundos com música quase inaudível e apresentador em repouso. As demais começam em 0,3 a 0,8 segundo. A troca automática aguarda essas etapas e a narração. As pautas combinam serviços municipais e acontecimentos impossíveis, com humor seco; o modelo fraco pode ignorar instruções e suas repetições continuam preservadas.

Execute `powershell -ExecutionPolicy Bypass -File .\start_channel.ps1` nesta pasta. O lançador inicia o Piper e o Ollama quando necessário e abre o jornal. Para rodar pelo editor, mantenha `voice_samples/server.py` executando com `.venv-voice/Scripts/python.exe`. O serviço escuta apenas em 127.0.0.1:11436. Modelo em `voice_samples/models/pt_BR-cadu-medium.onnx`. V silencia a voz; M controla a música. A música baixa durante a fala. Falha na síntese exibe a notícia sem voz, preservando seu texto. Setas interrompem a fala atual e reproduzem a notícia escolhida. O áudio é mantido apenas na memória da sessão.

Protótipo artístico para Godot 4.4 ou superior. Dados fictícios; geração por IA local.
Abra project.godot no Godot e pressione F6/F5.

Três telas em ciclo de 14 segundos, proporção 4:3, relógio ficcional a partir de 17/09/1993 às 18h42, rodapé contínuo e ícones desenhados no Godot.
Não acompanha gravações ou músicas do TWC. Arraste um arquivo MP3/OGG/WAV seu sobre a janela para reproduzi-lo em loop. O áudio é temporário, não copiado ao projeto.

Teclas: setas/espaço = trocar tela; P = pausar ciclo; C = textura de TV; H = ajuda; M = silenciar; F11 = tela cheia; Esc = sair da tela cheia.
Edite weather.json para mudar a cidade, as temperaturas, os boletins e o rodapé. Reinicie a execução depois da edição.
Design e desenho: main.gd. Cena de entrada: main.tscn.
A fonte usa Arial instalada no sistema, com fallback; nenhuma fonte comercial é redistribuída.
A transmissão começa sem interface de configuração na tela. H revela os controles.

# Amostras de voz do Augusto

Três vozes brasileiras Piper (Cadu, Faber, Jeff), com o mesmo texto em texto.txt. WAV mono PCM 16-bit, 22050 Hz. Nenhuma voz escolhida ou ligada ao jornal ainda.

Geradas localmente em CPU com Piper 1.8.0, ONNX Runtime 1.30.0, Python 3.12 no ambiente ../.venv-voice. Reproduzir: executar generate.py com esse Python. Parâmetros iguais: length_scale=1.08, noise_scale=0.667, noise_w_scale=0.8, normalize_audio=True. Durações variam pela cadência de cada voz.

results.json registra carregamento, primeira síntese, síntese aquecida, duração do áudio e hash de cada modelo. Medições pontuais com os aplicativos atuais em execução; não é benchmark isolado. Cada WAV foi validado quanto a duração e sinal não silencioso. A qualidade subjetiva e a pronúncia ficam para a escolha do usuário.

Modelos e cartões: https://huggingface.co/rhasspy/piper-voices/tree/main/pt/pt_BR — cartões individuais copiados em models; datasets declarados CC0. Motor Piper: https://github.com/OHF-Voice/piper1-gpl (GPL-3.0).

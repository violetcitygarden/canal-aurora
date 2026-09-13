"""Text-only, identical-prompt comparison. Does not change sitcom config."""
import json
import time
import subprocess
import urllib.request
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent
CONFIG = json.loads((ROOT / 'config.json').read_text(encoding='utf-8'))
OUT = ROOT / 'cache' / ('comparison-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
MODELS = ['llama3.2:3b-instruct-q4_K_M', 'qwen3:4b-instruct-2507-q4_K_M']
SYSTEM = CONFIG['system'] + '\nPresentes nesta parte: JESSICA, VALDIR. Ausentes: NAIR, MAURO. Somente os presentes podem falar. Não escreva ENTRA, SAI ou rubricas. Escreva de 4 a 6 falas curtas, com pelo menos dois presentes respondendo um ao outro. Ninguém entra ou sai neste trecho. Prefira uma frase direta de 5 a 12 palavras, sem explicações adicionais.'
PROMPTS = [
    'Assunto: a compra do detergente. Situação: Jéssica comprou o detergente e quer dividir o valor com Valdir. Valdir diz que não deve pagar porque nunca lava a louça. Comece a conversa. Apenas NOME: fala.',
    'Assunto: a compra do detergente. Continue exatamente desta conversa, sem reiniciar:\nJESSICA: O detergente deu quatro reais para cada um.\nVALDIR: Eu não uso detergente.\nJESSICA: Porque você não lava nada.\nVALDIR: Então você sabe que eu não uso.\nAgora Jéssica propõe uma solução prática. Valdir tenta escapar da obrigação. Apenas NOME: fala.',
    'Assunto: um pote sem nome na geladeira. Jéssica precisa guardar o almoço de amanhã. Valdir ocupou a prateleira com três panelas vazias para reservar lugar. Jéssica quer que ele tire as panelas. Valdir quer manter o espaço. Comece a conversa. Apenas NOME: fala.'
]

def api(path, payload=None, timeout=300):
    request = urllib.request.Request('http://127.0.0.1:11434/api/' + path,
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)

def gpu():
    return subprocess.check_output(['nvidia-smi', '--query-gpu=memory.used,memory.total,utilization.gpu', '--format=csv,noheader,nounits'], text=True).strip()

def main():
    OUT.mkdir(parents=True)
    settings = {'temperature': CONFIG['temperature'], 'num_ctx': 2048, 'num_predict': 450,
                'repeat_penalty': 1.15, 'repeat_last_n': 256, 'seed': 42}
    (OUT / 'inputs.json').write_text(json.dumps({'system': SYSTEM, 'prompts': PROMPTS, 'options': settings}, ensure_ascii=False, indent=2), encoding='utf-8')
    results = []
    print('OUTPUT ' + str(OUT), flush=True)
    for model in MODELS:
        deadline = time.monotonic() + 900
        while model not in [item['name'] for item in api('tags')['models']]:
            if time.monotonic() > deadline:
                raise TimeoutError('Download ainda indisponível: ' + model)
            time.sleep(5)
        for active in api('ps')['models']:
            api('generate', {'model': active['name'], 'keep_alive': 0})
        for index, prompt in enumerate(PROMPTS):
            before = gpu()
            started = time.perf_counter()
            response = api('generate', {'model': model, 'system': SYSTEM, 'prompt': prompt,
                'stream': False, 'keep_alive': '5m', 'options': settings})
            seconds = time.perf_counter() - started
            words = len(response.get('response', '').split())
            lines = [line for line in response.get('response','').splitlines() if line.strip()]
            row = {'model': model, 'case': index + 1, 'wall_seconds': round(seconds, 2),
                'tokens_per_second': round(response.get('eval_count', 0) / max(response.get('eval_duration', 1) / 1e9, .001), 2),
                'load_seconds': round(response.get('load_duration', 0) / 1e9, 2),
                'estimated_speech_seconds_fast': round(words / 3 + len(lines) * 1.1, 1),
                'estimated_speech_seconds_slow': round(words / 2 + len(lines) * 1.1, 1),
                'gpu_before_mib': before, 'gpu_after_mib': gpu(), 'allocation': api('ps'),
                'raw_response': response}
            results.append(row)
            (OUT / 'results.json').write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
            print(json.dumps(row, ensure_ascii=False), flush=True)
        api('generate', {'model': model, 'keep_alive': 0})
    blocks = ['# Comparação Pensão Nair\n\nRespostas integrais, sem edição. Mesmos prompts e parâmetros. Contexto 2048. A primeira rodada inclui carregamento; demais com modelo carregado. Tempos de fala são estimativas de 120–180 palavras/minuto mais 1,1 s por fala, sem síntese, risadas ou movimento.\n']
    for row in results:
        blocks.append(f"## {row['model']} — caso {row['case']}\n\n{row['wall_seconds']} s; {row['tokens_per_second']} tokens/s.\n\n```text\n{row['raw_response'].get('response','')}\n```\n")
    (OUT / 'comparacao.md').write_text('\n'.join(blocks), encoding='utf-8')

if __name__ == '__main__':
    main()

"""Prepare real Piper Jeff speech for the standalone reporter preview."""
import hashlib
import json
from pathlib import Path
from generate import download

ROOT = Path(__file__).resolve().parent
TEXTS = [
    'Boa tarde. Eu estou no centro de Santa Irene, onde os moradores aguardam a reabertura desta rua. '
    'Segundo a prefeitura, a obra terminou ontem, mas a segunda-feira ainda não autorizou a passagem. '
    'Os comerciantes pedem uma solução antes do próximo fim de semana. Do centro, para o Jornal Aurora.',
    'Boa tarde. Nós estamos na zona rural de Santa Irene. Aqui, os produtores perceberam que a cerca '
    'avançou três metros durante a madrugada. Ninguém viu o deslocamento, mas as vacas já solicitaram '
    'a atualização do endereço. A prefeitura prometeu enviar um fiscal. Do campo, para o Jornal Aurora.',
    'Boa noite. Deste mirante, nós acompanhamos as luzes de Santa Irene. Hoje, um dos prédios '
    'acendeu suas janelas com quinze minutos de antecedência. A companhia de energia informou que '
    'a diferença será descontada da próxima noite. Nós seguimos acompanhando. De volta ao estúdio.'
]

def main():
    models = ROOT / 'models'
    models.mkdir(exist_ok=True)
    base = 'https://huggingface.co/rhasspy/piper-voices/resolve/main/pt/pt_BR/jeff/medium'
    for suffix in ['.onnx', '.onnx.json']:
        name = 'pt_BR-jeff-medium' + suffix
        print('Conferindo modelo Jeff: ' + name, flush=True)
        download(base + '/' + name, models / name)
    from server import synthesize
    output = ROOT / 'reporter_preview'
    output.mkdir(exist_ok=True)
    for index, text in enumerate(TEXTS):
        target = output / f'{index}.json'
        signature = hashlib.sha256(('jeff-v1:' + text).encode()).hexdigest()
        if target.exists():
            try:
                cached = json.loads(target.read_text(encoding='utf-8'))
                if cached.get('signature') == signature and cached.get('voice') == 'jeff' and cached.get('wav'):
                    continue
            except (ValueError, OSError):
                pass
        print(f'Jeff preparando fala {index + 1}/3...', flush=True)
        payload = synthesize(text, 'jeff')
        payload.update(text=text, signature=signature)
        temporary = target.with_suffix('.tmp')
        temporary.write_text(json.dumps(payload, ensure_ascii=False), encoding='utf-8')
        temporary.replace(target)
    print('Tres falas do Jeff prontas.', flush=True)

if __name__ == '__main__':
    main()

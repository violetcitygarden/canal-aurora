"""Bounded continuity from dialogue, without an extra model request."""
import json
from pathlib import Path

PERSONAL_TOPICS = [
    'perguntar a alguém como foi seu último encontro',
    'perguntar por uma pessoa da família e ouvir a resposta',
    'um antigo relacionamento e o que ficou daquela época',
    'um convite para sair e a insegurança de aceitar',
    'como alguém veio morar na pensão',
    'uma amizade antiga que anda distante',
    'um plano pessoal para o futuro que alguém nunca contou',
    'retomar uma informação pessoal já contada, perguntando como ficou',
]

def load_memory(path):
    try:
        data = json.loads(Path(path).read_text(encoding='utf-8'))
        return [item for item in data if isinstance(item, dict)
                and isinstance(item.get('lines'), list)][-20:]
    except (OSError, ValueError, TypeError):
        return []

def context(memory):
    excerpts = []
    for scene in memory[-8:]:
        for line in scene['lines']:
            if isinstance(line, dict):
                excerpts.append(f"{line.get('speaker', '')}: {line.get('text', '')}")
    return ('CONTINUIDADE PESSOAL: os trechos abaixo são relatos anteriores, não novas falas. '
            'Respeite nomes, vínculos e acontecimentos já estabelecidos. Não transforme '
            'boatos em fatos nem invente parentescos entre os moradores. Se perguntarem '
            'sobre a vida de alguém, essa pessoa responde e os outros reagem. '
            'Revele no máximo um detalhe novo por cena, em falas curtas. '
            'Romance só entre adultos. Não force casal, exposição ou confissão.\n'
            + '\n'.join(excerpts)[-6000:])

def save_delivered(path, scene):
    if not scene.get('personal'): return
    path = Path(path)
    memory = load_memory(path)
    memory.append({'lines': [{'speaker': line['speaker'], 'text': line['text']}
                             for line in scene['lines']]})
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(memory[-20:], ensure_ascii=False, indent=2), encoding='utf-8')
    temporary.replace(path)

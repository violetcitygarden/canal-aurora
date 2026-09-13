"""Independent sitcom writer and voice preparation service. Localhost only."""
import truststore
truststore.inject_into_ssl()

from concurrent.futures import ThreadPoolExecutor
from collections import deque
from difflib import SequenceMatcher
import unicodedata
import argparse
import asyncio
import base64
import hashlib
import io
import json
import logging
import queue
import random
import re
import subprocess
import threading
import time
import urllib.request
import wave
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = ROOT / 'cache'
MODELS = CACHE / 'models'
CONFIG = json.loads((ROOT / 'config.json').read_text(encoding='utf-8'))
IDS = ('NAIR', 'VALDIR', 'JESSICA', 'MAURO')
TOPICS = ['um pote sem nome na geladeira', 'a divisão da conta do gás', 'uma cadeira que mudou de lugar',
          'roupa esquecida no varal', 'o horário de usar o liquidificador', 'alguém deixou uma colher dentro do açúcar',
          'quem ficou com a chave da lavanderia', 'um carregador emprestado', 'a compra do detergente',
          'a vez de limpar o fogão', 'um visitante que tomou café sem avisar', 'a organização da prateleira']
DEMO = [
    ('NAIR', 'Quem colocou esse pote na minha prateleira?'),
    ('JESSICA', 'A senhora falou que a prateleira do meio era de todo mundo.'),
    ('NAIR', 'Era. Eu coloquei uma etiqueta ontem.'),
    ('VALDIR', 'A etiqueta está atrás do pote.'),
    ('NAIR', 'Então você viu.'),
    ('JESSICA', 'Eu só preciso guardar o almoço de amanhã.'),
    ('VALDIR', 'Na minha época a gente guardava sem precisar marcar reunião.'),
    ('JESSICA', 'O senhor tem três panelas vazias lá dentro.'),
    ('VALDIR', 'Estou guardando o lugar.'),
    ('NAIR', 'Panela vazia pode ficar no quarto.'),
    ('VALDIR', 'No quarto a senhora cobra por móvel.'),
    ('NAIR', 'Cobrarei pela geladeira também se continuar essa conversa.')
]
DEMO_TWO = [
    ('MAURO', 'Pensei numa forma de baratear o café da casa.'),
    ('JESSICA', 'Comprar o pacote maior?'),
    ('MAURO', 'Um plano mensal. Cada um paga uma quantia fixa.'),
    ('NAIR', 'O café já está no aluguel.'),
    ('MAURO', 'Esse seria um café complementar.'),
    ('JESSICA', 'É o mesmo café dessa garrafa?'),
    ('MAURO', 'Inicialmente.'),
    ('NAIR', 'Inicialmente você vai lavar a garrafa.'),
    ('MAURO', 'Posso descontar o serviço da mensalidade?'),
    ('JESSICA', 'Você acabou de inventar uma conta para dever dinheiro para si mesmo.')
]
PIPER = {}
VOICE_FAILURES = {}
SCENES = queue.Queue(maxsize=2)
STATUS = {'status': 'Preparando vozes', 'ready': False, 'error': ''}
STOP = threading.Event()
VOICE_LOCKS = {speaker: threading.Lock() for speaker in IDS}
POOL = ThreadPoolExecutor(max_workers=4)


def fetch_json(url, payload=None, timeout=90):
    body = json.dumps(payload, ensure_ascii=False).encode() if payload is not None else None
    request = urllib.request.Request(url, data=body, headers={'Content-Type': 'application/json', 'User-Agent': 'PensaoNair/1.0'})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.load(response)


def ensure_model(name):
    MODELS.mkdir(parents=True, exist_ok=True)
    stem = f'pt_BR-{name}-medium'
    # Reuse already downloaded journal models if this MVP lives beside it.
    for candidate in [ROOT.parent / 'voice_samples/models', MODELS]:
        if all((candidate / (stem+s)).exists() for s in ('.onnx', '.onnx.json')):
            return candidate / (stem+'.onnx')
    for suffix in ('.onnx', '.onnx.json'):
        target = MODELS / (stem+suffix)
        if target.exists(): continue
        url = f'https://huggingface.co/rhasspy/piper-voices/resolve/main/pt/pt_BR/{name}/medium/{stem}{suffix}'
        logging.info('Baixando %s', target.name)
        request = urllib.request.Request(url, headers={'User-Agent': 'PensaoNair/1.0'})
        with urllib.request.urlopen(request, timeout=90) as response:
            part = target.with_suffix(target.suffix+'.part')
            with part.open('wb') as output:
                while chunk := response.read(1024*1024): output.write(chunk)
            part.replace(target)
    return MODELS / (stem+'.onnx')


def piper_wav(text, name):
    from piper import PiperVoice, SynthesisConfig
    if name not in PIPER: PIPER[name] = PiperVoice.load(str(ensure_model(name)), use_cuda=False)
    buffer = io.BytesIO()
    with wave.open(buffer, 'wb') as output:
        PIPER[name].synthesize_wav(text, output, syn_config=SynthesisConfig(length_scale=1.06, noise_scale=0.667, noise_w_scale=0.8, normalize_audio=True))
    return buffer.getvalue()


async def female_audio(text, speaker, target):
    import edge_tts
    voice, pitch, rate = ('pt-BR-FranciscaNeural', '-15Hz', '-8%') if speaker == 'NAIR' else ('pt-BR-ThalitaMultilingualNeural', '+0Hz', '+0%')
    await asyncio.wait_for(edge_tts.Communicate(text, voice, pitch=pitch, rate=rate).save(str(target)), timeout=35)


def speech(text, speaker):
    key = hashlib.sha256(('v1:'+speaker+':'+text).encode()).hexdigest()
    target = CACHE / (key+'.wav')
    if not target.exists():
        if time.monotonic() - VOICE_FAILURES.get(speaker, -1000) < 60:
            raise RuntimeError('Voz temporariamente indisponível; aguardando nova tentativa')
        try:
            if speaker in ('VALDIR', 'MAURO'):
                data = piper_wav(text, 'faber' if speaker == 'VALDIR' else 'jeff')
                target.write_bytes(data)
            else:
                mp3 = CACHE / (key+'.mp3')
                asyncio.run(female_audio(text, speaker, mp3))
                import imageio_ffmpeg
                subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-hide_banner', '-loglevel', 'error', '-y', '-i', str(mp3), '-ar', '22050', '-ac', '1', str(target)], check=True, timeout=20, capture_output=True, creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
                mp3.unlink(missing_ok=True)
        except Exception:
            target.unlink(missing_ok=True)
            VOICE_FAILURES[speaker] = time.monotonic()
            raise
    import numpy as np
    data = target.read_bytes()
    with wave.open(io.BytesIO(data),'rb') as source:
        rate = source.getframerate()
        samples = np.frombuffer(source.readframes(source.getnframes()),dtype='<i2').astype(float)/32768
    hop = round(rate*.02)
    rms = np.array([np.sqrt(np.mean(samples[i:i+hop]**2)) for i in range(0,len(samples),hop)])
    scale = max(float(np.percentile(rms,90)),.02)
    envelope = np.clip((rms-.008)/scale,0,1).round(3).tolist()
    return {'wav':base64.b64encode(data).decode(), 'envelope':envelope}


def parse_dialogue(text, min_lines=6):
    result = []
    for raw in text.splitlines():
        match = re.match(r'^\s*(?:\d+[.)]\s*)?\*{0,2}(NAIR|VALDIR|J[ÉE]SSICA|MAURO)\*{0,2}\s*:\s*\*{0,2}(.+)',raw,re.I)
        if not match: continue
        speaker = match[1].upper().replace('É','E')
        line = match[2].strip().strip('*').strip()
        if not line or line.startswith(('(', '[')): continue
        result.append((speaker,line))
    if not min_lines <= len(result) <= 20 or len({s for s,_ in result})<2:
        raise ValueError('Modelo não devolveu um diálogo utilizável com pelo menos dois personagens')
    return result


def scene_plan(present):
    before = list(present)
    if len(before) == 2 or (len(before) == 3 and random.random() < .55):
        who = random.choice([s for s in IDS if s not in before])
        event = {'action':'enter', 'speaker':who}
        after = before + [who]
    else:
        who = random.choice(before)
        event = {'action':'exit', 'speaker':who}
        after = [s for s in before if s != who]
    return before, event, after


def normalized_line(text):
    return ' '.join(re.sub(r'[^a-z0-9 ]', ' ', unicodedata.normalize('NFKD',text.casefold()).encode('ascii','ignore').decode()).split())


def reject_repetition(dialogue, history):
    old = [normalized_line(text) for _,text in history]
    seen = []
    repeats = 0
    exact_repeats = 0
    for _,text in dialogue:
        line = normalized_line(text)
        if line in old: exact_repeats += 1
        if seen.count(line) >= 2:
            raise ValueError("A mesma fala curta apareceu três vezes")
        # Short acknowledgements are natural; repeated substantive lines are not.
        if len(line.split()) >= 5:
            matches = lambda other: line == other or SequenceMatcher(None,line,other).ratio() >= .88
            if any(matches(other) for other in seen):
                raise ValueError('A resposta repetiu uma fala dentro do próprio trecho')
            if any(matches(other) for other in old): repeats += 1
        seen.append(line)
    if (exact_repeats >= 3 and exact_repeats / max(len(dialogue),1) >= .6) or repeats >= 2 or repeats / max(len(dialogue),1) >= .35:
        raise ValueError('A resposta reciclou falas recentes; crie ações e respostas novas')


def length_instruction(allow_long):
    return 'Prefira uma frase direta de 5 a 12 palavras, sem explicações adicionais. '


def split_speech(text):
    """Partition locally, preserving every word; never retry the writer for length."""
    words = text.split()
    chunks = []
    current = []
    for word in words:
        if current and (len(current) >= CONFIG.get('short_line_words',18) or len(' '.join(current + [word])) > CONFIG.get('short_line_chars',110)):
            chunks.append(' '.join(current))
            current = []
        current.append(word)
        if len(current) >= 5 and re.search(r'[.!?;]?[.!?;]["”]*$',word):
            chunks.append(' '.join(current))
            current = []
    if current: chunks.append(' '.join(current))
    return chunks


def generate_turns(present, topic, context, direction, history, allow_long=False):
    """Recover malformed multi-speaker output by assigning speakers in code."""
    dialogue = []
    order = list(present)
    random.shuffle(order)
    for i in range(4):
        speaker = order[i % len(order)]
        STATUS['status'] = f'Escrevendo fala {i+1}/4 de {speaker}'
        correction = ''
        for attempt in range(2):
            response = fetch_json(CONFIG['ollama_endpoint'], {
                'model': CONFIG['model'],
                'system': CONFIG['system'] + f'\nAGORA responda somente como {speaker}. Uma única fala, sem nome, lista ou narração. Presentes: {present}. ' + direction + length_instruction(allow_long),
                'prompt': f'Assunto: {topic}. Contexto: {context}\n' + '\n'.join(f'{s}: {t}' for s,t in dialogue) + f'\nPróxima resposta de {speaker}: {correction}',
                'stream':False, 'keep_alive':'5m',
                'options':{'temperature':CONFIG['temperature'],'num_ctx':CONFIG['num_ctx'],'num_predict':160,'repeat_penalty':1.15}})
            text = re.sub(r'<think>.*?</think>', '', response.get('response',''), flags=re.S).strip()
            text = re.sub(r'^'+speaker+r'\s*:\s*', '', text, flags=re.I).strip(' "')
            if not text or re.search(r'(NAIR|VALDIR|J[ÉE]SSICA|MAURO)\s*:',text,re.I):
                if attempt == 1: raise ValueError(f'Resposta individual inválida de {speaker}; veja cache/generation-rejected.jsonl')
                continue
            candidate = dialogue + [(speaker,text)]
            try:
                reject_repetition(candidate,history)
            except ValueError as error:
                correction = str(error)
                if attempt == 1: raise
                continue
            dialogue = candidate
            break
    return dialogue


def record_rejection(response, error):
    CACHE.mkdir(exist_ok=True)
    with (CACHE/'generation-rejected.jsonl').open('a',encoding='utf-8') as output:
        output.write(json.dumps({'error':str(error),'response':response.get('response','')},ensure_ascii=False)+'\n')


def generate_part(present, topic, context, direction, history=()):
    allow_long = random.random() < CONFIG.get('long_turn_chance',0.25)
    instruction = (
        f'Presentes nesta parte: {", ".join(present)}. '
        f'Ausentes: {", ".join(s for s in IDS if s not in present)}. '
        'Somente os presentes podem falar. Não escreva ENTRA, SAI ou rubricas. '
        'Escreva de 4 a 6 falas curtas, com pelo menos dois presentes respondendo um ao outro. '
        + direction + length_instruction(allow_long)
    )
    correction = ''
    for attempt in range(2):
        response = fetch_json(CONFIG['ollama_endpoint'], {
            'model':CONFIG['model'], 'system':CONFIG['system'] + '\n' + instruction,
            'prompt':f'Assunto: {topic}. Contexto anterior:\n{context}\n{correction}',
            'stream':False, 'keep_alive':'5m',
            'options':dict({k:CONFIG[k] for k in ('temperature','num_ctx')}, num_predict=450, repeat_penalty=1.15, repeat_last_n=256)})
        try:
            dialogue = parse_dialogue(response.get('response',''), min_lines=2)
            if any(s not in present for s,_ in dialogue):
                raise ValueError('Só podem falar: ' + ', '.join(present))
            reject_repetition(dialogue, history)
            return dialogue
        except ValueError as error:
            record_rejection(response,error)
            correction = f'Nova tentativa: {error}. Aborde outro detalhe concreto de {topic}. Faça alguém propor uma ação e outra pessoa reagir. Não recicle respostas. Somente NOME: fala, usando os presentes.'
            if attempt == 1:
                return generate_turns(present,topic,context,direction,history,allow_long)


def generate_scene(present, event, after, topic, recent, history=()):
    STATUS['status'] = 'Escrevendo conversa antes da movimentação'
    before_lines = generate_part(present, topic, recent,
        'Comece uma situação nova sobre o assunto indicado. Ninguém entra ou sai neste trecho. Não antecipe a movimentação.', history)
    context = '\n'.join(f'{s}: {t}' for s,t in before_lines)
    movement = (f"{event['speaker']} acaba de entrar pela porta e não ouviu as falas anteriores."
                if event['action']=='enter' else f"{event['speaker']} acaba de sair da cozinha e não pode mais responder.")
    STATUS['status'] = 'Escrevendo continuação após a movimentação'
    after_lines = generate_part(after, topic, context,
        movement + ' Reconheça isso naturalmente e avance a situação com uma ação ou informação nova. Não reinicie a conversa nem repita o trecho anterior.', list(history) + before_lines)
    return before_lines + after_lines, len(before_lines)


def prepare_scene(dialogue, source, present=None, event=None, event_at=3):
    expanded = []
    for index,(speaker,text) in enumerate(dialogue):
        chunks = split_speech(text)
        for part,chunk in enumerate(chunks):
            line = {'speaker':speaker,'text':chunk,'continuation':part>0,'continues':part<len(chunks)-1}
            if event and index==event_at and part==0: line['event'] = event
            expanded.append(line)
    def prepare(item):
        line = dict(item)
        speaker,text = line['speaker'],line['text']
        try:
            with VOICE_LOCKS[speaker]: line.update(speech(text,speaker))
        except Exception as error:
            logging.exception('Voz %s falhou',speaker)
            line['voice_error'] = str(error)
            STATUS['error'] = f'Voz {speaker}: {error}'
        return line
    futures = [POOL.submit(prepare,item) for item in expanded]
    lines = []
    for i,future in enumerate(futures):
        STATUS['status'] = f'Preparando áudio {i+1}/{len(expanded)}'
        lines.append(future.result())
    return {'lines':lines,'source':source,'present':present or list(dict.fromkeys(s for s,_ in dialogue))}


def worker(demo_only):
    recent = ''
    previous_topic = ''
    index = 0
    present = random.sample(IDS,2)
    history = deque(maxlen=100)
    topic_bag = []
    while not STOP.is_set():
        if SCENES.full():
            STOP.wait(.5)
            continue
        try:
            if demo_only and index >= 2:
                STATUS['status'] = 'Demonstração encerrada. Abra sem -Demo para gerar conversas novas.'
                return
            STATUS['error'] = ''
            if demo_only:
                dialogue = DEMO if index%2==0 else DEMO_TWO
                source = 'Cena de demonstração'
                present = ['NAIR','JESSICA'] if index%2==0 else ['MAURO','JESSICA']
                event = {'action':'enter','speaker':'VALDIR' if index%2==0 else 'NAIR'}
                event_at = 3
                after = present + [event['speaker']]
            else:
                if not topic_bag:
                    topic_bag = random.sample(TOPICS,len(TOPICS))
                    if topic_bag[-1] == previous_topic: topic_bag.reverse()
                topic = topic_bag.pop()
                present, event, after = scene_plan(present)
                dialogue, event_at = generate_scene(present, event, after, topic, recent, history)
                previous_topic = topic
                source = 'Diálogo gerado'
            logging.info('Texto pronto: %s falas, presentes=%s, evento=%s',len(dialogue),present,event)
            STATUS['status'] = 'Preparando vozes'
            prepared = prepare_scene(dialogue,source,present,event,event_at)
            if index == 0 and any(not line.get('wav') for line in prepared['lines']):
                raise RuntimeError('Primeira conversa ainda sem todos os áudios; tentando as vozes novamente')
            prepared['scene_id'] = index + 1
            prepared['demo'] = demo_only
            present = after
            SCENES.put(prepared)
            STATUS['ready'] = True
            logging.info('Áudios prontos; cenas na fila=%s', SCENES.qsize())
            history.extend(dialogue)
            recent = f'O assunto anterior foi {previous_topic or "a prateleira da geladeira"}. Ele já foi tratado. Agora desenvolva o NOVO assunto, sem reencenar a discussão anterior.'
            with (CACHE/'dialogues.jsonl').open('a',encoding='utf-8') as output:
                output.write(json.dumps({'source':source,'lines':[{'speaker':s,'text':t} for s,t in dialogue]},ensure_ascii=False)+'\n')
            index += 1
            STATUS['status'] = 'Cena pronta'
            STATUS['error'] = ''
        except Exception as error:
            STATUS['error'] = str(error)
            STATUS['status'] = 'Redação indisponível; tentando novamente'
            logging.exception('Geração falhou')
            STOP.wait(10)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.reply(200,dict(STATUS,service='pensao-nair',version=1,queued=SCENES.qsize()))
        elif self.path == '/next':
            try: self.reply(200,SCENES.get_nowait())
            except queue.Empty: self.reply(202,dict(STATUS,queued=0))
        else: self.reply(404,{'error':'not found'})
    def reply(self,code,payload):
        body = json.dumps(payload,ensure_ascii=False).encode() if code!=204 else b''
        self.send_response(code)
        self.send_header('Content-Type','application/json; charset=utf-8')
        self.send_header('Content-Length',str(len(body)))
        self.end_headers()
        try: self.wfile.write(body)
        except (BrokenPipeError,ConnectionResetError): pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port',type=int,default=11450)
    parser.add_argument('--demo',action='store_true')
    args = parser.parse_args()
    CACHE.mkdir(exist_ok=True)
    logging.basicConfig(level=logging.INFO,format='%(asctime)s %(message)s')
    STATUS['ready'] = False
    threading.Thread(target=worker,args=(args.demo,),daemon=True).start()
    service = ThreadingHTTPServer(('127.0.0.1',args.port),Handler)
    logging.info('Pensão em http://127.0.0.1:%s',args.port)
    try: service.serve_forever()
    finally: STOP.set(); service.server_close()

if __name__ == '__main__': main()

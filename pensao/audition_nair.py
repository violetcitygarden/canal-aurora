"""Three labeled voice treatments for Nair; does not change production voices."""
import asyncio
import json
import subprocess
import wave
from pathlib import Path
import edge_tts
from gtts import gTTS

OUT = Path(__file__).resolve().parent / 'cache' / 'nair-auditions'
TEXT = ('Valdir, eu já falei. Panela vazia não guarda lugar na geladeira. '
        'Se quer reservar espaço, paga outro aluguel. '
        'E tira essa cadeira da frente do fogão. Eu não vou pedir de novo.')
OPTIONS = [
    {'name': '1_francisca_seca', 'voice': 'pt-BR-FranciscaNeural', 'pitch': '-24Hz', 'rate': '-3%',
     'filter': 'highpass=f=100,equalizer=f=1700:t=q:w=0.8:g=3,lowpass=f=4900,acompressor=threshold=0.12:ratio=2:attack=10:release=90'},
    {'name': '2_thalita_grave', 'voice': 'pt-BR-ThalitaMultilingualNeural', 'pitch': '-28Hz', 'rate': '-5%',
     'filter': 'highpass=f=85,equalizer=f=320:t=q:w=0.7:g=2,lowpass=f=5500'},
    {'name': '3_google_tratada', 'voice': 'google-pt-BR',
     'filter': 'rubberband=pitch=0.94:tempo=1.04,highpass=f=100,equalizer=f=1900:t=q:w=0.8:g=2,lowpass=f=4700'},
]

async def generate(option):
    name = option['name']
    source = OUT / (name + '.mp3')
    if option['voice'].startswith('google'):
        await asyncio.to_thread(lambda: gTTS(TEXT, lang='pt', tld='com.br', timeout=30).save(str(source)))
    else:
        await asyncio.wait_for(edge_tts.Communicate(TEXT, option['voice'], pitch=option['pitch'], rate=option['rate']).save(str(source)), timeout=60)
    output = OUT / (name + '.wav')
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(source),
                    '-af', option['filter'] + ',loudnorm=I=-19:TP=-2:LRA=7', '-ar', '24000', '-ac', '1', str(output)],
                   check=True, timeout=30, capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
    with wave.open(str(output)) as wav:
        duration = wav.getnframes() / wav.getframerate()
        assert duration > 5 and wav.getnchannels() == 1
    return {'name': name, 'duration': round(duration, 2), 'path': str(output)}

async def main():
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'settings.json').write_text(json.dumps({'text': TEXT, 'options': OPTIONS}, ensure_ascii=False, indent=2), encoding='utf-8')
    results = await asyncio.gather(*(generate(option) for option in OPTIONS), return_exceptions=True)
    failed = False
    for result in results:
        if isinstance(result, Exception):
            failed = True
            print('FAILED', repr(result), flush=True)
        else:
            print(json.dumps(result, ensure_ascii=False), flush=True)
    if failed:
        raise RuntimeError('Some auditions failed')

if __name__ == '__main__':
    asyncio.run(main())

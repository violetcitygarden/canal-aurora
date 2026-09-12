"""Short comparable PT-BR voice auditions; generation uses online services."""
import asyncio
from pathlib import Path
import subprocess
import edge_tts
from gtts import gTTS

ROOT = Path(__file__).resolve().parent / 'weather_auditions'
TEXT = ('Boa noite. Eu sou Helena Duarte, e esta é a previsão para Santa Irene. '
        'No Alto do Cedro, sol entre nuvens, com vinte e seis graus. '
        'Amanhã, mínima de dezoito e máxima de vinte e nove graus. '
        'A prefeitura pede que ninguém recolha as sombras antes das seis. '
        'Voltamos ao Jornal Aurora.')

async def edge(name, voice):
    await edge_tts.Communicate(TEXT, voice).save(str(ROOT / f'{name}.mp3'))

def google():
    gTTS(TEXT, lang='pt', tld='com.br', timeout=30).save(str(ROOT / '3_google.mp3'))

async def main():
    ROOT.mkdir(exist_ok=True)
    (ROOT / 'texto.txt').write_text(TEXT, encoding='utf-8')
    tasks = [edge('1_francisca', 'pt-BR-FranciscaNeural'),
             edge('2_thalita', 'pt-BR-ThalitaMultilingualNeural'),
             asyncio.to_thread(google)]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    for name, result in zip(['1_francisca', '2_thalita', '3_google'], results):
        if isinstance(result, Exception):
            print(name, 'FAILED', str(result), flush=True)
            continue
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
                        '-i', str(ROOT / f'{name}.mp3'), '-ar', '24000', '-ac', '1',
                        str(ROOT / f'{name}.wav')], check=True, creationflags=subprocess.CREATE_NO_WINDOW)
        print(name, 'OK', (ROOT / f'{name}.wav').stat().st_size, flush=True)

if __name__ == '__main__':
    asyncio.run(main())

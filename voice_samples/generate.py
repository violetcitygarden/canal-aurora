"""Three comparable local PT-BR voice samples, timed on CPU."""
from pathlib import Path
import hashlib
import json
import time
import urllib.request
import wave

ROOT = Path(__file__).resolve().parent
MODELS = ROOT / 'models'
TEXT = ('Boa noite. Está no ar o Jornal Aurora. '
        'A prefeitura de Santa Irene informou que a Ponte do Cedro será reaberta nesta segunda-feira. '
        'O atendimento na biblioteca municipal permanece até as sete da noite. '
        'A seguir, a previsão do tempo para toda a região. '
        'É o maior. É o melhor. É o maior. É o melhor.')

def download(url, target):
    if target.exists():
        return
    partial = target.with_suffix(target.suffix + '.part')
    urllib.request.urlretrieve(url, partial)
    partial.replace(target)

def main():
    from piper import PiperVoice, SynthesisConfig
    MODELS.mkdir(parents=True, exist_ok=True)
    (ROOT / 'texto.txt').write_text(TEXT, encoding='utf-8')
    results = []
    for name in ['cadu', 'faber', 'jeff']:
        stem = f'pt_BR-{name}-medium'
        base = f'https://huggingface.co/rhasspy/piper-voices/resolve/main/pt/pt_BR/{name}/medium'
        print(f'Download: {name}', flush=True)
        for suffix in ['.onnx', '.onnx.json']:
            download(f'{base}/{stem}{suffix}', MODELS / (stem + suffix))
        download(f'{base}/MODEL_CARD', MODELS / (name + '-MODEL_CARD.txt'))
        start = time.perf_counter()
        voice = PiperVoice.load(str(MODELS / (stem + '.onnx')), use_cuda=False)
        load = time.perf_counter() - start
        settings = SynthesisConfig(length_scale=1.08, noise_scale=0.667, noise_w_scale=0.8, normalize_audio=True)
        # First generation measured separately from warmed synthesis.
        for run in range(2):
            output = ROOT / f'{name}.wav'
            start = time.perf_counter()
            with wave.open(str(output), 'wb') as wav:
                voice.synthesize_wav(TEXT, wav, syn_config=settings)
            seconds = time.perf_counter() - start
            if run == 0:
                first = seconds
        with wave.open(str(output), 'rb') as wav:
            duration = wav.getnframes() / wav.getframerate()
            assert duration > 5 and wav.getsampwidth() == 2
        import numpy as np
        with wave.open(str(output), 'rb') as wav:
            samples = np.frombuffer(wav.readframes(wav.getnframes()), dtype=np.int16)
        assert np.max(np.abs(samples.astype(np.int32))) > 100, 'Silent sample'
        row = dict(voice=name, load_seconds=round(load,2), first_synthesis_seconds=round(first,2),
                   warm_synthesis_seconds=round(seconds,2), audio_seconds=round(duration,2),
                   realtime_factor=round(seconds/duration,3), sample_rate=22050,
                   model_sha256=hashlib.sha256((MODELS/(stem+'.onnx')).read_bytes()).hexdigest())
        results.append(row)
        print(json.dumps(row), flush=True)
        (ROOT / 'results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
        del voice

if __name__ == '__main__':
    main()

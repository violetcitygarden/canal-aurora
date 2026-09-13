"""Audition the supplied Nair Piper model with neutral synthesis settings."""
import json
import time
import wave
from pathlib import Path
from piper import PiperVoice, SynthesisConfig

ROOT = Path(__file__).resolve().parent
OUT = ROOT / 'cache' / 'nair-auditions'
TEXT = json.loads((OUT / 'settings.json').read_text(encoding='utf-8'))['text']
model = ROOT / 'cache' / 'nair-custom-model' / 'pt_BR-nair-medium.onnx'
started = time.perf_counter()
voice = PiperVoice.load(str(model), use_cuda=False)
target = OUT / '4_nair_modelo_local.wav'
with wave.open(str(target), 'wb') as output:
    voice.synthesize_wav(TEXT, output, syn_config=SynthesisConfig(length_scale=1.0, noise_scale=0.667, noise_w_scale=0.8, normalize_audio=True))
with wave.open(str(target), 'rb') as result:
    duration = result.getnframes() / result.getframerate()
    assert result.getnframes() > 0
    print(json.dumps({'file': str(target), 'audio_seconds': round(duration, 2), 'generation_and_load_seconds': round(time.perf_counter()-started, 2), 'sample_rate': result.getframerate(), 'text': TEXT}, ensure_ascii=False))

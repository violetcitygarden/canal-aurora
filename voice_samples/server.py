"""Local Cadu CPU service; waveform envelope accompanies each WAV for lip sync."""
import base64
import io
import json
import time
import wave
import subprocess
import tempfile
import asyncio
import edge_tts
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import numpy as np
from piper import PiperVoice, SynthesisConfig

ROOT = Path(__file__).resolve().parent
VOICE = PiperVoice.load(str(ROOT / 'models/pt_BR-cadu-medium.onnx'), use_cuda=False)
JEFF = None
CONFIG = SynthesisConfig(length_scale=1.08, noise_scale=0.667, noise_w_scale=0.8, normalize_audio=True)

async def thalita_audio(path, text):
    await asyncio.wait_for(edge_tts.Communicate(text, 'pt-BR-ThalitaMultilingualNeural').save(str(path)), timeout=65)

def synthesize(text, voice='cadu'):
    global JEFF
    start = time.perf_counter()
    buffer = io.BytesIO()
    if voice == 'thalita':
        with tempfile.TemporaryDirectory(prefix='aurora-thalita-') as folder:
            mp3_path = Path(folder) / 'speech.mp3'
            wave_path = Path(folder) / 'speech.wav'
            asyncio.run(thalita_audio(mp3_path, text))
            subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y',
                            '-i', str(mp3_path), '-ar', '24000', '-ac', '1', str(wave_path)],
                           check=True, timeout=10, capture_output=True,
                           creationflags=subprocess.CREATE_NO_WINDOW)
            data = wave_path.read_bytes()
    elif voice == 'maria':
        with tempfile.TemporaryDirectory(prefix='aurora-weather-') as folder:
            text_path = Path(folder) / 'text.txt'
            wave_path = Path(folder) / 'speech.wav'
            text_path.write_text(text, encoding='utf-8')
            subprocess.run(['powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                            '-File', str(ROOT / 'maria.ps1'), str(text_path), str(wave_path)],
                           check=True, timeout=80, capture_output=True,
                           creationflags=subprocess.CREATE_NO_WINDOW)
            data = wave_path.read_bytes()
    else:
        with wave.open(buffer, 'wb') as output:
            selected = VOICE
            if voice == 'jeff':
                if JEFF is None:
                    JEFF = PiperVoice.load(str(ROOT / 'models/pt_BR-jeff-medium.onnx'), use_cuda=False)
                selected = JEFF
            selected.synthesize_wav(text, output, syn_config=CONFIG)
        data = buffer.getvalue()
    with wave.open(io.BytesIO(data), 'rb') as audio:
        rate = audio.getframerate()
        pcm = np.frombuffer(audio.readframes(audio.getnframes()), dtype='<i2').astype(np.float32) / 32768
    hop = round(rate * 0.02)
    rms = np.array([np.sqrt(np.mean(pcm[i:i+hop] ** 2)) for i in range(0,len(pcm),hop)])
    reference = max(float(np.percentile(rms, 90)), 0.02)
    envelope = np.clip((rms - 0.008) / reference, 0, 1).round(3).tolist()
    return {'voice':voice, 'wav':base64.b64encode(data).decode('ascii'),
            'envelope':envelope, 'step':hop/rate, 'duration':len(pcm)/rate,
            'synthesis_seconds':round(time.perf_counter()-start,3)}

class Handler(BaseHTTPRequestHandler):
    def reply(self, status, payload):
        data = json.dumps(payload, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass

    def do_GET(self):
        self.reply(200 if self.path == '/health' else 404, {'voice':'cadu','voices':['cadu','thalita','maria','jeff'],'backend':'piper-cpu+edge+sapi'})

    def do_POST(self):
        if self.path != '/synthesize':
            self.reply(404, {'error':'not found'})
            return
        try:
            length = int(self.headers.get('Content-Length','0'))
            if not 0 < length <= 32000:
                raise ValueError('invalid request size')
            payload = json.loads(self.rfile.read(length))
            text = payload.get('text')
            if not isinstance(text,str) or not text.strip() or len(text)>8000:
                raise ValueError('invalid text')
            voice = payload.get('voice', 'cadu')
            if voice not in ('cadu', 'thalita', 'maria', 'jeff'):
                raise ValueError('invalid voice')
            self.reply(200, synthesize(text, voice))
        except (ValueError, TypeError, json.JSONDecodeError) as error:
            self.reply(400, {'error':str(error)})
        except Exception as error:
            self.log_error('synthesis failed: %s', error)
            self.reply(500, {'error':'synthesis failed'})

if __name__ == '__main__':
    print('Cadu ready on http://127.0.0.1:11436', flush=True)
    HTTPServer(('127.0.0.1',11436),Handler).serve_forever()

import sys
import unittest
from unittest.mock import patch
import threading
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import server

class DialogueTests(unittest.TestCase):
    def test_conversation_has_multiple_characters(self):
        text = '\n'.join(f'{speaker}: {text}' for speaker,text in server.DEMO)
        self.assertEqual(server.parse_dialogue(text),server.DEMO)
    def test_rejects_monologue_and_unstructured_response(self):
        with self.assertRaises(ValueError): server.parse_dialogue('NAIR: café\n'*10)
        with self.assertRaises(ValueError): server.parse_dialogue('Era uma vez uma pensão.')
    def test_accepts_accent_and_numbered_lines(self):
        text='\n'.join(f'{i+1}. {"JÉSSICA" if s=="JESSICA" else s}: {t}' for i,(s,t) in enumerate(server.DEMO))
        self.assertEqual(server.parse_dialogue(text),server.DEMO)

    def test_presence_and_transition_are_enforced(self):
        event = {'action':'enter','speaker':'VALDIR'}
        lines = ['NAIR: Cadê o Valdir?', 'JESSICA: Está no quarto.', 'NAIR: Vou esperar.', 'ENTRA: VALDIR', 'VALDIR: Bom dia.', 'NAIR: Quer café?', 'VALDIR: Quero.']
        dialogue, cut = server.parse_scene('\n'.join(lines), ['NAIR','JESSICA'],event)
        self.assertEqual(cut,3)
        with self.assertRaises(ValueError):
            server.parse_scene('\n'.join(lines).replace('JESSICA: Está no quarto.','VALDIR: Estou aqui.'), ['NAIR','JESSICA'],event)
        with self.assertRaises(ValueError):
            server.parse_scene('\n'.join(lines).replace('ENTRA: VALDIR',''), ['NAIR','JESSICA'],event)

    def test_audio_parallelism_keeps_dialogue_order(self):
        barrier = threading.Barrier(2)
        def fake(text, speaker):
            barrier.wait(timeout=3)
            return {'wav':speaker}
        with patch.object(server,'speech',side_effect=fake):
            scene = server.prepare_scene([('NAIR','Oi'),('MAURO','Olá')],'test')
        self.assertEqual([line.get('wav') for line in scene['lines']],['NAIR','MAURO'])

    def test_exit_disallows_absent_speaker(self):
        text = 'NAIR: Até depois.\nVALDIR: Vou sair.\nSAI: VALDIR\nNAIR: Ele saiu.\nJESSICA: Pois é.\nNAIR: Quer café?\nJESSICA: Quero.'
        server.parse_scene(text,['NAIR','VALDIR','JESSICA'],{'action':'exit','speaker':'VALDIR'})
        with self.assertRaises(ValueError):
            server.parse_scene(text.replace('JESSICA: Quero.','VALDIR: Quero.'),['NAIR','VALDIR','JESSICA'],{'action':'exit','speaker':'VALDIR'})

if __name__ == '__main__': unittest.main()

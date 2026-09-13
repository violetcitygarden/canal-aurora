import sys
import threading
import unittest
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import server

class DialogueTests(unittest.TestCase):
    def test_conversation_and_numbered_accented_names(self):
        text = '\n'.join(f'{i+1}. {"JÉSSICA" if s=="JESSICA" else s}: {t}' for i,(s,t) in enumerate(server.DEMO))
        self.assertEqual(server.parse_dialogue(text), server.DEMO)

    def test_rejects_monologue(self):
        with self.assertRaises(ValueError): server.parse_dialogue('NAIR: café\n'*10)

    def test_entry_needs_no_model_marker(self):
        before = 'NAIR: Cadê o Mauro?\nJESSICA: Deve estar no quarto.\nNAIR: O café vai esfriar.\nJESSICA: Eu vou tomar.'
        after = 'MAURO: Bom dia.\nNAIR: Chegou na hora.\nMAURO: Tem café?\nJESSICA: Ainda tem.'
        with patch.object(server,'fetch_json',side_effect=[{'response':before},{'response':after}]) as fetch:
            dialogue,cut=server.generate_scene(['NAIR','JESSICA'],{'action':'enter','speaker':'MAURO'},['NAIR','JESSICA','MAURO'],'café','')
        self.assertEqual(cut,4)
        self.assertEqual(dialogue[cut][0],'MAURO')
        self.assertIn('acaba de entrar',fetch.call_args_list[1].args[1]['system'])
        self.assertIn('O café vai esfriar.',fetch.call_args_list[1].args[1]['prompt'])

    def test_absent_speaker_gets_retry(self):
        with patch.object(server,'fetch_json',side_effect=[{'response':'MAURO: Oi.\nNAIR: Oi.'},{'response':'NAIR: Oi.\nJESSICA: Oi.'}]) as fetch:
            result=server.generate_part(['NAIR','JESSICA'],'café','','')
        self.assertEqual(fetch.call_count,2)
        self.assertEqual([s for s,_ in result],['NAIR','JESSICA'])

    def test_exit_continuation_excludes_departed_character(self):
        with patch.object(server,'fetch_json',side_effect=[{'response':'NAIR: Tá bom.\nMAURO: Até depois.'},{'response':'NAIR: Ele saiu.\nJESSICA: Eu vi.'}]) as fetch:
            dialogue,cut=server.generate_scene(['NAIR','JESSICA','MAURO'],{'action':'exit','speaker':'MAURO'},['NAIR','JESSICA'],'café','')
        self.assertNotIn('MAURO',[s for s,_ in dialogue[cut:]])
        self.assertIn('acaba de sair',fetch.call_args_list[1].args[1]['system'])

    def test_audio_parallelism_preserves_order_and_event(self):
        barrier=threading.Barrier(2)
        def fake(text,speaker):
            barrier.wait(timeout=3)
            return {'wav':speaker}
        event={'action':'enter','speaker':'MAURO'}
        with patch.object(server,'speech',side_effect=fake):
            scene=server.prepare_scene([('NAIR','Oi'),('MAURO','Olá')],'test',['NAIR'],event,1)
        self.assertEqual([line.get('wav') for line in scene['lines']],['NAIR','MAURO'])
        self.assertEqual(scene['lines'][1]['event'],event)

if __name__ == '__main__': unittest.main()

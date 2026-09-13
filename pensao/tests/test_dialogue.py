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

class RepetitionTests(unittest.TestCase):
    def test_rejects_recycled_five_short_phrases(self):
        lines=[('NAIR','Quer café?'),('JESSICA','Quero sim.'),('NAIR','Está quente.'),('JESSICA','Vou esperar.'),('NAIR','Tá bom.')]
        with self.assertRaises(ValueError): server.reject_repetition(lines,lines)

    def test_rejects_near_duplicate_substantive_lines(self):
        old=[('NAIR','Você precisa lavar essa panela antes do almoço.'),('JESSICA','Eu vou lavar essa panela depois do almoço.')]
        new=[('NAIR','Você precisa lavar essa panela antes do almoço!'),('JESSICA','Eu vou lavar essa panela depois do almoço!')]
        with self.assertRaises(ValueError): server.reject_repetition(new,old)

    def test_allows_brief_acknowledgement_in_new_conversation(self):
        server.reject_repetition([('NAIR','Tá bom.'),('JESSICA','Eu deixei a chave da lavanderia com o porteiro.')],[('NAIR','Tá bom.')])

    def test_retry_discards_repeated_output(self):
        old=[('NAIR','Você precisa lavar essa panela antes do almoço.'),('JESSICA','Eu vou lavar essa panela depois do almoço.')]
        repeated='\n'.join(f'{s}: {t}' for s,t in old)
        fresh='NAIR: A esponja nova está no armário.\nJESSICA: Vou pegar antes que sumam com ela.'
        with patch.object(server,'fetch_json',side_effect=[{'response':repeated},{'response':fresh}]) as fetch:
            result=server.generate_part(['NAIR','JESSICA'],'louça','','',old)
        self.assertEqual(fetch.call_count,2)
        self.assertIn('esponja',result[0][1])

class StartupTests(unittest.TestCase):
    def test_malformed_dialogue_recovers_with_assigned_speakers(self):
        responses=[{'response':'Uma história sem nomes.'}]*2 + [{'response':t} for t in ['A torneira está pingando desde cedo.','Eu deixei uma bacia ali embaixo.','Essa bacia é onde eu lavo a roupa.','Então vou buscar o balde no quintal.']]
        with patch.object(server,'fetch_json',side_effect=responses), patch.object(server,'record_rejection'):
            dialogue=server.generate_part(['NAIR','JESSICA'],'torneira','','')
        self.assertEqual(len(dialogue),4)
        self.assertEqual(len({s for s,_ in dialogue}),2)

    def test_first_scene_is_generated_and_ready_only_after_audio(self):
        import queue
        import tempfile
        stop=threading.Event()
        scenes=queue.Queue()
        dialogue=[('NAIR','Primeira fala nova.'),('JESSICA','Resposta nova.')]
        status={'ready':False,'status':'','error':''}
        def prepare(*args):
            self.assertFalse(status['ready'])
            stop.set()
            return {'lines':[{'speaker':s,'text':t,'wav':'test'} for s,t in dialogue]}
        with tempfile.TemporaryDirectory() as tmp, patch.object(server,'CACHE',Path(tmp)), patch.object(server,'STOP',stop), patch.object(server,'SCENES',scenes), patch.object(server,'STATUS',status), patch.object(server,'generate_scene',return_value=(dialogue,1)) as generate, patch.object(server,'prepare_scene',side_effect=prepare):
            server.worker(False)
        self.assertEqual(generate.call_count,1)
        self.assertTrue(status['ready'])
        self.assertEqual(scenes.get()['lines'][0]['text'],'Primeira fala nova.')

class LengthTests(unittest.TestCase):
    def test_split_preserves_words_without_writer(self):
        text=' '.join(['palavra']*50)
        chunks=server.split_speech(text)
        self.assertGreater(len(chunks),1)
        self.assertEqual(' '.join(chunks),text)
        self.assertTrue(all(len(t.split())<=18 for t in chunks))

    def test_long_turn_is_accepted_without_length_retry(self):
        texts=[' '.join(['palavra']*50),'Quem deixou esse balde aqui?','Eu trouxe para lavar o chão.','Então coloca perto da porta.']
        with patch.object(server,'fetch_json',side_effect=[{'response':t} for t in texts]) as fetch:
            dialogue=server.generate_turns(['NAIR','JESSICA'],'balde','','',[])
        self.assertEqual(fetch.call_count,4)
        self.assertEqual(dialogue[0][1],texts[0])

    def test_split_keeps_event_and_laughter_boundary(self):
        event={'action':'enter','speaker':'MAURO'}
        with patch.object(server,'speech',return_value={'wav':'test'}):
            scene=server.prepare_scene([('NAIR','Oi.'),('MAURO',' '.join(['palavra']*40))],'test',['NAIR'],event,1)
        self.assertEqual(scene['lines'][1]['event'],event)
        self.assertEqual(sum('event' in line for line in scene['lines']),1)
        self.assertTrue(scene['lines'][1]['continues'])
        self.assertTrue(scene['lines'][-1]['continuation'])
        self.assertFalse(scene['lines'][-1]['continues'])

if __name__ == '__main__': unittest.main()

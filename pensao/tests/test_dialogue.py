import sys
import unittest
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

if __name__ == '__main__': unittest.main()

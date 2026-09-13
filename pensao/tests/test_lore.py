import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lore import load_memory, save_delivered, context

class LoreTests(unittest.TestCase):
    def test_persistence_and_bounded_history(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'memory.json'
            ordinary = {'lines': [{'speaker': 'NAIR', 'text': 'Lave a panela.'}]}
            save_delivered(path, ordinary)
            self.assertFalse(path.exists())
            for i in range(25):
                save_delivered(path, {'personal': True, 'lines': [
                    {'speaker': 'VALDIR', 'text': f'Conheci Ana no baile {i}.', 'wav': 'not persisted'}]})
            data = load_memory(path)
            self.assertEqual(len(data), 20)
            self.assertNotIn('wav', path.read_text())
            self.assertIn('Ana no baile 24', context(data))
            self.assertNotIn('Ana no baile 5.', context(data))

    def test_missing_or_damaged_memory(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'memory.json'
            self.assertEqual(load_memory(path), [])
            path.write_text('broken')
            self.assertEqual(load_memory(path), [])

if __name__ == '__main__': unittest.main()

import importlib.util
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parent.parent / 'scripts' / 'validate-openmaptiles.py'

spec = importlib.util.spec_from_file_location('validate_openmaptiles', MODULE_PATH)
validate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validate)


GOOD_METADATA = {'format': 'pbf', 'bounds': '-180,-85,180,85', 'minzoom': '0', 'maxzoom': '14'}
GOOD_LAYERS = ['water', 'transportation', 'place', 'poi', 'building', 'landcover']


def make_mbtiles(path, metadata=None, vector_layers=None, tile_rows=1):
    con = sqlite3.connect(path)
    cur = con.cursor()
    cur.execute('CREATE TABLE metadata (name TEXT, value TEXT)')
    cur.execute('CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB)')
    md = dict(metadata or {})
    if vector_layers is not None:
        md['json'] = json.dumps({'vector_layers': [{'id': layer} for layer in vector_layers]})
    for key, value in md.items():
        cur.execute('INSERT INTO metadata VALUES (?, ?)', (key, value))
    for _ in range(tile_rows):
        cur.execute('INSERT INTO tiles VALUES (0, 0, 0, ?)', (b'x',))
    con.commit()
    con.close()


class ValidateOpenMapTilesTest(unittest.TestCase):
    def test_accepts_valid_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'valid.mbtiles'
            make_mbtiles(path, GOOD_METADATA, GOOD_LAYERS)
            self.assertEqual(validate.main([str(path)]), 0)

    def test_rejects_missing_metadata(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'no-format.mbtiles'
            metadata = {k: v for k, v in GOOD_METADATA.items() if k != 'format'}
            make_mbtiles(path, metadata, GOOD_LAYERS)
            self.assertNotEqual(validate.main([str(path)]), 0)

    def test_rejects_missing_required_layer(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'no-poi.mbtiles'
            layers = [layer for layer in GOOD_LAYERS if layer != 'poi']
            make_mbtiles(path, GOOD_METADATA, layers)
            self.assertNotEqual(validate.main([str(path)]), 0)

    def test_rejects_empty_tiles(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'empty.mbtiles'
            make_mbtiles(path, GOOD_METADATA, GOOD_LAYERS, tile_rows=0)
            self.assertNotEqual(validate.main([str(path)]), 0)


if __name__ == '__main__':
    unittest.main()

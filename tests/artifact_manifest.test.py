import json
import tempfile
import unittest
from pathlib import Path

from scripts.artifact_manifest import verify_manifest, write_manifest


class ManifestTest(unittest.TestCase):
    def test_round_trip_and_source_change_detection(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / 'region.osm.pbf'
            artifact = root / 'output.mbtiles'
            local = root / 'style'
            manifest = root / 'manifest.json'
            source.write_bytes(b'osm')
            artifact.write_bytes(b'tiles')
            local.mkdir()
            (local / 'style.json').write_text('{}')

            write_manifest('openmaptiles', source, artifact, 'v3.16', 'abc', [local], manifest)
            self.assertTrue(verify_manifest(source, artifact, [local], manifest))

            source.write_bytes(b'changed')
            self.assertFalse(verify_manifest(source, artifact, [local], manifest))
            data = json.loads(manifest.read_text())
            self.assertEqual(data['kind'], 'openmaptiles')


if __name__ == '__main__':
    unittest.main()

import gzip
import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = (
    Path(__file__).resolve().parent.parent
    / "scripts"
    / "validate-openmaptiles-pmtiles.py"
)

spec = importlib.util.spec_from_file_location(
    "validate_openmaptiles_pmtiles", MODULE_PATH
)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


HEADER_LENGTH = 127
GOOD_LAYERS = ["water", "transportation", "place", "poi", "building", "landcover"]


def make_pmtiles(
    path,
    *,
    magic=b"PMTiles",
    version=3,
    addressed=10,
    entries=10,
    contents=10,
    internal_compression=2,
    tile_compression=2,
    tile_type=1,
    minzoom=0,
    maxzoom=14,
    bounds=(-180.0, -85.0, 180.0, 85.0),
    layers=GOOD_LAYERS,
    metadata_gap=4096,
    truncate_metadata=False,
    tile_length=1,
):
    metadata = gzip.compress(
        json.dumps({"vector_layers": [{"id": layer} for layer in layers]}).encode()
    )
    root_offset = HEADER_LENGTH
    root_length = 1
    metadata_offset = HEADER_LENGTH + metadata_gap
    tile_offset = metadata_offset + len(metadata)
    header = bytearray(HEADER_LENGTH)
    header[0:7] = magic
    header[7] = version
    for offset, value in (
        (8, root_offset),
        (16, root_length),
        (24, metadata_offset),
        (32, len(metadata)),
        (56, tile_offset),
        (64, tile_length),
        (72, addressed),
        (80, entries),
        (88, contents),
    ):
        struct.pack_into("<Q", header, offset, value)
    header[96] = 1
    header[97] = internal_compression
    header[98] = tile_compression
    header[99] = tile_type
    header[100] = minzoom
    header[101] = maxzoom
    for offset, value in zip((102, 106, 110, 114), bounds):
        struct.pack_into("<i", header, offset, round(value * 10_000_000))
    with open(path, "wb") as stream:
        stream.write(header)
        stream.write(b"r")
        stream.write(b"\0" * (metadata_offset - stream.tell()))
        stream.write(metadata[:-1] if truncate_metadata else metadata)
        if not truncate_metadata and tile_length:
            stream.write(b"t")


class ValidateOpenMapTilesPMTilesTest(unittest.TestCase):
    def assert_rejected(self, **kwargs):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "invalid.pmtiles"
            make_pmtiles(path, **kwargs)
            self.assertTrue(validator.validate(str(path)))

    def test_accepts_valid_world_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "valid.pmtiles"
            make_pmtiles(path)
            self.assertEqual(validator.validate(str(path), require_world=True), [])

    def test_rejects_short_header(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "short.pmtiles"
            path.write_bytes(b"PMTiles")
            self.assertTrue(validator.validate(str(path)))

    def test_rejects_bad_magic(self):
        self.assert_rejected(magic=b"NotTile")

    def test_rejects_version_2(self):
        self.assert_rejected(version=2)

    def test_rejects_zero_addressed_tiles(self):
        self.assert_rejected(addressed=0)

    def test_rejects_zero_tile_entries(self):
        self.assert_rejected(entries=0)

    def test_rejects_zero_tile_contents(self):
        self.assert_rejected(contents=0)

    def test_rejects_zero_tile_data_length(self):
        self.assert_rejected(tile_length=0)

    def test_rejects_range_beyond_eof(self):
        self.assert_rejected(metadata_gap=8192, truncate_metadata=True)

    def test_rejects_non_gzip_internal_metadata(self):
        self.assert_rejected(internal_compression=1)

    def test_rejects_non_gzip_tile_compression(self):
        self.assert_rejected(tile_compression=1)

    def test_rejects_non_mvt_tile_type(self):
        self.assert_rejected(tile_type=2)

    def test_rejects_nonzero_min_zoom(self):
        self.assert_rejected(minzoom=1)

    def test_rejects_max_zoom_below_14(self):
        self.assert_rejected(maxzoom=13)

    def test_rejects_missing_poi_layer(self):
        self.assert_rejected(layers=[layer for layer in GOOD_LAYERS if layer != "poi"])

    def test_rejects_truncated_metadata(self):
        self.assert_rejected(truncate_metadata=True)

    def test_rejects_regional_bounds_when_world_required(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "regional.pmtiles"
            make_pmtiles(path, bounds=(112.0, -44.0, 154.0, -10.0))
            self.assertTrue(validator.validate(str(path), require_world=True))


if __name__ == "__main__":
    unittest.main()

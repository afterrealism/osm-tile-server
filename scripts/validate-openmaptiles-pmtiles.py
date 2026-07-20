#!/usr/bin/env python3
import argparse
import gzip
import json
import os
import struct
import sys

HEADER_LENGTH = 127
REQUIRED_LAYERS = {"water", "transportation", "place", "poi", "building", "landcover"}


def _u64(header: bytes, offset: int) -> int:
    return struct.unpack_from("<Q", header, offset)[0]


def _i32(header: bytes, offset: int) -> int:
    return struct.unpack_from("<i", header, offset)[0]


def validate(path: str, require_world: bool = False) -> list[str]:
    problems = []
    size = os.path.getsize(path)
    with open(path, "rb") as stream:
        header = stream.read(HEADER_LENGTH)
        if len(header) != HEADER_LENGTH:
            return ["file smaller than 127-byte PMTiles header"]
        if header[0:7] != b"PMTiles":
            return ["bad magic: not a PMTiles archive"]
        if header[7] != 3:
            return [f"unsupported PMTiles version: {header[7]}"]

        ranges = {
            "root directory": (_u64(header, 8), _u64(header, 16)),
            "metadata": (_u64(header, 24), _u64(header, 32)),
            "leaf directories": (_u64(header, 40), _u64(header, 48)),
            "tile data": (_u64(header, 56), _u64(header, 64)),
        }
        for name, (offset, length) in ranges.items():
            if name in ("root directory", "metadata", "tile data") and length == 0:
                problems.append(f"{name} is empty")
            if length and (
                offset < HEADER_LENGTH or offset > size or length > size - offset
            ):
                problems.append(f"{name} range is outside the file")

        for label, offset in (
            ("addressed tiles", 72),
            ("tile entries", 80),
            ("tile contents", 88),
        ):
            if _u64(header, offset) == 0:
                problems.append(f"no {label} present")
        if header[97] != 2:
            problems.append(f"internal compression must be gzip (2), got {header[97]}")
        if header[98] != 2:
            problems.append(f"tile compression must be gzip (2), got {header[98]}")
        if header[99] != 1:
            problems.append(f"tile type must be MVT (1), got {header[99]}")
        if header[100] != 0:
            problems.append(f"min zoom must be 0, got {header[100]}")
        if header[101] < 14:
            problems.append(f"max zoom must be at least 14, got {header[101]}")

        bounds = tuple(
            _i32(header, offset) / 10_000_000 for offset in (102, 106, 110, 114)
        )
        if require_world and not (
            bounds[0] <= -179
            and bounds[1] <= -80
            and bounds[2] >= 179
            and bounds[3] >= 80
        ):
            problems.append(f"archive does not cover world bounds: {bounds}")

        metadata_offset, metadata_length = ranges["metadata"]
        if (
            metadata_length
            and metadata_offset <= size
            and metadata_length <= size - metadata_offset
        ):
            stream.seek(metadata_offset)
            raw = stream.read(metadata_length)
            try:
                metadata = json.loads(gzip.decompress(raw))
                layers = {
                    item.get("id")
                    for item in metadata.get("vector_layers", [])
                    if isinstance(item, dict)
                }
                missing = REQUIRED_LAYERS - layers
                if missing:
                    problems.append(f"missing vector layers: {sorted(missing)}")
            except (OSError, UnicodeDecodeError, ValueError, TypeError) as exc:
                problems.append(f"unparseable metadata: {exc}")
    return problems


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-world", action="store_true")
    parser.add_argument("archive")
    args = parser.parse_args(argv)
    problems = validate(args.archive, args.require_world)
    for problem in problems:
        print(f"ERROR: {problem}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def sha256_tree(path: Path) -> str:
    digest = hashlib.sha256()
    for file in sorted(item for item in path.rglob('*') if item.is_file()):
        digest.update(file.relative_to(path).as_posix().encode())
        digest.update(sha256_file(file).encode())
    return digest.hexdigest()


def local_source_hashes(local_sources: list[Path]) -> dict[str, str]:
    ordered = sorted(local_sources, key=lambda path: path.as_posix())
    return {path.name: sha256_tree(path) for path in ordered}


def write_manifest(kind: str, source: Path, artifact: Path, source_ref: str,
                   source_commit: str, local_sources: list[Path], manifest: Path) -> None:
    stat = source.stat()
    data = {
        'kind': kind,
        'source_sha256': sha256_file(source),
        'source_size': stat.st_size,
        'source_mtime_ns': stat.st_mtime_ns,
        'artifact_sha256': sha256_file(artifact),
        'source_ref': source_ref,
        'source_commit': source_commit,
        'local_source_sha256': local_source_hashes(local_sources),
        'generated_at': datetime.now(timezone.utc).isoformat(),
    }
    temporary = manifest.with_suffix(manifest.suffix + '.part')
    temporary.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')
    temporary.replace(manifest)


def verify_manifest(source: Path, artifact: Path, local_sources: list[Path],
                    manifest: Path) -> bool:
    if not source.is_file() or not artifact.is_file() or not manifest.is_file():
        return False
    data = json.loads(manifest.read_text())
    stat = source.stat()
    return (
        data['source_sha256'] == sha256_file(source)
        and data['source_size'] == stat.st_size
        and data['artifact_sha256'] == sha256_file(artifact)
        and data['local_source_sha256'] == local_source_hashes(local_sources)
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest='command', required=True)
    for command in ('write', 'verify'):
        sub = subparsers.add_parser(command)
        sub.add_argument('--source', type=Path, required=True)
        sub.add_argument('--artifact', type=Path, required=True)
        sub.add_argument('--local-source', type=Path, action='append', required=True)
        sub.add_argument('--manifest', type=Path, required=True)
        if command == 'write':
            sub.add_argument('--kind', required=True)
            sub.add_argument('--source-ref', required=True)
            sub.add_argument('--source-commit', required=True)
    args = parser.parse_args()
    if args.command == 'write':
        write_manifest(args.kind, args.source, args.artifact, args.source_ref,
                       args.source_commit, args.local_source, args.manifest)
        return 0
    return 0 if verify_manifest(args.source, args.artifact,
                                args.local_source, args.manifest) else 1


if __name__ == '__main__':
    raise SystemExit(main())

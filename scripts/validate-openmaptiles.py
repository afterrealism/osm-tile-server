#!/usr/bin/env python3
import json
import sqlite3
import sys

REQUIRED_METADATA = {'format', 'bounds', 'minzoom', 'maxzoom', 'json'}
REQUIRED_LAYERS = {'water', 'transportation', 'place', 'poi', 'building', 'landcover'}


def validate(path):
    problems = []
    con = sqlite3.connect(f'file:{path}?mode=ro', uri=True)
    cur = con.cursor()
    metadata = dict(cur.execute('SELECT name, value FROM metadata'))
    missing_metadata = REQUIRED_METADATA - metadata.keys()
    if missing_metadata:
        problems.append(f'missing metadata: {sorted(missing_metadata)}')
    layers = set()
    if 'json' in metadata:
        layers = {layer['id'] for layer in json.loads(metadata['json']).get('vector_layers', [])}
    missing_layers = REQUIRED_LAYERS - layers
    if missing_layers:
        problems.append(f'missing vector layers: {sorted(missing_layers)}')
    if cur.execute('SELECT 1 FROM tiles LIMIT 1').fetchone() is None:
        problems.append('no tiles present')
    con.close()
    return problems


def main(argv=None):
    argv = argv if argv is not None else sys.argv[1:]
    if len(argv) != 1:
        print('usage: validate-openmaptiles.py FILE.mbtiles', file=sys.stderr)
        return 2
    problems = validate(argv[0])
    for problem in problems:
        print(f'ERROR: {problem}', file=sys.stderr)
    return 1 if problems else 0


if __name__ == '__main__':
    raise SystemExit(main())

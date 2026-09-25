#!/usr/bin/env python3
"""Regenerate with the explicitly pinned abi-typegen release."""
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
binary = os.environ.get('ABI_TYPEGEN_BIN', 'abi-typegen')
version = subprocess.check_output([binary, '--version'], text=True).strip()
if version != 'abi-typegen 0.6.0':
    raise SystemExit(f'Expected abi-typegen 0.6.0, got {version}')
for source in sorted((root / 'abi').glob('*.json')):
    artifact = root / 'artifacts' / f'{source.stem}.sol' / source.name
    artifact.parent.mkdir(parents=True, exist_ok=True)
    artifact.write_text(json.dumps({'contractName': source.stem, 'abi': json.loads(source.read_text())}, indent=2) + '\n')
args = [binary, 'generate', '--artifacts', str(root / 'artifacts'), '--out', str(root / 'generated'), '--target', 'godot']
if '--check' in sys.argv:
    args.append('--check')
subprocess.run(args, check=True)

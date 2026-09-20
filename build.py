#!/usr/bin/env python3
"""Build a portable source ZIP and checksums from an explicit allowlist."""
from pathlib import Path
import hashlib
import re
import zipfile

root = Path(__file__).resolve().parent
version = re.search(r'^;; Version: (.+)$', (root / 'perinf.el').read_text(), re.M).group(1)
name = f'perinf-{version}'
out = root / 'dist'
out.mkdir(exist_ok=True)
files = sorted(root.glob('perinf*.el'))
files += [root / x for x in ['LICENSE', 'README.md', 'README.da.md', 'CHANGELOG-da.md', 'VALIDATION.md', 'Makefile', '.gitignore', 'install.py', 'build.py']]
for directory in ['scripts', 'test', 'examples', 'recipes']:
    files += sorted(p for p in (root / directory).rglob('*') if p.is_file() and p.suffix not in ['.pyc', '.elc'] and p.name != '.DS_Store')
archive = out / f'{name}.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
    for path in files:
        z.write(path, f'{name}/{path.relative_to(root).as_posix()}')
for path in [archive, out / f'{name}.tar']:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    path.with_suffix(path.suffix + '.sha256').write_text(f'{digest}  {path.name}\n')
    print(path.name, digest)

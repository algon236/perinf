#!/usr/bin/env python3
"""Install PerInf sources without replacing an existing installation or data."""
import argparse
from pathlib import Path
import shutil
import sys


def install(target):
    root = Path(__file__).resolve().parent
    target = Path(target).expanduser().absolute()
    if target.exists() or target.is_symlink():
        raise FileExistsError(f'Installation already exists: {target}')
    target.mkdir(parents=True)
    for path in sorted(root.glob('perinf*.el')):
        shutil.copy2(path, target / path.name)
    shutil.copy2(root / 'LICENSE', target / 'LICENSE')
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--target', default='~/.emacs.d/lisp/perinf')
    args = parser.parse_args()
    try:
        target = install(args.target)
    except OSError as error:
        print(error, file=sys.stderr)
        return 1
    print(f'Installed: {target}\nAdd this directory to load-path and require perinf.\nDefault project: ~/org/agenda/\nSee README.da.md for setup.')
    return 0


if __name__ == '__main__':
    sys.exit(main())

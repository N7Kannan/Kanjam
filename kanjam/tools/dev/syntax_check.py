#!/usr/bin/env python3
"""Structural Dart syntax check using tree-sitter (brackets, missing tokens, bad
statements). It does NOT type-check; use `flutter analyze` for that."""
import sys, pathlib
import tree_sitter_dart as tsd
from tree_sitter import Language, Parser

lang = Language(tsd.language())
parser = Parser(lang)

def errors(node, out):
    if node.type == 'ERROR' or node.is_missing:
        out.append(node)
        return
    for c in node.children:
        errors(c, out)

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '.')
bad = 0
files = sorted(root.rglob('*.dart'))
for f in files:
    src = f.read_bytes()
    tree = parser.parse(src)
    out = []
    errors(tree.root_node, out)
    if out:
        bad += 1
        for n in out[:5]:
            line = n.start_point[0] + 1
            snippet = src.decode('utf8', 'replace').splitlines()[line - 1].strip()[:90]
            kind = 'MISSING ' + n.type if n.is_missing else 'ERROR'
            print(f'{f}:{line}: {kind}: {snippet}')
print(f'checked {len(files)} files, {bad} with syntax problems')

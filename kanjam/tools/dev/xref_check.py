#!/usr/bin/env python3
"""Cross-reference checks for the KANJAM Dart sources (no Dart SDK needed).

Catches the mistakes a compiler would flag that a pure syntax check cannot:
  * relative imports that do not resolve, packages missing from pubspec
  * project symbols used without importing the file that defines them
  * well-known SDK symbols used without the import that provides them
  * named constructor arguments that do not exist / required ones missing
  * members used on project service classes or static helper classes that
    are not declared
  * project imports that are never used (analyzer `unused_import`)
It is heuristic. `flutter analyze` remains the source of truth.
"""
import re, sys, pathlib

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()
LIB = ROOT / 'lib'

# ---------------------------------------------------------------- scanning
def strip(src: str) -> str:
    """Blank out comments and string-literal text (offsets preserved).
    Code inside ${...} interpolations is kept."""
    out = list(src)
    n = len(src)

    def scan_code(i, stop_on_brace=False):
        depth = 0
        while i < n:
            c = src[i]
            if c == '/' and i + 1 < n and src[i + 1] == '/':
                while i < n and src[i] != '\n':
                    out[i] = ' '; i += 1
                continue
            if c == '/' and i + 1 < n and src[i + 1] == '*':
                j = src.find('*/', i + 2); j = n if j < 0 else j + 2
                for k in range(i, j):
                    if out[k] != '\n': out[k] = ' '
                i = j; continue
            if c in '\'"':
                i = scan_string(i); continue
            if stop_on_brace:
                if c == '{': depth += 1
                elif c == '}':
                    if depth == 0: return i
                    depth -= 1
            i += 1
        return i

    def scan_string(i):
        q = src[i]
        raw = i > 0 and src[i - 1] == 'r'
        triple = src.startswith(q * 3, i)
        qlen = 3 if triple else 1
        i += qlen
        while i < n:
            c = src[i]
            if c == '\\' and not raw:
                out[i] = ' '
                if i + 1 < n and out[i + 1] != '\n': out[i + 1] = ' '
                i += 2; continue
            if src.startswith(q * qlen, i):
                return i + qlen
            if c == '$' and not raw:
                if i + 1 < n and src[i + 1] == '{':
                    out[i] = ' '; out[i + 1] = ' '
                    j = scan_code(i + 2, stop_on_brace=True)
                    if j < n: out[j] = ' '
                    i = j + 1; continue
                out[i] = ' '; i += 1; continue   # $ident: ident kept as code
            if c != '\n': out[i] = ' '
            i += 1
        return i

    scan_code(0)
    return ''.join(out)

files = sorted(LIB.rglob('*.dart'))
raw = {f: f.read_text(encoding='utf8') for f in files}
code = {f: strip(raw[f]) for f in files}

pubspec = (ROOT / 'pubspec.yaml').read_text()
deps = set(re.findall(r'^  ([a-z_0-9]+):', pubspec, re.M))
errors, warns = [], []
def err(f, msg): errors.append(f'{f.relative_to(ROOT)}: {msg}')
def warn(f, msg): warns.append(f'{f.relative_to(ROOT)}: {msg}')

# ---------------------------------------------------------------- symbols
DEF = re.compile(r'^(?:abstract\s+|final\s+|base\s+|sealed\s+)*(class|enum|mixin|extension)\s+(\w+)', re.M)
FUNC = re.compile(r'^(?:Future<[^>]*>|Future|void|bool|String|int|double|InputDecoration|Widget|List<[^>]*>)\s+(\w+)\s*\(', re.M)
defs = {}          # symbol -> file
for f in files:
    for m in DEF.finditer(code[f]):
        name = m.group(2)
        if name.startswith('_'): continue
        if name in defs and defs[name] != f:
            err(f, f'duplicate public symbol {name} (also in {defs[name].name})')
        defs[name] = f
    for m in FUNC.finditer(code[f]):
        name = m.group(1)
        if not name.startswith('_') and name != 'main':
            defs[name] = f

def imports_of(f):
    res = []
    for m in re.finditer(r"^import\s+'([^']+)'(?:\s+(?:as\s+\w+|show\s+[^;]+|hide\s+[^;]+))?;", raw[f], re.M):
        res.append(m.group(1))
    return res

ident = re.compile(r'(?<![\w.$])([A-Za-z_]\w*)')
def used_idents(f):
    return set(ident.findall(code[f]))

# SDK symbols -> acceptable import substrings
SDK = {
    'unawaited': ['dart:async'],
    'Timer': ['dart:async'], 'Completer': ['dart:async'],
    'Random': ['dart:math'],
    'base64UrlEncode': ['dart:convert'], 'utf8': ['dart:convert'], 'jsonEncode': ['dart:convert'],
    'TextInputFormatter': ['flutter/services.dart'],
    'FilteringTextInputFormatter': ['flutter/services.dart'],
    'HapticFeedback': ['flutter/services.dart'],
    'TextEditingValue': ['flutter/services.dart', 'flutter/material.dart', 'flutter/widgets.dart'],
    'ChangeNotifier': ['flutter/foundation.dart', 'flutter/material.dart', 'flutter/widgets.dart'],
    'debugPrint': ['flutter/foundation.dart', 'flutter/material.dart', 'flutter/widgets.dart'],
    'Hive': ['hive_flutter', 'hive/hive.dart', 'package:hive/'],
    'Box': ['hive_flutter', 'package:hive/'],
    'NumberFormat': ['package:intl/'], 'DateFormat': ['package:intl/'],
    'sha256': ['package:crypto/'],
    'MultiProvider': ['package:provider/'], 'Consumer': ['package:provider/'],
    'ChangeNotifierProvider': ['package:provider/'],
}
for f in files:
    src_imports = imports_of(f)
    for sym, needs in SDK.items():
        if re.search(r'(?<![\w.])' + re.escape(sym) + r'\b', code[f]):
            if not any(any(n in imp for n in needs) for imp in src_imports):
                err(f, f'uses {sym} but has none of the imports {needs}')
    if re.search(r'context\.(read|watch|select)<', code[f]) and not any('package:provider' in i for i in src_imports):
        err(f, 'uses context.read/watch without importing provider')
    if re.search(r'\.pal\b', code[f]) and f.name != 'theme.dart' and not any(i.endswith('theme.dart') for i in src_imports):
        err(f, 'uses context.pal without importing core/theme.dart')
    for imp in src_imports:
        if imp.startswith('package:'):
            pkg = imp.split(':')[1].split('/')[0]
            if pkg != 'flutter' and pkg not in deps:
                err(f, f'package {pkg} not in pubspec dependencies')
        elif not imp.startswith('dart:'):
            target = (f.parent / imp).resolve()
            if not target.exists():
                err(f, f'import does not resolve: {imp}')

# project symbols used but defining file not imported (or same file)
for f in files:
    imp_targets = set()
    for imp in imports_of(f):
        if not imp.startswith(('dart:', 'package:')):
            imp_targets.add((f.parent / imp).resolve())
    for sym in used_idents(f):
        d = defs.get(sym)
        if d and d != f and d.resolve() not in imp_targets:
            # a private-looking local with same name? ignore if declared locally
            if re.search(r'\b(class|enum|mixin)\s+' + sym + r'\b', code[f]): continue
            err(f, f'uses {sym} (defined in {d.relative_to(ROOT)}) without importing it')
    # unused project imports
    for t in imp_targets:
        sy = [s for s, fl in defs.items() if fl.resolve() == t]
        uses_pal = t.name == 'theme.dart' and re.search(r'\.pal\b', code[f])
        if sy and not uses_pal and not any(s in used_idents(f) for s in sy):
            warn(f, f'unused import {t.relative_to(LIB)}')

# ---------------------------------------------------------------- constructors
def split_top(s, sep=','):
    parts, depth, cur = [], 0, ''
    for c in s:
        if c in '([{': depth += 1
        elif c in ')]}': depth -= 1
        if c == sep and depth == 0:
            parts.append(cur); cur = ''
        else:
            cur += c
    if cur.strip(): parts.append(cur)
    return parts

def match_paren(s, i):
    depth = 0
    for j in range(i, len(s)):
        if s[j] in '([{': depth += 1
        elif s[j] in ')]}':
            depth -= 1
            if depth == 0: return j
    return -1

ctors = {}      # class -> (named set, required set, definition offset, file)
for f in files:
    c = code[f]
    for m in re.finditer(r'\bclass\s+(\w+)\b[^{;]*\{', c):
        name = m.group(1)
        start = m.end()
        # find the class body end by brace matching
        end = match_paren(c, m.end() - 1)
        body = c[start:end if end > 0 else len(c)]
        cm = re.search(r'(?:const\s+)?\b' + name + r'\s*\(', body)
        if not cm: continue
        po = start + cm.end() - 1
        pc = match_paren(c, po)
        params = c[po + 1:pc]
        if '{' not in params: 
            ctors[name] = None   # positional ctor: skip checking
            continue
        named = params[params.index('{') + 1:params.rindex('}')]
        names, required = set(), set()
        for seg in split_top(named):
            seg = seg.strip()
            if not seg: continue
            seg_nodef = seg.split('=')[0] if '=' in seg and not seg.strip().startswith('required') or '=' in seg else seg
            nm = re.search(r'(?:this\.|super\.)?(\w+)\s*$', seg_nodef.strip())
            if not nm: continue
            names.add(nm.group(1))
            if seg.startswith('required'): required.add(nm.group(1))
        ctors[name] = (names, required, start + cm.start(), f)

for f in files:
    c = code[f]
    for cls, info in ctors.items():
        if info is None: continue
        names, required, defoff, deffile = info
        for m in re.finditer(r'(?<![\w.])(?:const\s+|new\s+)?' + cls + r'\s*\(', c):
            if f == deffile and abs(m.start() - defoff) < 8: continue
            if re.match(r'\s*(class|extends|implements|with)\b', c[max(0, m.start()-12):m.start()]): continue
            po = m.end() - 1
            pc = match_paren(c, po)
            if pc < 0: continue
            args = c[po + 1:pc]
            given = set()
            for seg in split_top(args):
                nm = re.match(r'\s*(\w+)\s*:(?!:)', seg)
                if nm: given.add(nm.group(1))
            line = c.count('\n', 0, m.start()) + 1
            for g in given - names - {'key'}:
                err(f, f'line {line}: {cls}(...) has no named parameter "{g}"')
            for r in required - given:
                err(f, f'line {line}: {cls}(...) missing required "{r}"')

# ---------------------------------------------------------------- members
def class_members(f, cls):
    c = code[f]
    m = re.search(r'\bclass\s+' + cls + r'\b[^{;]*\{', c)
    if not m: return set()
    end = match_paren(c, m.end() - 1)
    body = c[m.end():end]
    members = set()
    # depth-1 declarations only
    depth, line_start, buf = 0, 0, ''
    top = ''
    for ch in body:
        if ch in '({[': depth += 1
        if depth == 0: top += ch
        else: top += ' ' if ch not in '({[' else ch
        if ch in ')}]': depth -= 1
    for mm in re.finditer(r'(?:static\s+)?(?:final\s+|const\s+|late\s+)*(?:[\w<>?,\[\]]+\s+)*?(?:get\s+|set\s+)?(\w+)\s*(?:\(|=|;|=>)', top):
        members.add(mm.group(1))
    # fields declared as `final Type name;` and public/private both
    for mm in re.finditer(r'\b(\w+)\s*;', top):
        members.add(mm.group(1))
    # constructor params that are fields (this.x)
    for mm in re.finditer(r'this\.(\w+)', c[m.end():end]):
        members.add(mm.group(1))
    return members

SVC = {'AuthService','AccountService','TransactionService','BudgetService','GoalService',
       'NotificationService','SettingsService','FinanceCoordinator','StorageService'}
svc_members = {}
for s in SVC:
    f = defs.get(s)
    if f: svc_members[s] = class_members(f, s) | {'addListener','removeListener','notifyListeners','dispose','hasListeners'}

OBJ_COMMON = {'toString','hashCode','runtimeType'}
for f in files:
    c = code[f]
    var_type = {}
    for m in re.finditer(r'(?:final|var)\s+(\w+)\s*=\s*context\.(?:read|watch)<(\w+)>\(\)\s*;', c):
        var_type[m.group(1)] = m.group(2)
    # direct chains
    for m in re.finditer(r'context\.(?:read|watch)<(\w+)>\(\)\.(\w+)', c):
        t, mem = m.groups()
        if t in svc_members and mem not in svc_members[t]:
            err(f, f'{t} has no member "{mem}"')
    for v, t in var_type.items():
        if t not in svc_members: continue
        decls = len(re.findall(r'\b(?:final|var)\s+' + v + r'\b', c)) + len(re.findall(r'\b[A-Z]\w*(?:<[^>]*>)?\??\s+' + v + r'\s*[,)=]', c))
        if decls != 1: continue
        for m in re.finditer(r'(?<![\w.])' + v + r'\.(\w+)', c):
            if m.group(1) not in svc_members[t] and m.group(1) not in OBJ_COMMON:
                err(f, f'{v}.{m.group(1)}: {t} has no member "{m.group(1)}"')

STATIC = ['Fmt','Validators','Categories','FinanceCalculator','AppConstants','CryptoUtils','IdGen','AmountParser','AppTheme','StorageService']
smembers = {}
for s in STATIC:
    f = defs.get(s)
    if f: smembers[s] = class_members(f, s)
for f in files:
    for s, mem in smembers.items():
        for m in re.finditer(r'(?<![\w.])' + s + r'\.(\w+)', code[f]):
            if m.group(1) not in mem and m.group(1) != 'instance':
                err(f, f'{s}.{m.group(1)} is not declared in {s}')

# ---------------------------------------------------------------- report
for w in sorted(set(warns)): print('warn :', w)
for e in sorted(set(errors)): print('ERROR:', e)
print(f'\nchecked {len(files)} files: {len(set(errors))} error(s), {len(set(warns))} warning(s)')
sys.exit(1 if errors else 0)

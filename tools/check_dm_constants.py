"""Check constant references and preserve the original ABAP token stream.

This is a refactoring regression check, not an ABAP compiler. Expected token
hashes come from main fc30682 before replacing domain literals with constants.
"""
from pathlib import Path
import hashlib
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'src'
TOKEN = re.compile(
    r"(?m)^\*[^\n]*|\"[^\n]*|'(?:[^']|'')*'|`(?:[^`]|``)*`|\|[^|]*\||"
    r"[A-Za-z_%][A-Za-z0-9_%]*|\d+|[^\s]"
)
REF = re.compile(r'@?yif_dm_constants=>c_(\w+)-(\w+)', re.I)


def tokens(source):
    return [("'X'" if m.group().lower() == 'abap_true' else m.group())
            for m in TOKEN.finditer(source)
            if not m.group().startswith(('"', '*'))]


def digest(source):
    return hashlib.sha256(json.dumps(tokens(source), ensure_ascii=False).encode()).hexdigest()


def constants():
    source = (SRC / 'yif_dm_constants.intf.abap').read_text()
    result = {}
    for group, body in re.findall(r'BEGIN OF c_(\w+),(.*?)END OF c_\1\.', source, re.S):
        for name, length, value in re.findall(
                r"(\w+) TYPE c LENGTH (\d+) VALUE '((?:[^']|'')*)'", body):
            assert int(length) == len(value.replace("''", "'")), (group, name)
            result[f'c_{group}-{name}'.lower()] = "'" + value + "'"
    assert result, 'No constants parsed'
    return result


def validate():
    values = constants()
    expected = json.loads((ROOT / 'tools/dm-constant-baseline.json').read_text())
    references = 0
    for name, expected_hash in expected['files'].items():
        source = (SRC / name).read_text(encoding='utf-8-sig')

        def expand(match):
            nonlocal references
            references += 1
            key = f'c_{match[1]}-{match[2]}'.lower()
            assert key in values, f'{name}: undefined constant {key}'
            return values[key]

        expanded = REF.sub(expand, source)
        assert digest(expanded) == expected_hash, f'{name}: code changed beyond literal substitution'
        original_tokens = tokens(source)
        if not name.endswith('.testclasses.abap'):
            literals = set(values.values())
            assert not any(t in literals for t in original_tokens), f'{name}: domain literal remains'
        assert all(len(line) <= 255 for line in source.splitlines()), f'{name}: line exceeds 255'
    for name, expected_hash in expected.get('excluded_files', {}).items():
        source = (SRC / name).read_text(encoding='utf-8-sig')
        assert digest(source) == expected_hash, f'{name}: excluded Z object was modified'
        assert not REF.search(source), f'{name}: excluded Z object depends on the new interface'
    tree = ET.parse(SRC / 'yif_dm_constants.intf.xml')
    assert tree.findtext('.//CLSNAME') == 'YIF_DM_CONSTANTS'
    print(f'{len(expected["files"])} ABAP sources unchanged after expanding {references} references; '
          f'{len(values)} constants defined; no remaining domain literals in Y production classes; Z sources unchanged.')


if __name__ == '__main__':
    validate()

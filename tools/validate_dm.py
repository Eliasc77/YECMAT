#!/usr/bin/env python3
"""Validate the DM repository contract; no SAP activation or ABAP compiler."""
from pathlib import Path
import json
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PREFIX = 'YMMT_DM_'
KEYS = {
    'FLUJO': 'FLUJO_ID', 'FLUJO_VR': 'FLUJO_ID VERSION',
    'PASO': 'FLUJO_ID VERSION PASO_ID', 'SOL': 'SOLICITUD_UUID',
    'TAREA': 'TAREA_UUID', 'SEG': 'SEGMENTO_UUID',
    'SEG_CEN': 'SEGMENTO_UUID', 'SEG_ALM': 'SEGMENTO_UUID',
    'SEG_VEN': 'SEGMENTO_UUID', 'SEG_VAL': 'SEGMENTO_UUID',
    'SEG_UOM': 'SEGMENTO_UUID', 'CAMPO': 'CAMPO_ID',
    'SECCION': 'SECCION_ID', 'REGLA': 'REGLA_UUID',
    'DATO': 'SEGMENTO_UUID CAMPO_ID',
}
STANDARD = {
    'MANDT', 'SYSUUID_X16', 'MTART', 'MATNR', 'WERKS_D', 'LGORT_D',
    'VKORG', 'VTWEG', 'BWKEY', 'BWTAR_D', 'MEINS', 'SYUNAME',
    'TIMESTAMPL', 'BOOLE_D', 'TABNAME', 'FIELDNAME',
}


class ValidationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ValidationError(message)


def validate(root=ROOT):
    root = Path(root)
    doc = root / 'docs/arquitectura'
    model = json.loads((doc / 'modelo_dm.json').read_text())
    tables = model['tables']
    require(set(tables) == {PREFIX + n for n in KEYS}, 'Expected exactly 15 model tables')
    paths = list((root / 'src').rglob('*.tabl.xml'))
    require(len(paths) == 15, 'Expected exactly 15 TABL definitions')
    xmls = {}
    for path in paths:
        tree = ET.parse(path)
        name = tree.findtext('.//DD02V/TABNAME')
        require(name not in xmls, f'Duplicate table {name}')
        require(path.name == name.lower() + '.tabl.xml', f'Filename mismatch: {path}')
        require(tree.getroot().get('serializer') == 'LCL_OBJECT_TABL', f'Serializer {name}')
        xmls[name] = tree
    require(set(xmls) == set(tables), 'XML/model table set differs')

    dictionary = (doc / 'DICCIONARIO_DATOS.md').read_text()
    relation_edges = []
    field_count = fk_count = index_count = 0
    for name, spec in tables.items():
        tree = xmls[name]
        require(tree.findtext('.//DD02V/TABCLASS') == 'TRANSP', f'Transparent table {name}')
        require(tree.findtext('.//DD02V/CLIDEP') == 'X', f'Client dependency {name}')
        require(tree.find('.//DD02V/LANGDEP') is None, f'Unexpected language dependency {name}')
        require(tree.findtext('.//DD02V/CONTFLAG') == spec['delivery_class'], f'Delivery class {name}')
        require(tree.findtext('.//DD09L/BUFALLOW') == 'N', f'Buffering {name}')
        require(tree.find('.//ABAP_LANGUAGE_VERSION') is None, f'Cloud restriction {name}')
        declared = spec['fields']
        expected_pk = ['MANDT'] + KEYS[name[len(PREFIX):]].split()
        require([f['name'] for f in declared if f['key']] == expected_pk, f'Model PK {name}')
        fields = tree.findall('.//DD03P_TABLE/DD03P')
        names = [f.findtext('FIELDNAME') for f in fields]
        require(len(set(names)) == len(names), f'Duplicate field {name}')
        require(names == [f['name'] for f in declared], f'Fields/order {name}')
        actual_pk = [f.findtext('FIELDNAME') for f in fields if f.findtext('KEYFLAG') == 'X']
        require(actual_pk == expected_pk, f'PK {name}')
        require(names[:len(actual_pk)] == actual_pk, f'Non-contiguous PK {name}')
        require(len(name) <= 16, f'DDIC table name length {name}')
        section = dictionary.split('## ' + name + '\n', 1)[1].split('\n## ', 1)[0]
        for actual, expected in zip(fields, declared):
            col, typ = expected['name'], expected['type']
            field_count += 1
            require(actual.findtext('NOTNULL') == 'X', f'NOTNULL {name}.{col}')
            require(f'| `{col}` | `{typ}` |' in section, f'Dictionary {name}.{col}')
            if typ.startswith('CHAR'):
                size = int(typ[4:])
                require(0 < size <= 1333, f'CHAR bound {name}.{col}')
                require(actual.findtext('DATATYPE') == 'CHAR', f'Type {name}.{col}')
                require(int(actual.findtext('LENG', '0')) == size, f'Length {name}.{col}')
                require(int(actual.findtext('INTLEN', '0')) == 2 * size, f'Unicode length {name}.{col}')
                require(actual.findtext('INTTYPE') == 'C', f'Internal type {name}.{col}')
                require(actual.find('ROLLNAME') is None, f'Conflicting data element {name}.{col}')
            elif typ in {'INT4', 'DATS'}:
                inttype, intlen, leng = ('I', 4, 10) if typ == 'INT4' else ('D', 16, 8)
                require(actual.findtext('DATATYPE') == typ, f'Type {name}.{col}')
                require(actual.findtext('INTTYPE') == inttype, f'Internal type {name}.{col}')
                require(int(actual.findtext('INTLEN', '0')) == intlen, f'Internal length {name}.{col}')
                require(int(actual.findtext('LENG', '0')) == leng, f'Length {name}.{col}')
            else:
                require(typ in STANDARD, f'Unrecognized standard element {typ}')
                require(actual.findtext('ROLLNAME') == typ, f'Data element {name}.{col}')
                require(actual.findtext('COMPTYPE') == 'E', f'Element component {name}.{col}')
                require(actual.find('DATATYPE') is None, f'Overridden standard element {name}.{col}')
            if col.endswith('_UUID'):
                require(typ == 'SYSUUID_X16', f'UUID type {name}.{col}')

        foreign = tree.findall('.//DD08V_TABLE/DD08V')
        mappings = tree.findall('.//DD05M_TABLE/DD05M')
        require(len(foreign) == len(spec['foreign_keys']), f'FK count {name}')
        require(len(mappings) == sum(len(f['fields']) for f in spec['foreign_keys']), f'FK mapping count {name}')
        for fk in spec['foreign_keys']:
            fk_count += 1
            parent, cols, anchor = fk['parent'], fk['fields'], fk['anchor']
            require(parent in tables, f'Unknown FK parent {name}')
            parent_fields = tables[parent]['fields']
            require(cols == [f['name'] for f in parent_fields if f['key']], f'Incomplete parent PK {name}')
            require(cols[0] == 'MANDT', f'Missing FK client {name}')
            child_types = {f['name']: f['type'] for f in declared}
            parent_types = {f['name']: f['type'] for f in parent_fields}
            require(all(child_types.get(c) == parent_types[c] for c in cols), f'FK type mismatch {name}')
            headers = [f for f in foreign if f.findtext('FIELDNAME') == anchor]
            require(len(headers) == 1, f'FK header {name}.{anchor}')
            header = headers[0]
            require(header.findtext('CHECKTABLE') == parent, f'FK target {name}.{anchor}')
            category = 'KEY' if set(cols) <= set(actual_pk) else 'REF'
            require(header.findtext('FRKART') == category, f'FK category {name}.{anchor}')
            require(header.findtext('CARDLEFT') == '1', f'FK parent cardinality {name}')
            require(header.findtext('CARD') == ('C' if fk['cardinality'] == '0..1' else 'CN'), f'FK cardinality {name}')
            rows = [f for f in mappings if f.findtext('FIELDNAME') == anchor]
            require(len(rows) == len(cols), f'FK rows {name}.{anchor}')
            for pos, (row, col) in enumerate(zip(rows, cols), 1):
                expected = {'FORTABLE': name, 'FORKEY': col, 'CHECKTABLE': parent,
                            'CHECKFIELD': col, 'PRIMPOS': f'{pos:04}'}
                require(all(row.findtext(k) == v for k, v in expected.items()), f'FK mapping {name}.{anchor}.{col}')
            field = fields[names.index(anchor)]
            require(field.findtext('CHECKTABLE') == parent, f'Field check table {name}.{anchor}')
            relation_edges.append((parent, '||--o|' if fk['cardinality'] == '0..1' else '||--o{', name))

        headers = tree.findall('.//DD12V/DD12V')
        rows = tree.findall('.//DD17V/DD17V')
        require(len(headers) == len(spec['indexes']), f'Index count {name}')
        require(len(rows) == sum(len(i['fields']) for i in spec['indexes']), f'Index field count {name}')
        for idx in spec['indexes']:
            index_count += 1
            require(idx['fields'][0] == 'MANDT', f'Index client {name}')
            require(len(set(idx['fields'])) == len(idx['fields']), f'Index duplicate column {name}')
            require(set(idx['fields']) <= set(names), f'Index unknown column {name}')
            match = [i for i in headers if i.findtext('INDEXNAME') == idx['name']]
            require(len(match) == 1, f'Index header {name}.{idx["name"]}')
            require(match[0].findtext('SQLTAB') == name, f'Index table {name}')
            require((match[0].findtext('UNIQUEFLAG') == 'X') == idx['unique'], f'Index uniqueness {name}')
            members = [i for i in rows if i.findtext('INDEXNAME') == idx['name']]
            require([i.findtext('FIELDNAME') for i in members] == idx['fields'], f'Index columns {name}')
            require(all(i.findtext('SQLTAB') == name and i.findtext('POSITION') == f'{pos:04}'
                        for pos, i in enumerate(members, 1)), f'Index positions {name}')

    # Preserve the functional uniqueness choices even if the JSON is accidentally weakened.
    for suffix, unique_cols in {
        'SOL': ['MANDT', 'NUMERO_SOLICITUD'],
        'TAREA': ['MANDT', 'SOLICITUD_UUID', 'FLUJO_ID', 'VERSION', 'PASO_ID'],
        'REGLA': ['MANDT', 'FLUJO_ID', 'VERSION', 'AREA', 'CAMPO_ID'],
    }.items():
        require(any(i['unique'] and i['fields'] == unique_cols for i in tables[PREFIX + suffix]['indexes']), f'Required unique index {suffix}')

    der = (doc / 'DER_DM.mmd').read_text()
    blocks = re.findall(r'^    (YMMT_DM_\w+) \{\n(.*?)^    \}', der, re.M | re.S)
    require(len(blocks) == 15 and {b[0] for b in blocks} == set(tables), 'DER entity set')
    for name, body in blocks:
        actual = [line.split() for line in body.splitlines() if line.strip()]
        expected = []
        for field in tables[name]['fields']:
            col = field['name']
            tags = (['PK'] if field['key'] else [])
            if any(col in fk['fields'] for fk in tables[name]['foreign_keys']):
                tags.append('FK')
            if name == PREFIX + 'SOL' and col == 'NUMERO_SOLICITUD':
                tags.append('UK')
            expected.append([field['type'], col.lower()] + ([','.join(tags)] if tags else []))
        require(actual == expected, f'DER fields/keys {name}')
    parsed = re.findall(r'^    (YMMT_DM_\w+) (\|\|--o[|{]) (YMMT_DM_\w+) : (\w+)$', der, re.M)
    require(len(parsed) == 16, 'DER relation count')
    require(sorted((a, b, c) for a, b, c, _ in parsed) == sorted(relation_edges), 'DER FK edges')
    require(sorted(parsed) == sorted((r['parent'], r['cardinality'], r['child'], r['label']) for r in model['relations']), 'DER relation contract')
    for path in (root / 'src').iterdir():
        require(path.name == 'package.devc.xml' or path.name.startswith('ymmt_dm_'), f'Legacy source remains: {path.name}')
    return f'OK: 15 tables, {field_count} fields, {fk_count} foreign keys, {index_count} indexes, 16 DER relations'


if __name__ == '__main__':
    try:
        print(validate())
    except (ValidationError, ET.ParseError, KeyError, ValueError, OSError, IndexError) as exc:
        print(f'FAIL: {exc}', file=sys.stderr)
        sys.exit(1)

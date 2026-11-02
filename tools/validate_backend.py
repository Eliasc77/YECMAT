"""Static repository checks only; not an ABAP compiler or a replacement for ADT."""
from pathlib import Path
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'src'

def validate():
    for path in SRC.glob('*.xml'):
        ET.parse(path)
    tables = {p.stem.split('.')[0].upper() for p in SRC.glob('*.tabl.xml')}
    assert tables == {'YMMT_DM_CFG_CTL', 'YMMT_DM_CFG_USR'}, tables
    assert not any('ymmt_dm_cfg_log' in p.read_text().lower() for p in SRC.glob('*')), 'CFG_LOG must not be a dependency'
    for path in SRC.glob('*.tabl.xml'):
        tree = ET.parse(path)
        fields = tree.findall('.//DD03P')
        assert fields[0].findtext('FIELDNAME') == 'MANDT'
        assert fields[0].findtext('KEYFLAG') == 'X'
    protected = ['ymmt_dm_campo', 'ymmt_dm_seccion', 'ymmt_dm_flujo', 'ymmt_dm_flujo_vr', 'ymmt_dm_paso', 'ymmt_dm_regla']
    for table in protected:
        assert not (SRC / (table + '.tabl.xml')).exists(), 'Never redefine existing configuration tables'
    for name in ['ybp_i_dm_cfg.clas.locals_imp.abap', 'ycl_dm_cfg_store.clas.abap', 'ycl_dm_cfg_model.clas.abap']:
        source = (SRC / name).read_text()
        code = '\n'.join(line for line in source.splitlines() if not line.lstrip().startswith('"'))
        assert not re.search(r'\b(COMMIT|ROLLBACK)\s+(WORK|ENTITIES)\b', code, re.I), name
        assert not re.search(r'\bDELETE\s+FROM\b', code, re.I), name
    action = (SRC / 'yd_dm_cfg_cmd.ddls.asddls').read_text()
    actual = re.findall(r'^\s+(\w+)\s*:', action, re.M)
    assert set(actual) == set(json.loads((ROOT / 'docs/action-parameters.json').read_text()))
    projection = (SRC / 'yc_dm_cfg.bdef.asbdef').read_text()
    assert 'use action Aplicar' in projection and 'use update' not in projection
    behavior = (SRC / 'yi_dm_cfg.bdef.asbdef').read_text()
    assert 'etag master LastChangedAt' in behavior and 'lock master' in behavior and 'additional save' in behavior
    handler = (SRC / 'ybp_i_dm_cfg.clas.locals_imp.abap').read_text()
    assert 'ycl_dm_cfg_store=>is_admin( )' in handler
    store = (SRC / 'ycl_dm_cfg_store.clas.abap').read_text()
    assert all('INSERT ' + table in store for table in protected)
    for name in ['campo', 'seccion', 'flujo', 'flujo_vr', 'paso', 'regla']:
        source = (SRC / ('ya_dm_' + name + '.ddls.asddls')).read_text()
        assert "Access.user_name = $session.user and Access.active = 'X'" in source
    for view in ['i', 'c']:
        assert (SRC / ('yr_' + view + '_dm_cfg.dcls.asdcls')).exists()
    print('Backend static checks passed: existing tables preserved; isolated admin service, allowlist, locks/ETag, no commits/deletes in RAP.')

if __name__ == '__main__':
    validate()

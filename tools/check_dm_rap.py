"""Repository contract checks for the RAP migration; not an ABAP compiler."""
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'src'
BASE = 'e415d2f352f0a5a131cb577a2cfc97dad99476c8'
SUFFIXES = ['campo', 'seccion', 'flujo', 'flujo_vr', 'paso', 'regla']
NS = '{http://www.sap.com/abapxml}'


def validate():
    for path in SRC.glob('*.xml'):
        ET.parse(path)
    for suffix in SUFFIXES:
        active = ET.parse(SRC / f'ymmt_dm_{suffix}.tabl.xml')
        fields = active.findall('.//DD03P_TABLE/DD03P')
        original = ET.fromstring(subprocess.check_output(
            ['git', 'show', f'{BASE}:src/ymmt_dm_{suffix}.tabl.xml'], cwd=ROOT))
        previous = original.findall('.//DD03P_TABLE/DD03P')
        # Every old column, key and data type stays intact; audit fields are appended.
        assert len(fields) == len(previous) + 2, suffix
        for old, new in zip(previous, fields):
            assert [(n.tag, n.text) for n in old] == [(n.tag, n.text) for n in new], suffix
        assert [f.findtext('FIELDNAME') for f in fields[-2:]] == ['LAST_CHANGED_AT', 'LOCAL_LAST_CHANGED_AT']
        draft = ET.parse(SRC / f'ymmt_dm_d_{suffix}.tabl.xml')
        names = [f.findtext('FIELDNAME') for f in draft.findall('.//DD03P_TABLE/DD03P')]
        assert len(names) == len(set(names)), suffix
        assert names[-1] == '.INCLUDE' and 'DRAFTUUID' in names
        assert draft.findtext('.//DD03P[FIELDNAME=".INCLUDE"]/PRECFIELD') == 'SYCH_BDL_DRAFT_ADMIN_INC'
        view = (SRC / f'yi_dm_m_{suffix}.ddls.asddls').read_text()
        aliases = re.findall(r'Data\.\w+ as (\w+)', view)
        assert set(names) == {'MANDT', 'DRAFTUUID', '.INCLUDE'} | {a.upper() for a in aliases}, suffix
        projection = (SRC / f'yc_dm_m_{suffix}.ddls.asddls').read_text()
        assert 'provider contract transactional_query' in projection
        assert 'localInstanceLastChangedAt: true' in view
        assert 'lastChangedAt: true' in view
        ui = (SRC / f'yc_dm_m_{suffix}_ui.ddlx.asddlxs').read_text()
        assert '@UI.lineItem:' in ui and '@UI.identification:' in ui
    control = ET.parse(SRC / 'ymmt_dm_cfg_ctl.tabl.xml')
    original_control = ET.fromstring(subprocess.check_output(
        ['git', 'show', f'{BASE}:src/ymmt_dm_cfg_ctl.tabl.xml'], cwd=ROOT))
    old_fields = original_control.findall('.//DD03P_TABLE/DD03P')
    new_fields = control.findall('.//DD03P_TABLE/DD03P')
    assert len(new_fields) == len(old_fields) + 1
    assert new_fields[-1].findtext('FIELDNAME') == 'RAP_ACTIVO'
    for old, new in zip(old_fields, new_fields):
        assert [(n.tag, n.text) for n in old] == [(n.tag, n.text) for n in new]
    for root in ['campo', 'seccion', 'flujo']:
        bdef = (SRC / f'yi_dm_m_{root}.bdef.asbdef').read_text()
        assert 'with draft;' in bdef and 'total etag LastChangedAt' in bdef
        assert 'etag master LocalLastChangedAt' in bdef and 'lock master unmanaged' in bdef
        assert 'create ( precheck );' in bdef
        assert not re.search(r'^\s*delete\s*;', bdef, re.M)
        projection = (SRC / f'yc_dm_m_{root}.bdef.asbdef').read_text()
        assert 'use draft;' in projection and 'use etag' in projection
        handler = (SRC / f'ybp_i_dm_m_{root}.clas.locals_imp.abap').read_text()
        assert 'SET LOCKS OF yi_dm_cfg' in handler
        assert 'FOR LOCK IMPORTING keys FOR LOCK' in handler
        assert 'ycl_dm_mnt_model=>validar(' in handler
        assert 'ycl_dm_mnt_trans=>registrar(' in handler
        assert handler.count('ycl_dm_mnt_trans=>limpiar( )') == 3
        assert not re.search(r'\b(COMMIT|ROLLBACK)\s+WORK\b', handler)
        assert not re.search(r'\b(INSERT|UPDATE|DELETE)\s+ymmt_', handler, re.I)
    aggregate = (SRC / 'yi_dm_m_flujo.bdef.asbdef').read_text()
    assert all(f'validation {alias}~validar;' in aggregate for alias in ['Version', 'Paso', 'Regla'])
    service = (SRC / 'yui_dm_mnt_o4.srvd.srvdsrv').read_text()
    assert len(re.findall(r'\bexpose\b', service)) == 6
    old = (SRC / 'ybp_i_dm_cfg.clas.locals_imp.abap').read_text()
    assert old.index('IF rap_activo = abap_true') < old.index('ycl_dm_cfg_model=>plan(')
    setup = (SRC / 'ycl_dm_mnt_setup.clas.abap').read_text()
    assert setup.index('SET LOCKS OF yi_dm_cfg') < setup.index('UPDATE ymmt_dm_')
    assert 'WHERE local_last_changed_at = 0' in setup
    assert 'WHERE config_id = @id AND rap_activo = @abap_false' in setup
    tests = (SRC / 'ycl_dm_mnt_model.clas.testclasses.abap').read_text()
    assert len(re.findall(r'METHODS \w+ FOR TESTING', tests)) == 11
    for path in SRC.glob('y*.abap'):
        assert all(len(line) <= 255 for line in path.read_text(encoding='utf-8-sig').splitlines()), path.name
    for path in SRC.glob('z*'):
        original = subprocess.check_output(['git', 'show', f'{BASE}:src/{path.name}'], cwd=ROOT)
        assert path.read_bytes() == original, path.name
    print('RAP contracts passed: additive schema, six drafts, three roots, ETags, safe cutover, annotations, Z objects unchanged.')


if __name__ == '__main__':
    validate()

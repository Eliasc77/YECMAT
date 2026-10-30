#!/usr/bin/env python3
"""Cross-object RAP contract checks, complementing the ABAP/CDS/BDEF parsers."""
import json
from pathlib import Path
import re
import xml.etree.ElementTree as E
from tools.validate_dm import ROOT, ValidationError, require

ROOTS={'SOL':'Solicitud','SEG':'Segmento','TAREA':'Tarea','DATO':'Dato'}
CONFIG={'FLUJO','FLUJO_VR','PASO','CAMPO','SECCION','REGLA'}
SUBS={'CEN':'Centro','ALM':'Almacen','VEN':'Ventas','VAL':'Valoracion','UOM':'Unidad'}

def aliases(col):
    special={'UUID':'UUID','ID':'Id','BPM':'Bpm','SAP':'Sap','UOM':'Uom'}
    return ''.join(special.get(p,p.title()) for p in col.split('_'))

def validate(root=ROOT):
    root=Path(root); src=root/'src'
    model=json.loads((root/'docs/arquitectura/modelo_dm.json').read_text())
    tables=model['tables']
    for path in src.glob('*.xml'):
        E.parse(path)
    for name, spec in tables.items():
        suffix=name[8:]
        i=(src/('yi_dm_'+suffix.lower()+'.ddls.asddls')).read_text()
        c=(src/('yc_dm_'+suffix.lower()+'.ddls.asddls')).read_text()
        # Compare the scalar schema with persistence, not a golden generated file.
        actual=re.findall(r'(?:key\s+)?Data\.(\w+) as (\w+)', i)
        expected=[(f['name'].lower(),aliases(f['name'])) for f in spec['fields'] if f['name']!='MANDT']
        require(actual==expected,f'CDS scalar contract {suffix}')
        require(name.lower()+' as Data' in i,f'CDS persistence source {suffix}')
        for _,alias in expected:
            require(re.search(r'\b'+alias+r'\b',c), f'Projection field {suffix}.{alias}')
        require('mandt' not in c.lower(), f'Public client field {suffix}')
        require('@UI.' not in i+c,f'Static UI contract {suffix}')
        for layer in ['i','c']:
            role=src/f'yr_{layer}_dm_{suffix.lower()}.dcls.asdcls'
            if suffix not in CONFIG:
                require(role.exists(),f'Missing DCL {layer}/{suffix}')
                text=role.read_text()
                require(f'grant select on Y{layer.upper()}_DM_{suffix}' in text,f'DCL entity {suffix}')
                require(' where ' in text,f'Unrestricted grant {suffix}')
        if suffix in ROOTS:
            b=(src/('yi_dm_'+suffix.lower()+'.bdef.asbdef')).read_text()
            projection=(src/('yc_dm_'+suffix.lower()+'.bdef.asbdef')).read_text()
            require('authorization master ( global, instance )' in b,f'Authorization {suffix}')
            require('lock master' in b,f'Lock {suffix}')
            etag='ModificadoEl' if suffix=='DATO' else 'LastChangedAt'
            require('etag master '+etag in b,f'ETag master {suffix}')
            require('use etag' in projection, f'Projection ETag {suffix}')
            require('@Semantics.systemDateTime.localInstanceLastChangedAt: true' in i,f'ETag semantics {suffix}')
            own_block=b.split('mapping for ',1)[1].split('}',1)[0]
            mappings=re.findall(r'(\w+)\s*=\s*(\w+)\s*;',own_block)
            require(mappings==[(alias,col) for col,alias in expected],f'Behavior mapping {suffix}')
            require('delete;' not in b and 'use delete;' not in projection,f'Unsafe root deletion {suffix}')
            require('validation ' in b,f'Missing save validation {suffix}')
            pool=src/('ybp_i_dm_'+suffix.lower()+'.clas.locals_imp.abap')
            require(pool.exists(),f'Missing behavior pool {suffix}')
            code=pool.read_text()
            methods=re.findall(r'\bMETHOD\s+(\w+)\.',code,re.I)
            for method in re.findall(r'(?:determination|validation)\s+(\w+)', b):
                require(method.lower() in [m.lower() for m in methods],f'Missing handler {suffix}.{method}')
            if suffix=='SEG':
                for sub,alias in SUBS.items():
                    target='YC_DM_SEG_'+sub
                    require('_'+alias+' : redirected to composition child '+target in c,f'Composition projection {sub}')
                    child=(src/('yc_dm_seg_'+sub.lower()+'.ddls.asddls')).read_text()
                    require('_Segmento : redirected to parent YC_DM_SEG' in child,f'Parent projection {sub}')
        for forbidden in ['COMMIT WORK','ROLLBACK WORK','CALL FUNCTION','CALL TRANSACTION','UPDATE ymmt_dm_', 'INSERT ymmt_dm_', 'DELETE FROM']:
            for file in src.glob('*.abap'):
                require(forbidden.lower() not in file.read_text().lower(), f'Forbidden transaction/API in {file.name}')
    service=(src/'yui_dm_o4.srvd.srvdsrv').read_text()
    exposed=re.findall(r'expose\s+(\w+)\s+as\s+(\w+)',service)
    require(len(exposed)==15 and len({e[0] for e in exposed})==15,'Service entity set')
    require({e[0] for e in exposed}=={'YC_DM_'+n[8:] for n in tables},'Public service projection set')
    access=(src/'yi_dm_dato_usr.ddls.asddls').read_text()
    require("R.estado_campo <> 'I'" in access and 'T.area = R.area' in access,'Field visibility/area isolation')
    helper=(src/'ycl_dm_rules.clas.abap').read_text()
    require("estado_campo = 'O' OR estado_campo = 'M'" in helper,'Backend read-only/invisible rule enforcement')
    require("context-estado <> 'BORRADOR' AND context-estado <> 'EN_CURSO'" in helper,'Closed request guard')
    require('SET LOCKS OF yi_dm_tarea' in helper, 'Shared task locks for value writes')
    data_pool=(src/'ybp_i_dm_dato.clas.locals_imp.abap').read_text()
    require('ycl_dm_rules=>lock_value' in data_pool and 'line_exists( blocked[' in data_pool,
            'Failed lock must prevent value save')
    closing=(src/'ybp_i_dm_sol.clas.locals_imp.abap').read_text().split('  METHOD Cerrar.',1)[1].split('  ENDMETHOD.',1)[0]
    require('SET LOCKS OF yi_dm_tarea' in closing, 'Task locks during close')
    return 'OK: 30 table CDS + 4 support/parameter CDS, 18 DCL, 8 BDEF, 4 behavior pools, 15 service entities'

if __name__=='__main__':
    import sys
    # Support invocation as python3 -m tools.validate_rap from the repository root.
    try: print(validate())
    except (ValidationError,ValueError,KeyError,OSError,E.ParseError) as exc:
        print('FAIL: '+str(exc),file=sys.stderr);sys.exit(1)

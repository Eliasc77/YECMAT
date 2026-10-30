#!/usr/bin/env python3
"""Generate deterministic abapGit RAP artifacts from the reviewed DM contract."""
from pathlib import Path
import json
import xml.etree.ElementTree as E

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'src'; DOC=ROOT/'docs/arquitectura'
NS='http://www.sap.com/abapxml'
E.register_namespace('asx',NS)

def xml_file(name,kind,node,record):
    root=E.Element('abapGit',version='v1.0.0',serializer='LCL_OBJECT_'+kind,serializer_version='v1.0.0')
    val=E.SubElement(E.SubElement(root,'{'+NS+'}abap',version='1.0'),'{'+NS+'}values')
    data=E.SubElement(val,node)
    for k,v in record.items(): E.SubElement(data,k).text=str(v)
    write_xml(SRC/(name.lower()+'.'+kind.lower()+'.xml'),root)

def write_xml(path,root):
    E.indent(root,space=' ')
    path.write_text('<?xml version="1.0" encoding="utf-8"?>\n'+E.tostring(root,encoding='unicode')+'\n')

def source(name,kind,ext,text,label=None):
    (SRC/(name.lower()+'.'+kind.lower()+'.'+ext)).write_text(text.rstrip()+'\n')
    if kind=='DDLS':
        xml_file(name,kind,'DDLS',dict(DDLNAME=name,DDLANGUAGE='E',DDTEXT=label or name,SOURCE_TYPE='W' if 'abstract entity' not in text else 'A'))
    elif kind=='DCLS':
        xml_file(name,kind,'DCLS',dict(DCLNAME=name,DDLANGUAGE='E',DDTEXT=label or name))
    elif kind=='BDEF':
        xml_file(name,kind,'BDEF',dict(NAME=name,TYPE='BDEF/BDO',DESCRIPTION=label or name,DESCRIPTION_TEXT_LIMIT='60',LANGUAGE='EN',MASTER_LANGUAGE='EN',ABAP_LANGU_VERSION='5',SOURCE_TYPE='ABAP_SOURCE',SOURCE_FIXED_POINT_ARITHMETIC='true',SOURCE_UNICODE_CHECKS_ACTIVE='true'))
    elif kind=='SRVD':
        xml_file(name,kind,'SRVD',dict(NAME=name,TYPE='SRVD/SRV',DESCRIPTION=label or name,LANGUAGE='EN',MASTER_LANGUAGE='EN',SOURCE_TYPE='ABAP_SOURCE',SOURCE_ORIGIN_DESCRIPTION='ABAP Development Tools',SRVD_SOURCE_TYPE='S',SRVD_SOURCE_TYPE_DESC='Definition'))

SPECIAL={'UUID':'UUID','ID':'Id','BPM':'Bpm','UOM':'Uom','SAP':'Sap'}
def alias(col): return ''.join(SPECIAL.get(s,s.title()) for s in col.split('_'))
ROOTS={'SOL':'Solicitud','SEG':'Segmento','TAREA':'Tarea','DATO':'Dato'}
SUBS={'CEN':'Centro','ALM':'Almacen','VEN':'Ventas','VAL':'Valoracion','UOM':'Unidad'}
CONFIG={'FLUJO','FLUJO_VR','PASO','CAMPO','SECCION','REGLA'}
ASSOC={'FLUJO':'_Flujo','FLUJO_VR':'_Version','PASO':'_Paso','SOL':'_Solicitud','SEG':'_Segmento','CAMPO':'_Campo','SECCION':'_Seccion'}

def update_tables(model):
    additions={'SOL':[('CLASIFICACION_BPM','CHAR1'),('LAST_CHANGED_AT','ABP_LOCINST_LASTCHANGE_TSTMPL')],
               'SEG':[('CONTEXTO_CLAVE','CHAR100'),('LAST_CHANGED_AT','ABP_LOCINST_LASTCHANGE_TSTMPL')],
               'TAREA':[('LAST_CHANGED_AT','ABP_LOCINST_LASTCHANGE_TSTMPL')]}
    for name,t in model['tables'].items():
        suffix=name[8:]; path=SRC/(name.lower()+'.tabl.xml'); root=E.parse(path).getroot()
        ft=root.find('.//DD03P_TABLE')
        for f in t['fields']:
            old=f['type']; new={'BOOLE_D':'ABAP_BOOLEAN'}.get(old,old)
            if suffix=='DATO' and f['name']=='MODIFICADO_EL': new='ABP_LOCINST_LASTCHANGE_TSTMPL'
            f['type']=new
            if old!=new:
                node=next(n for n in ft if n.findtext('FIELDNAME')==f['name'])
                node.find('ROLLNAME').text=new
        for col,typ in additions.get(suffix,[]):
            if any(f['name']==col for f in t['fields']): continue
            t['fields'].append(dict(name=col,type=typ,key=False))
            node=E.SubElement(ft,'DD03P')
            for k,v in dict(FIELDNAME=col,ADMINFIELD='0',NOTNULL='X').items(): E.SubElement(node,k).text=v
            if typ.startswith('CHAR'):
                size=int(typ[4:])
                data=dict(INTTYPE='C',INTLEN=f'{size*2:06}',DATATYPE='CHAR',LENG=f'{size:06}',MASK='  CHAR')
            else: data=dict(ROLLNAME=typ,COMPTYPE='E')
            for k,v in data.items(): E.SubElement(node,k).text=v
        if suffix=='SEG' and not any(i['name']=='Z02' for i in t['indexes']):
            idx=dict(name='Z02',fields=['MANDT','SOLICITUD_UUID','TIPO_SEGMENTO','CONTEXTO_CLAVE'],unique=True)
            t['indexes'].append(idx)
            head=E.SubElement(root.find('.//DD12V'),'DD12V')
            for k,v in dict(SQLTAB=name,INDEXNAME='Z02',AS4LOCAL='A',DDLANGUAGE='E',UNIQUEFLAG='X',DDTEXT='DM contexto unico').items(): E.SubElement(head,k).text=v
            for pos,col in enumerate(idx['fields'],1):
                row=E.SubElement(root.find('.//DD17V'),'DD17V')
                for k,v in dict(SQLTAB=name,INDEXNAME='Z02',POSITION=f'{pos:04}',AS4LOCAL='A',FIELDNAME=col).items(): E.SubElement(row,k).text=v
        write_xml(path,root)
    (DOC/'modelo_dm.json').write_text(json.dumps(model,ensure_ascii=False,indent=2)+'\n')

def documents(model):
    der=['erDiagram','']+[f"    {r['parent']} {r['cardinality']} {r['child']} : {r['label']}" for r in model['relations']]+['']
    old=(DOC/'DICCIONARIO_DATOS.md').read_text(); dictionary=[old.split('## YMMT_DM_FLUJO\n')[0].rstrip(),'']
    for name,t in model['tables'].items():
        der += [f'    {name} {{']
        dictionary += ['## '+name,'',t['description']+'. Clase de entrega `'+t['delivery_class']+'`.','','| Campo | Tipo DDIC | Clave / referencia |','|---|---|---|']
        for f in t['fields']:
            tags=['PK'] if f['key'] else []
            refs=[fk['parent'] for fk in t['foreign_keys'] if f['name'] in fk['fields']]
            if refs: tags.append('FK')
            if name=='YMMT_DM_SOL' and f['name']=='NUMERO_SOLICITUD': tags.append('UK')
            der += ['        '+f['type']+' '+f['name'].lower()+(' '+','.join(tags) if tags else '')]
            dictionary += [f"| `{f['name']}` | `{f['type']}` | "+(', '.join(tags) or '—')+(' → '+', '.join('`'+r+'`' for r in refs) if refs else '')+' |']
        der += ['    }','']; dictionary += ['']
        for idx in t['indexes']:
            dictionary += [f"- Índice `{idx['name']}` "+('único' if idx['unique'] else 'no único')+': `'+', '.join(idx['fields'])+'`.']
        dictionary += ['']
    (DOC/'DER_DM.mmd').write_text('\n'.join(der).rstrip()+'\n')
    (DOC/'DICCIONARIO_DATOS.md').write_text('\n'.join(dictionary).rstrip()+'\n')

def views(model):
    for name,t in model['tables'].items():
        suffix=name[8:]; is_sub=suffix.startswith('SEG_'); i='YI_DM_'+suffix; c='YC_DM_'+suffix
        kind='root ' if suffix in ROOTS else ''
        annotations=["@EndUserText.label: 'DM "+suffix+"'",'@AccessControl.authorizationCheck: '+('#NOT_REQUIRED' if suffix in CONFIG else '#CHECK')]
        lines=annotations+['define '+kind+'view entity '+i,'  as select from '+name.lower()+' as Data']
        assoc=[]
        for fk in t['foreign_keys']:
            target=fk['parent'][8:]; a=ASSOC[target]
            parent='to parent' if is_sub and target=='SEG' else '[1..1] to'
            on=' and '.join('$projection.'+alias(col)+' = '+a+'.'+alias(col) for col in fk['fields'] if col!='MANDT')
            lines += [f'  association {parent} YI_DM_{target} as {a}', '    on '+on]
            assoc.append((a,target,'parent' if is_sub else 'association'))
        if suffix=='SOL':
            for target,a in [('SEG','_Segmentos'),('TAREA','_Tareas')]:
                lines += [f'  association [0..*] to YI_DM_{target} as {a}',f'    on $projection.SolicitudUUID = {a}.SolicitudUUID']
                assoc.append((a,target,'association'))
        if suffix=='SEG':
            for sub,a in SUBS.items():
                lines += [f'  composition [0..1] of YI_DM_SEG_{sub} as _{a}']
                assoc.append(('_'+a,'SEG_'+sub,'composition'))
        if suffix in {'SOL','DATO'}:
            target='YI_DM_SOL_USR' if suffix=='SOL' else 'YI_DM_DATO_USR'
            key='SolicitudUUID' if suffix=='SOL' else 'SegmentoUUID'
            on=f'$projection.{key} = _Acceso.{key}'
            if suffix=='DATO': on+=' and $projection.CampoId = _Acceso.CampoId'
            lines += [f'  association [0..1] to {target} as _Acceso','    on '+on+' and _Acceso.Usuario = $session.user']
        fields=[]
        for f in t['fields']:
            col=f['name']
            if col=='MANDT': continue
            sem={'CREADO_POR':'user.createdBy','CREADO_EL':'systemDateTime.createdAt',
                 'LAST_CHANGED_AT':'systemDateTime.localInstanceLastChangedAt',
                 'MODIFICADO_EL':'systemDateTime.localInstanceLastChangedAt','MODIFICADO_POR':'user.lastChangedBy'}.get(col)
            if sem: fields.append('      @Semantics.'+sem+': true')
            fields.append(('  key ' if f['key'] else '      ')+'Data.'+col.lower()+' as '+alias(col)+',')
        fields += ['      '+a+',' for a,_,_ in assoc]
        if suffix in {'SOL','DATO'}: fields.append('      _Acceso,')
        fields[-1]=fields[-1].rstrip(',')
        source(i,'DDLS','asddls','\n'.join(lines+['{']+fields+['}']))
        plines=annotations+['define '+kind+'view entity '+c]
        if suffix not in CONFIG: plines += ['  provider contract transactional_query']
        plines += [('  as select from ' if suffix in CONFIG else '  as projection on ')+i,'{']
        plines += [('  key ' if f['key'] else '      ')+alias(f['name'])+',' for f in t['fields'] if f['name']!='MANDT']
        for a,target,atype in ([] if suffix in CONFIG else assoc):
            redir={'parent':'parent ','composition':'composition child '}.get(atype,'')
            plines += [f'      {a} : redirected to {redir}YC_DM_{target},']
        if suffix in {'SOL','DATO'}: plines += ['      _Acceso,']
        plines[-1]=plines[-1].rstrip(',')
        source(c,'DDLS','asddls','\n'.join(plines+['}']))
        if suffix not in CONFIG:
            expr={'SOL':'_Acceso.Usuario','DATO':'_Acceso.Usuario','SEG':'_Solicitud._Acceso.Usuario','TAREA':'_Solicitud._Acceso.Usuario'}.get(suffix,'_Segmento._Solicitud._Acceso.Usuario')
            for entity,condition in [(i,expr+' = $session.user'),(c,'inheriting conditions from entity '+i)]:
                role='YR_'+entity[1]+'_'+entity[3:]
                source(role,'DCLS','asdcls',"@EndUserText.label: 'DM acceso de solicitud'\n@MappingRole: true\ndefine role "+role+' {\n  grant select on '+entity+' where '+condition+';\n}')

    source('YI_DM_SOL_USR','DDLS','asddls',"""@EndUserText.label: 'DM miembros de solicitud'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_SOL_USR
  as select from ymmt_dm_sol
{
  key solicitud_uuid as SolicitudUUID,
  key creado_por as Usuario
}
union select from ymmt_dm_tarea
{
  solicitud_uuid as SolicitudUUID,
  responsable as Usuario
}
where responsable <> ''
""")
    common="""from ymmt_dm_seg as S
    inner join ymmt_dm_sol as H on H.solicitud_uuid = S.solicitud_uuid
    inner join ymmt_dm_campo as C on C.tipo_segmento = S.tipo_segmento
    inner join ymmt_dm_regla as R on R.flujo_id = H.flujo_id
      and R.version = H.version and R.campo_id = C.campo_id"""
    filters="R.activo = 'X' and C.activo = 'X' and R.estado_campo <> 'I'"
    source('YI_DM_DATO_USR','DDLS','asddls',"@EndUserText.label: 'DM acceso por campo y contexto'\n@AccessControl.authorizationCheck: #NOT_REQUIRED\ndefine view entity YI_DM_DATO_USR\n  as select distinct "+common+"\n{\n  key S.segmento_uuid as SegmentoUUID,\n  key C.campo_id as CampoId,\n  key H.creado_por as Usuario\n}\nwhere "+filters+"\nunion select distinct "+common+"\n    inner join ymmt_dm_tarea as T on T.solicitud_uuid = H.solicitud_uuid and T.area = R.area\n{\n  S.segmento_uuid as SegmentoUUID,\n  C.campo_id as CampoId,\n  T.responsable as Usuario\n}\nwhere "+filters+" and T.responsable <> ''\n")
    source('YD_DM_INICIAR','DDLS','asddls',"@EndUserText.label: 'DM clasificacion BPM'\ndefine abstract entity YD_DM_INICIAR {\n  ClasificacionBpm : abap.char(1);\n}")
    source('YD_DM_REABRIR','DDLS','asddls',"@EndUserText.label: 'DM tarea a reabrir'\ndefine abstract entity YD_DM_REABRIR {\n  TareaUUID : abap.raw(16);\n}")
    exposes=[('SOL','Solicitudes'),('SEG','Segmentos'),('TAREA','Tareas'),('DATO','Datos'),('FLUJO','Flujos'),('FLUJO_VR','Versiones'),('PASO','Pasos'),('CAMPO','Campos'),('SECCION','Secciones'),('REGLA','Reglas')]+[('SEG_'+k,'Contexto'+v) for k,v in SUBS.items()]
    source('YUI_DM_O4','SRVD','srvdsrv',"@EndUserText.label: 'DM captura dinamica'\ndefine service YUI_DM_O4 {\n"+'\n'.join(f'  expose YC_DM_{s} as {a};' for s,a in exposes)+'\n}')

def behaviors(model):
    for suffix,a in ROOTS.items():
        i='YI_DM_'+suffix; c='YC_DM_'+suffix
        b=[f'managed implementation in class YBP_I_DM_{suffix} unique;', 'strict ( 2 );','',f'define behavior for {i} alias {a}',f'persistent table ymmt_dm_{suffix.lower()}', 'lock master','authorization master ( global, instance )', 'etag master '+('ModificadoEl' if suffix=='DATO' else 'LastChangedAt'),'{','  create;','  update;']
        fields=model['tables']['YMMT_DM_'+suffix]['fields']
        uuid={'SOL':'SolicitudUUID','SEG':'SegmentoUUID','TAREA':'TareaUUID'}.get(suffix)
        if uuid: b+=['  field ( numbering : managed, readonly ) '+uuid+';']
        if suffix=='SOL':
            b+=['  field ( readonly ) Estado, ClasificacionBpm, CreadoPor, CreadoEl, LastChangedAt;',
                '  field ( mandatory : create, readonly : update ) NumeroSolicitud, TipoMaterial, TipoOperacion, FlujoId, Version;',
                '  field ( readonly : update ) Material;',
                '  determination defaults on modify { create; }',
                '  validation validateRequest on save { create; update; }',
                '  action Iniciar parameter YD_DM_INICIAR result [1] $self;',
                '  action Cerrar result [1] $self;',
                '  action Aprobar result [1] $self;',
                '  action Reabrir parameter YD_DM_REABRIR result [1] $self;']
        elif suffix=='SEG':
            b+=['  field ( readonly ) Estado, ContextoClave, LastChangedAt;',
                '  field ( mandatory : create, readonly : update ) SolicitudUUID, TipoSegmento;',
                '  determination defaults on modify { create; }',
                '  determination context on save { create; }',
                '  validation validateContext on save { create; update; }']
            b+=['  association _'+v+' { create; }' for v in SUBS.values()]
        elif suffix=='TAREA':
            b+=['  field ( readonly ) FlujoId, Version, Area, Estado, CreadoEl, LastChangedAt;',
                '  field ( mandatory : create, readonly : update ) SolicitudUUID, PasoId;',
                '  determination defaults on modify { create; }',
                '  validation validateTask on save { create; update; }',
                '  action Iniciar result [1] $self;', '  action Finalizar result [1] $self;', '  action Reabrir result [1] $self;']
        else:
            b+=['  field ( readonly ) ModificadoPor, ModificadoEl;',
                '  field ( mandatory : create, readonly : update ) SegmentoUUID, CampoId;',
                '  determination audit on modify { create; field Valor; }',
                '  validation validateValue on save { create; update; }']
        b+=['  mapping for ymmt_dm_'+suffix.lower(),'  {']+['    '+alias(f['name'])+' = '+f['name'].lower()+';' for f in fields if f['name']!='MANDT']+['  }','}']
        if suffix=='SEG':
            for sub,sa in SUBS.items():
                child='SEG_'+sub
                b+=['',f'define behavior for YI_DM_{child} alias {sa}',f'persistent table ymmt_dm_{child.lower()}', 'lock dependent by _Segmento','authorization dependent by _Segmento','{','  field ( readonly ) SegmentoUUID;','  association _Segmento;','  validation validateSubtype on save { create; }',f'  mapping for ymmt_dm_{child.lower()}','  {']+['    '+alias(f['name'])+' = '+f['name'].lower()+';' for f in model['tables']['YMMT_DM_'+child]['fields'] if f['name']!='MANDT']+['  }','}']
        source(i,'BDEF','asbdef','\n'.join(b))
        proj=['projection;','strict ( 2 );','',f'define behavior for {c} alias {a}','use etag','{']
        if suffix in {'SOL','SEG','DATO'}: proj+=['  use create;']
        if suffix in {'TAREA','DATO'}: proj+=['  use update;']
        if suffix=='SOL': proj+=['  use action '+x+';' for x in ['Iniciar','Cerrar','Aprobar','Reabrir']]
        if suffix=='TAREA': proj+=['  use action Iniciar;','  use action Finalizar;']
        if suffix=='SEG': proj+=['  use association _'+v+' { create; }' for v in SUBS.values()]
        proj+=['}']
        if suffix=='SEG':
            for sub,sa in SUBS.items(): proj+=['',f'define behavior for YC_DM_SEG_{sub} alias {sa}','{','  use association _Segmento;','}']
        source(c,'BDEF','asbdef','\n'.join(proj))
        name='YBP_I_DM_'+suffix
        xml_file(name,'CLAS','VSEOCLASS',dict(CLSNAME=name,LANGU='E',DESCRIPT='DM behavior '+a,CATEGORY='06',STATE='1',CLSCCINCL='X',FIXPT='X',UNICODE='X',CLSDEFINT=i))
        (SRC/(name.lower()+'.clas.abap')).write_text(f'CLASS {name.lower()} DEFINITION PUBLIC ABSTRACT FINAL\n  FOR BEHAVIOR OF {i.lower()}.\nENDCLASS.\nCLASS {name.lower()} IMPLEMENTATION.\nENDCLASS.\n')

if __name__=='__main__':
    model=json.loads((DOC/'modelo_dm.json').read_text())
    update_tables(model); documents(model); views(model); behaviors(model)
    print('Generated persistence extensions, 34 CDS, 18 DCL, 8 BDEF and OData definition')

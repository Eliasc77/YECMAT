# Inspección, respaldo y limpieza

- Repositorio: `/workspace/YECMAT`; remoto: `https://github.com/Eliasc77/YECMAT.git`.
- Rama de trabajo: `work`; estado inicial limpio, sin cambios ajenos ni archivos sin seguimiento.
- Respaldo local previo a la limpieza: `backup/dm-before-restructure-20261030` → `2d493efcfcfd279ff73cc126e898336066c8708d`.
- Se leyeron todos los archivos versionados (fuentes, XML, documentación y configuración). No hay AGENTS.md en el workspace.
- No se ejecutó ninguna operación sobre un sistema SAP. El respaldo no se publica automáticamente.

## Dependencias inspeccionadas

`ZDM_REQ_H/A/F` → `ZI_DM_Request/AreaTask/FieldValue` → behaviors y pools `ZBP_I_DM_*` → proyecciones `ZC_DM_*`, metadata y `ZUI_DM_O4`.
`ZDM_FIELD_C` alimentaba validaciones de campos; `ZDM_ClassifyP/RejectP` parametrizaban acciones.
`ZDM_AUDIT/OUTBOX` y `ZCL_DM_TRIAL_ACTIVATION` dependían del UUID de solicitud anterior y de su ciclo BTP.
No se encontraron consumidores de otros proyectos en este repositorio; no es posible inventariar consumidores externos en SAP desde Git.
Se retira el conjunto dependiente completo para no dejar fuentes activables con referencias rotas. La reconstrucción de RAP queda pendiente y no se simula mediante vistas vacías.

## Archivos retirados del repositorio

| Archivo | Motivo |
|---|---|
| `config/field-control.sample.csv` | CSV del customizing ZDM_FIELD_C, incompatible con catalogo y reglas versionadas. |
| `src/zbp_i_dm_areatask.clas.abap` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_areatask.clas.locals_imp.abap` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_areatask.clas.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_fieldvalue.clas.abap` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_fieldvalue.clas.locals_imp.abap` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_fieldvalue.clas.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_request.clas.abap` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_request.clas.locals_imp.abap` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zbp_i_dm_request.clas.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_areatask.bdef.asbdef` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_areatask.bdef.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_areatask.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_areatask.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_areatask.ddlx.asddlxs` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_areatask.ddlx.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_fieldvalue.bdef.asbdef` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_fieldvalue.bdef.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_fieldvalue.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_fieldvalue.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_fieldvalue.ddlx.asddlxs` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_fieldvalue.ddlx.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_request.bdef.asbdef` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_request.bdef.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_request.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_request.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_request.ddlx.asddlxs` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zc_dm_request.ddlx.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zcl_dm_trial_activation.clas.abap` | Mock BTP Trial acoplado a ZDM_REQ_H y ZDM_OUTBOX; no aplicable al nuevo modelo On-Premise. |
| `src/zcl_dm_trial_activation.clas.xml` | Mock BTP Trial acoplado a ZDM_REQ_H y ZDM_OUTBOX; no aplicable al nuevo modelo On-Premise. |
| `src/zdm_audit.tabl.xml` | Persistencia del modelo anterior; sustituida por las 15 tablas YMMT_DM (auditoria/outbox fuera del nuevo DER). |
| `src/zdm_classify_p.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zdm_classify_p.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zdm_field_c.tabl.xml` | Persistencia del modelo anterior; sustituida por las 15 tablas YMMT_DM (auditoria/outbox fuera del nuevo DER). |
| `src/zdm_outbox.tabl.xml` | Persistencia del modelo anterior; sustituida por las 15 tablas YMMT_DM (auditoria/outbox fuera del nuevo DER). |
| `src/zdm_reject_p.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zdm_reject_p.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zdm_req_a.tabl.xml` | Persistencia del modelo anterior; sustituida por las 15 tablas YMMT_DM (auditoria/outbox fuera del nuevo DER). |
| `src/zdm_req_f.tabl.xml` | Persistencia del modelo anterior; sustituida por las 15 tablas YMMT_DM (auditoria/outbox fuera del nuevo DER). |
| `src/zdm_req_h.tabl.xml` | Persistencia del modelo anterior; sustituida por las 15 tablas YMMT_DM (auditoria/outbox fuera del nuevo DER). |
| `src/zi_dm_areatask.bdef.asbdef` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_areatask.bdef.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_areatask.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_areatask.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_fieldvalue.bdef.asbdef` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_fieldvalue.bdef.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_fieldvalue.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_fieldvalue.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_request.bdef.asbdef` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_request.bdef.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_request.ddls.asddls` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zi_dm_request.ddls.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zui_dm_o4.srvd.srvdsrv` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |
| `src/zui_dm_o4.srvd.xml` | CDS, behavior, clase, metadata o servicio exclusivo del BO anterior; dependencia de tablas o entidades retiradas. |

## Conservados

`src/package.devc.xml`, `.abapgit.xml` y `.gitignore` se conservan sin alteración como infraestructura compartida.
`docs/requirements.md` conserva los requisitos funcionales históricos; se señala su contexto anterior.
README, arquitectura, despliegue y pruebas se actualizan para retirar instrucciones incompatibles.
La pertenencia de las fuentes retiradas al modelo DM está confirmada por sus nombres, contenido y referencias locales. No se eliminan objetos de otros proyectos.

## Mapeo y migración pendiente

| Anterior | Nuevo destino |
|---|---|
| ZDM_REQ_H | SOL + versión de flujo + segmentos organizativos |
| ZDM_REQ_A | TAREA + PASO versionado |
| ZDM_REQ_F | DATO + CAMPO + SEG y subtipo |
| ZDM_FIELD_C | CAMPO + SECCION + REGLA y FLUJO_VR |
| AUDIT / OUTBOX y mock | Sin sustituto en el DER; rediseño posterior con aprobación funcional |

Los UUID antiguos no bastan para asignar contexto de valores: la migración necesita centro/almacén/ventas/valoración/unidad y una versión histórica explícita.
No hay script de migración automática ni eliminación física en SAP. No ejecutar una sincronización destructiva de abapGit sobre un sistema con datos: importar primero objetos nuevos y planificar por separado el retiro de los antiguos.

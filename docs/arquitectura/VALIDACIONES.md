# Validaciones de la reestructuración DM

## Resultados locales

| Comprobación | Resultado |
|---|---|
| `python3 tools/validate_dm.py` | OK: 15 tablas, 6 dominios, 6 elementos, 102 campos, 16 FK, 5 índices, 16 relaciones DER |
| `python3 -m unittest discover -s tests -v` | 13 pruebas aprobadas |
| Parser Mermaid 11.12.0 | DER_DM.mmd reconocido como erDiagram, sin errores de sintaxis |
| XML | 15 documentos bien formados, serializer TABL, nombres únicos y PK correctas |
| Tipos | UUID binario, elementos SAP sin redefinir longitud, CHAR Unicode, INT4 y DATS coherentes |
| Referencias | PK destino completa, MANDT incluido, tipos coincidentes, DD03P/DD05M/DD08V coherentes |
| Índices | Número de solicitud, tarea/paso y regla únicos; dos índices no únicos de búsqueda |
| DER/diccionario | Entidades, atributos, tipos, PK/FK/UK y cardinalidades contrastados con XML/contrato JSON |
| Limpieza | 54 bajas incluidas en LIMPIEZA.md; todas dentro del modelo DM anterior |
| Infraestructura | `.abapgit.xml` y `src/package.devc.xml` conservados sin cambios |
| Higiene Git | `git diff --check` sin errores; cachés excluidas; sin archivos temporales en el conjunto de cambios |
| Firmas de secretos | Sin claves privadas, tokens GitHub ni access keys AWS reconocibles en archivos candidatos |

Las pruebas negativas comprueban detección de PK UUID ausente, mapeo incorrecto
de mandante en FK, índice único debilitado, tipo UUID alterado, longitud errónea,
cardinalidad DER alterada, tabla ausente y definición adicional duplicada. La
novena prueba valida el conjunto correcto. Se añaden cuatro regresiones para FK
sin elemento de datos, FIELDNAME restringido, dominio ausente y longitud de dominio
incompatible. Se ejecutan sobre copias temporales.

La comprobación de nombres detectó `YMMT_DM_FLUJO_VER` con 17 caracteres. Se
corrigió a `YMMT_DM_FLUJO_VR` antes del resultado final aprobado. La corrección
está justificada en MODELO_DATOS.md. La clasificación DDIC de las FK distingue
KEY cuando sus componentes pertenecen a la PK del hijo y REF en caso contrario.

El parser Mermaid y sus dependencias se instalaron únicamente en `/tmp`, sin
añadir Node.js ni paquetes npm al repositorio. El formato de serialización se
contrastó con el [serializer TABL de abapGit](https://github.com/abapGit/abapGit/tree/1132cd91768a84ee32d2e9400e9ac86859bbecb0/src/objects/tabl).

## Corrección tras los errores de activación ADT

La captura del sistema destino mostró cuatro errores de FK sin elemento de datos,
el rechazo de FIELDNAME y un error dependiente de activación de CAMPO. Los tipos
integrados de identificadores y versión se sustituyen por elementos con dominios
propios; se elimina la dependencia de FIELDNAME/TABNAME usando nombre CHAR(30)
propio. No se cambian las 15 entidades, sus campos ni sus longitudes.

El validador anterior comprobaba compatibilidad de tipos pero no exigía elementos
en los componentes FK. Esa omisión está corregida y cubierta por regresión.
**La activación sigue pendiente de repetir en SAP después de importar el ajuste.**
Los otros tipos SAP se conservan; no se afirma compatibilidad completa con ABAP
Cloud ni se consideran resueltas advertencias cuyo texto no está en la captura.

## Archivos nuevos

- `src/ymme_dm_flujo_id.dtel.xml`
- `src/ymmd_dm_flujo_id.doma.xml`
- `src/ymme_dm_version.dtel.xml`
- `src/ymmd_dm_version.doma.xml`
- `src/ymme_dm_paso_id.dtel.xml`
- `src/ymmd_dm_paso_id.doma.xml`
- `src/ymme_dm_campo_id.dtel.xml`
- `src/ymmd_dm_campo_id.doma.xml`
- `src/ymme_dm_seccion.dtel.xml`
- `src/ymmd_dm_seccion.doma.xml`
- `src/ymme_dm_nombre.dtel.xml`
- `src/ymmd_dm_nombre.doma.xml`
- `src/ymmt_dm_flujo.tabl.xml`
- `src/ymmt_dm_flujo_vr.tabl.xml`
- `src/ymmt_dm_paso.tabl.xml`
- `src/ymmt_dm_sol.tabl.xml`
- `src/ymmt_dm_tarea.tabl.xml`
- `src/ymmt_dm_seg.tabl.xml`
- `src/ymmt_dm_seg_cen.tabl.xml`
- `src/ymmt_dm_seg_alm.tabl.xml`
- `src/ymmt_dm_seg_ven.tabl.xml`
- `src/ymmt_dm_seg_val.tabl.xml`
- `src/ymmt_dm_seg_uom.tabl.xml`
- `src/ymmt_dm_campo.tabl.xml`
- `src/ymmt_dm_seccion.tabl.xml`
- `src/ymmt_dm_regla.tabl.xml`
- `src/ymmt_dm_dato.tabl.xml`
- `docs/arquitectura/DER_DM.mmd`
- `docs/arquitectura/MODELO_DATOS.md`
- `docs/arquitectura/DICCIONARIO_DATOS.md`
- `docs/arquitectura/RELACIONES.md`
- `docs/arquitectura/LIMPIEZA.md`
- `docs/arquitectura/VALIDACIONES.md`
- `docs/arquitectura/modelo_dm.json`
- `tools/validate_dm.py`
- `tests/test_validate_dm.py`

Las bajas y sus motivos se enumeran en [LIMPIEZA.md](LIMPIEZA.md). README,
documentación de arquitectura/despliegue/pruebas y la nota de requisitos se
actualizan; `.gitignore` excluye los artefactos del validador Python.

## Límites y comprobaciones SAP pendientes

No hay conexión a SAP, ejecución de DDIF_TABL_PUT ni compilador/activación ADT.
El análisis de XML y la referencia de abapGit no prueban compatibilidad con una
versión concreta de SAP_BASIS. Quedan pendientes:

- Importar y activar las 15 tablas; verificar tipos estándar en el release real,
  ajustes técnicos, metadata FK e índices físicos; ejecutar revisión ATC.
- Diseñar e implementar validaciones RAP para integridad, especialización y
  unicidad contextual; probar dos sesiones concurrentes y aislamiento de mandante.
- Resolver estrategia de última modificación/ETag antes de behaviors managed,
  draft y publicación del servicio. CREADO_EL no es ETag de modificación.
- Crear CDS de interfaz/consumo, behaviors, clases, autorizaciones, definición y
  binding OData V4 compatibles con On-Premise. El servicio antiguo fue retirado.
- Planificar migración histórica e integración SAP, auditoría/outbox y retirada
  controlada de objetos antiguos; no se realizaron operaciones físicas ni de datos.

El respaldo local `backup/dm-before-restructure-20261030` conserva el commit
`2d493efcfcfd279ff73cc126e898336066c8708d`. La publicación usa la rama de trabajo
`work`, sin force-push ni cambio directo de `main`.

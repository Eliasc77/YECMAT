# Relaciones y cardinalidades

Cada hijo tiene exactamente un padre por relación; un padre puede tener cero o muchos hijos, salvo los subtipos (cero o uno). Todas las FK incluyen MANDT.
Se incluyen metadata DD08V/DD05M de Dictionary. Estas relaciones son semánticas DDIC: no equivalen a FOREIGN KEY SQL ni protegen Open SQL de escrituras huérfanas. La futura capa RAP debe validarlas al guardar.

| Padre | Hijo | Clave completa del padre referenciada | Hijos por padre |
|---|---|---|---|
| `YMMT_DM_FLUJO` | `YMMT_DM_FLUJO_VR` | `MANDT, FLUJO_ID` | 0..* |
| `YMMT_DM_FLUJO_VR` | `YMMT_DM_PASO` | `MANDT, FLUJO_ID, VERSION` | 0..* |
| `YMMT_DM_FLUJO_VR` | `YMMT_DM_REGLA` | `MANDT, FLUJO_ID, VERSION` | 0..* |
| `YMMT_DM_FLUJO_VR` | `YMMT_DM_SOL` | `MANDT, FLUJO_ID, VERSION` | 0..* |
| `YMMT_DM_SOL` | `YMMT_DM_TAREA` | `MANDT, SOLICITUD_UUID` | 0..* |
| `YMMT_DM_PASO` | `YMMT_DM_TAREA` | `MANDT, FLUJO_ID, VERSION, PASO_ID` | 0..* |
| `YMMT_DM_SOL` | `YMMT_DM_SEG` | `MANDT, SOLICITUD_UUID` | 0..* |
| `YMMT_DM_SEG` | `YMMT_DM_SEG_CEN` | `MANDT, SEGMENTO_UUID` | 0..1 |
| `YMMT_DM_SEG` | `YMMT_DM_SEG_ALM` | `MANDT, SEGMENTO_UUID` | 0..1 |
| `YMMT_DM_SEG` | `YMMT_DM_SEG_VEN` | `MANDT, SEGMENTO_UUID` | 0..1 |
| `YMMT_DM_SEG` | `YMMT_DM_SEG_VAL` | `MANDT, SEGMENTO_UUID` | 0..1 |
| `YMMT_DM_SEG` | `YMMT_DM_SEG_UOM` | `MANDT, SEGMENTO_UUID` | 0..1 |
| `YMMT_DM_SEG` | `YMMT_DM_DATO` | `MANDT, SEGMENTO_UUID` | 0..* |
| `YMMT_DM_CAMPO` | `YMMT_DM_DATO` | `MANDT, CAMPO_ID` | 0..* |
| `YMMT_DM_CAMPO` | `YMMT_DM_REGLA` | `MANDT, CAMPO_ID` | 0..* |
| `YMMT_DM_SECCION` | `YMMT_DM_REGLA` | `MANDT, SECCION_ID` | 0..* |

## Límites de integridad y controles necesarios

- SOL.NUMERO_SOLICITUD es único por mandante mediante índice Z01. Asignarlo antes de insertar: un valor inicial también participa en la unicidad.
- TAREA.Z01 impide repetir el mismo paso de la misma versión para una solicitud. Reintentos reutilizan la tarea; un historial de ejecuciones exigiría ampliar el DER.
- REGLA.Z01 impide estados contradictorios para el mismo flujo/versión/área/campo. La sección y el orden son atributos, no crean reglas duplicadas; tampoco las reglas inactivas pueden duplicar esa clave.
- Las PK de los subtipos garantizan como máximo una fila de cada subtipo por segmento. No impiden que un mismo UUID aparezca en subtipos diferentes. Exigir exclusividad según TIPO_SEGMENTO.
- DATO permite un único valor por segmento/campo. El tipo de segmento de CAMPO debe coincidir con SEG.TIPO_SEGMENTO; una FK simple no valida esa igualdad.
- Una tarea debe referir la misma pareja FLUJO_ID/VERSION que su SOL y un AREA igual a PASO.AREA. Las dos FK independientes no bastan para garantizarlo.
- No hay una FK REGLA→PASO: varias fases/pasos pueden usar una misma área. Validar que el área de la regla está disponible en algún paso activo de la versión.
- Los padres referenciados no se eliminan: se inactivan o retiran de vigencia. No hay cascadas físicas.

## Unicidad natural de segmentos

| Tipo | Clave única lógica dentro de una solicitud | Subtipo requerido |
|---|---|---|
| GENERAL | solicitud_uuid + GENERAL | ninguno |
| CENTRO | solicitud_uuid + CENTRO + centro | SEG_CEN |
| ALMACEN | solicitud_uuid + ALMACEN + centro + almacen | SEG_ALM |
| VENTAS | solicitud_uuid + VENTAS + org_ventas + canal | SEG_VEN |
| VALORACION | solicitud_uuid + VALORACION + area_valoracion + tipo_valoracion | SEG_VAL |
| UNIDAD | solicitud_uuid + UNIDAD + unidad_alternativa | SEG_UOM |

Estas claves atraviesan SEG y su subtipo. Con los campos del DER no es posible crear un índice SQL único que incluya SOLICITUD_UUID y el contexto del subtipo sin duplicar información.
Se conserva el diseño normalizado: la futura operación RAP de alta debe bloquear brevemente la solicitud (enqueue por mandante/solicitud), buscar el contexto mediante JOIN, crear SEG y subtipo en la misma LUW y rechazar duplicados. Todas las vías de escritura deben usar esa operación.
El bloqueo se mantiene desde la búsqueda hasta el commit/rollback de la creación; dos sesiones no deben validar ambas antes de guardar. GENERAL usa el mismo protocolo. El índice SEG.Z01 facilita la búsqueda pero NO garantiza unicidad.
La edición de datos ya existentes usará bloqueos por segmento/dato. No se precisa crear un segmento CENTRO para poder crear uno ALMACEN: el centro se guarda en el contexto de almacén y se comprueba contra customizing SAP.
Si se exige protección de unicidad también ante SQL externo, es necesario modificar el DER con una clave contextual en SEG o una tabla de registro de contextos; esa ampliación no se implementa sin una especificación funcional.

# Relaciones y cardinalidades

Cada hijo tiene exactamente un padre por relación; un padre puede tener cero o muchos hijos, salvo los subtipos (cero o uno). Todas las FK incluyen MANDT.
Se incluyen metadata DD08V/DD05M de Dictionary. Estas relaciones son semánticas DDIC: no equivalen a FOREIGN KEY SQL ni protegen Open SQL de escrituras huérfanas. Los handlers RAP validan las relaciones operativas al guardar; el customizing se mantiene fuera del servicio.

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

En el DER base estas claves atravesaban SEG y su subtipo, sin poder representarse
como índice único. La rama RAP añade SEG.CONTEXTO_CLAVE CHAR(100), derivado del
tipo y de los valores organizativos mediante prefijos de longitud, sin colisiones
por separadores. El índice único Z02 incluye MANDT, SOLICITUD_UUID, TIPO_SEGMENTO y
CONTEXTO_CLAVE. Z01 sigue siendo índice de búsqueda no único.

El backend genera la clave, impide modificar el contexto tras crearlo y comprueba
que GENERAL no tenga subtipo y cada tipo organizativo tenga exactamente el suyo.
La creación raíz/subtipo es una LUW. Se mantiene un lock corto de SOL durante el
alta para excluir cierres y un índice SQL protege duplicados entre transacciones.
No es necesario crear un segmento CENTRO para crear ALMACEN; ambos son contextos
independientes. Se valida el centro explícito frente al criterio del flujo; la
validez del resto de claves SAP debe contrastarse mediante APIs liberadas del
sistema de materiales al integrar, ya que el Trial no contiene ese maestro.

Los valores usan ETag y lock propios y locks breves de las tareas que dependen del
campo. Una tarea finalizada congela sus campos compartidos. Ver
[RAP_DINAMICO.md](RAP_DINAMICO.md) para el protocolo entre captura y cierre.

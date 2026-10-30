# Modelo de datos DM para S/4HANA On-Premise

## Alcance y estado

Se implementan las 15 tablas del DER en formato Dictionary abapGit TABL, en
`src/ymmt_dm_*.tabl.xml`. Son fuentes generadas y comprobadas estructuralmente
en Git, **no activadas en SAP**. No se conoce el release exacto de S/4HANA,
SAP_BASIS ni abapGit destino. Se usa Dictionary clásico, sin el indicador de
lenguaje ABAP Cloud del modelo anterior.

Esta entrega reconstruye persistencia y arquitectura. Los CDS, behaviors y
servicio anterior se retiran con sus dependencias. Su reconstrucción sobre el
nuevo modelo queda pendiente; no se entrega un servicio OData operativo.
No se han borrado tablas físicas ni registros en SAP.

## Decisiones e inconsistencias del DER

**Corrección de activación a partir del diagnóstico ADT:** las FK Dictionary
requieren elementos de datos; los tipos integrados CHAR/INT4 no bastan en sus
componentes. Se incorporan seis dominios `YMMD_DM_*` y seis elementos `YMME_DM_*`
para identificadores de flujo/paso/campo/sección, versión y nombres técnicos SAP.
Se reutiliza el mismo elemento y dominio en ambos extremos de cada relación.
El nombre técnico CHAR(30) sustituye a FIELDNAME (rechazado por el sistema destino)
y TABNAME para evitar esa dependencia de catálogo estándar. No cambian campos,
longitudes, valores almacenados, claves ni cardinalidades. Estos objetos deben
activarse antes de las tablas. El error de activación de CAMPO impide también
activar las tablas que lo referencian. Las validaciones estáticas anteriores
no comprobaban el requisito de elemento de datos en las FK; se amplían aquí.

**Corrección técnica de nombre, registrada antes de aplicarla:** la entidad
lógica `YMMT_DM_FLUJO_VER` del DER fuente tiene 17 caracteres. Para respetar el
límite de 16 caracteres de nombres de tabla Dictionary clásica On-Premise,
se implementa como `YMMT_DM_FLUJO_VR` (16). Esta es una correspondencia uno a uno,
sin cambio de atributos, claves ni cardinalidades. El DER actualizado, XML y
diccionario usan el nombre físico corregido. No se genera una tabla duplicada
ni un alias de persistencia de 17 caracteres.

1. **Mandante:** MANDT es el único campo añadido al DER funcional, como primer
   componente de todas las PK, FK e índices. NOTNULL evita NULL SQL, pero no
   impide valores iniciales ABAP. UUID, referencias y obligatorios deben validarse.
2. **General:** SEG.TIPO_SEGMENTO = GENERAL representa campos de cabecera
   independientes de organización. Como máximo uno por solicitud, sin subtipo.
   No se añade tabla SEG_GENERAL. Datos de identidad/proceso permanecen en SOL;
   no duplicar MATERIAL, TIPO_MATERIAL ni TIPO_OPERACION en DATO.
3. **Especialización exclusiva:** cada segmento organizativo necesita exactamente
   un subtipo coherente. Las cinco relaciones opcionales 1:0..1 del DER no expresan
   esa exclusividad; GENERAL es la excepción sin subtipo. El tipo de un segmento
   con datos no puede cambiar. Estas restricciones requieren validación RAP.
4. **Independencia:** SEG_ALM contiene su propio CENTRO y no exige un SEG_CEN.
   Ventas, valoración y unidades no dependen de un centro implícito. BWKEY no se
   equipara a WERKS: el nivel de valoración depende del sistema SAP.
5. **Unicidad:** la clave natural de segmento cruza dos tablas. Con los campos
   originales no hay índice SQL que garantice contexto único por solicitud.
   [RELACIONES.md](RELACIONES.md) define las claves y el protocolo de bloqueo
   pendiente. No se impone unicidad por tipo, que impediría varios centros.
   Se añaden índices únicos sin campos adicionales para número de solicitud,
   tarea por paso y regla por flujo/versión/área/campo, evitando duplicados
   contradictorios. Regla inactiva tampoco puede duplicar la misma clave.
6. **Versiones:** SOL fija FLUJO_ID/VERSION al crearse. Una versión publicada y
   sus PASO/REGLA son inmutables; los cambios crean otra versión. VERSION es INT4
   positivo. Estados propuestos BORRADOR/PUBLICADA/RETIRADA caben en CHAR12;
   son un contrato de aplicación pendiente, sin dominios de valores fijos aquí.
   VIGENTE_DESDE es obligatorio; HASTA inicial indica sin fin. Vigencias inclusivas,
   HASTA >= DESDE, sin solapamientos publicados del mismo flujo. La selección de
   un flujo activo debe ser unívoca; rechazar criterios ambiguos.
7. **Criterios históricos:** TIPO_MATERIAL, TIPO_OPERACION y CENTRO_CRITERIO están
   en FLUJO según el DER. No modificarlos después de publicar versiones, pues
   cambiaría la interpretación histórica; crear otro FLUJO_ID. SOL conserva los
   criterios del caso y debe validarlos al asignar versión. Centro criterio
   inicial puede significar cualquier centro; no añadir una FK obligatoria para
   ese comodín.
8. **Paso/tarea:** TAREA debe referir el mismo flujo/versión que SOL y AREA igual
   a PASO.AREA. Las dos FK independientes no lo garantizan. Se conservan los
   campos redundantes exigidos por el DER para referenciar PASO y registrar área;
   no son libremente editables. El índice admite una instancia por paso/solicitud;
   reintentos reutilizan la tarea. Un historial de ejecuciones exigiría ampliar
   el DER. CONDICION_BPM propone A/B/espacio (BPM/no BPM/ambos), pendiente de
   confirmar funcionalmente; operación C/M/I procede del requisito histórico.
9. **Reglas:** CAMPO identifica el dato y su tipo de segmento. El área de REGLA
   debe existir en algún PASO activo de la versión; AREA sola no identifica un
   paso, por lo que no se inventa una FK REGLA→PASO. Estado de campo I/O/M/R:
   invisible/opcional/obligatorio/solo lectura. No habilitar campos inactivos.
   Guardar progreso admite vacíos; completar tarea valida campos M por contexto
   aplicable, incluso si falta la fila DATO. La aplicabilidad se deriva de
   CAMPO.TIPO_SEGMENTO y los segmentos de la solicitud.
10. **Catálogo no versionado:** CAMPO y SECCION no tienen versión. Una vez usados
    por versiones publicadas, mantener inmutables significado, tipo, longitudes,
    segmento y mapeo SAP de CAMPO. Cambios incompatibles crean otro CAMPO_ID.
    No cambiar el significado de secciones referenciadas. SECCION.ORDEN es global;
    REGLA.ORDEN ordena los campos de la versión. Bajas lógicas preservan historia.
11. **Valores genéricos:** VALOR es CHAR(1333), límite deliberado del tipo integrado
    DDIC. Validar LONGITUD/DECIMALES/TIPO_DATO y convertir al tipo SAP al integrar;
    nunca truncar. Formato canónico propuesto: decimal con punto, fecha YYYYMMDD,
    booleano X/espacio, unidades internas SAP. Cantidad/moneda y sus referencias
    pueden ser campos separados del mismo contexto. Textos multilingües,
    clasificación multivalor, textos largos o binarios requieren ampliar el DER.
12. **FK:** DD05M/DD08V describen relaciones DDIC, no restricciones FOREIGN KEY SQL.
    No impiden escrituras Open SQL huérfanas ni eliminaciones de padres usados.
    La capa transaccional debe validar existencia, mandante, coherencia cruzada,
    contexto y exclusividad; inactivar padres en lugar de eliminarlos.

## Criterios de segmentación

| Nivel | Información y ejemplos SAP | Contexto |
|---|---|---|
| GENERAL | MARA; MAKT solo con idioma único definido | Solicitud |
| CENTRO | Planificación, compras o QM de MARC | Centro |
| ALMACEN | Datos MARD | Centro + almacén |
| VENTAS | Datos MVKE | Organización de ventas + canal |
| VALORACION | Precio/coste MBEW | Área + tipo de valoración |
| UNIDAD | Conversión MARM por unidad alternativa | Unidad alternativa |

La unidad base MARA-MEINS es GENERAL; la alternativa MARM-MEINH es UNIDAD.
El mapeo depende de la clave funcional SAP, no del área que edita el campo.
El mismo campo en dos centros genera valores en segmentos distintos. Tipo de
valoración inicial representa ausencia de valoración separada, no un segmento
incompleto. No omitir canal ni centro de almacén. Validar combinaciones en SAP.

## Concurrencia y RAP futuro

SOL, TAREA y SEG no tienen última modificación en el DER. CREADO_EL es inmutable
y no sirve como ETag de modificación. DATO.MODIFICADO_EL puede ser ETag del dato
si se mantiene en cada escritura, pero no es ETag de toda la solicitud.
No se han añadido campos ETag de forma implícita.

Antes de RAP managed con control optimista completo, añadir y justificar última
modificación en las raíces y total ETag si se adopta draft; alternativamente
diseñar control pesimista/unmanaged y evaluar su contrato. Las ediciones
independientes requieren locks por segmento/dato y tarea; un lock duradero de SOL
serializaría áreas. Altas de contexto y transiciones globales usan locks breves
de SOL, orden fijo de adquisición y una LUW. No introducir COMMIT WORK en handlers.

Las claves y tipos son utilizables en CDS View Entities con asociaciones de
cardinalidad explícita y aislamiento por mandante. No exponer MANDT para edición
OData. Quedan por diseñar behaviors, autorizaciones, proyecciones, servicio y
binding V4 compatibles con el release On-Premise real.

## Validación

Ejecutar `python3 tools/validate_dm.py` y
`python3 -m unittest discover -s tests -v`. Son validaciones estáticas de XML,
contrato JSON, claves, tipos, FK, índices y coherencia DER/diccionario. No compilan
ABAP ni demuestran integridad de datos en ejecución. La metadata FK/índices se
contrastó con el serializer TABL público de abapGit (DD05M_TABLE/DD08V_TABLE,
DD12V/DD17V). La importación y activación requieren ADT/SAP; ver
[VALIDACIONES.md](VALIDACIONES.md) y [despliegue](../deployment.md).

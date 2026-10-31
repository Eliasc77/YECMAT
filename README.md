# DM — carga inicial y primera solicitud de prueba

Rama independiente `feature/dm-carga-inicial`. Contiene únicamente tres clases de
utilidad, pruebas del plan de carga y un perfil DEMO. No contiene ni reemplaza las
tablas, CDS, behaviors, metadata UI o servicio del backend. La rama de metadata
`feature/dm-metadata` permanece intacta.

## Importar y activar

1. Mantener el backend activo, incluidas las tablas YMMT_DM_*, los seis dominios
   y elementos propios y el BO YI_DM_SOL. No importar tablas anteriores para usar
   esta utilidad. Se utiliza el modelo con los cinco campos de soporte RAP.
2. Crear un paquete separado (por ejemplo YECMAT_TOOLS), en el mismo software
   component del backend y con lenguaje ABAP Cloud. Conservar los enlaces actuales
   de backend y metadata. Vincular otro repositorio abapGit al mismo URL GitHub,
   seleccionando rama `feature/dm-carga-inicial` y ese paquete separado.
3. Importar las tres CLAS con todos sus archivos XML/ABAP. Activar primero
   YCL_DM_DEMO_CONFIG y después YCL_DM_CARGA_DEMO y YCL_DM_CREAR_SOL_DEMO.
   Si el sistema exige uso de paquete, habilitar acceso a los objetos propios del
   backend dentro del mismo componente. No se incluyen stubs de objetos estándar.
4. Ejecutar ABAP Unit de YCL_DM_DEMO_CONFIG: ocho pruebas sin lecturas ni escrituras
   de base de datos comprueban el perfil y el plan de inserción. Se entregan para
   SAP; no se presentan como pruebas ejecutadas en el entorno local.

No cambies el enlace del paquete backend a esta rama de utilidades: su contenido
excluye esos objetos y una sincronización completa podría proponer sus bajas.

## Paso 1 — cargar configuración

En ADT abrir YCL_DM_CARGA_DEMO y ejecutar **Run As → ABAP Application (Console)**.
Debe indicar la carga de este perfil:

| Configuración | Valor / cantidad |
|---|---|
| Flujo | DM_DEMO_ZFER |
| Versión | 1, PUBLICADA |
| Tipo de material / operación | ZFER / C |
| Vigencia | 20200101–99991231 |
| Centro criterio | Inicial, cualquier centro |
| Pasos | 3: PCP_CAPTURA, LOG_CAPTURA, CONT_CAPTURA |
| Campos / secciones / reglas | 9 / 6 / 9 |

Son los nueve campos de ejemplo de la rama de metadata. Se cubren GENERAL,
CENTRO, ALMACEN, VENTAS, VALORACION y UNIDAD. Los tres pasos son obligatorios,
activos y aplicables a BPM y no BPM. Se abren en paralelo según el backend actual.

La matriz es de DEMOSTRACIÓN, no la configuración funcional aprobada para la
empresa. Los catálogos regulatorios, Calidad, centros/tipos reales y reglas
adicionales deben definirse aparte. No se simula que estén configurados.

### Comportamiento de la carga

- Antes de escribir, se valida y compara el perfil completo con los registros
  existentes. Una diferencia cancela el plan sin sobrescribir ningún registro.
- Inserta solo en FLUJO, FLUJO_VR, PASO, CAMPO, SECCION y REGLA, con prefijo YMMT_DM_.
- Genera UUID nuevos para las reglas que se van a insertar, antes del primer INSERT.
  Las reglas existentes se reconocen por flujo/versión/área/campo, conservando su UUID.
- Ejecutar de nuevo con el perfil completo idéntico no modifica ni duplica datos.
- No añade elementos a una versión publicada incompleta o diferente. Se detiene
  para revisión; no reconstruye ni reescribe configuraciones publicadas.
- Los INSERT se confirman juntos; un conflicto SQL revierte toda esa ejecución.
  No se ignoran claves duplicadas ni hay DELETE/UPDATE de configuración.
- COMMIT/ROLLBACK WORK pertenecen exclusivamente a esta aplicación de consola,
  que es dueña de la LUW. Nunca llamar a la carga desde un behavior handler.
- No consulta MARA/MARC/MBEW/MARM: esos nombres solo describen el mapeo del catálogo.
  No crea, modifica ni activa maestros de material y no llama servicios externos.

## Paso 2 — crear la primera solicitud

Con el mismo usuario de la preview, ejecutar YCL_DM_CREAR_SOL_DEMO como aplicación
de consola. Crea mediante EML del BO YI_DM_SOL, respetando autorizaciones y
validaciones y sin escribir SOL directamente con SQL.

El número es `D-<usuario_tecnico>-01`, por ejemplo `D-USUARIO_DEMO-01`. El backend
asigna UUID, creador, fecha, ETag y estado BORRADOR. Flujo DM_DEMO_ZFER, versión 1,
tipo ZFER y operación C. No hace falta un material existente para la operación C.

Reejecutar la clase encuentra la misma solicitud y no la duplica ni reinicia su
estado. Ejecutar una sola instancia por usuario a la vez: esta utilidad no es un
servicio de numeración productivo. Un número que pertenezca a otro caso no se altera.
Los mensajes de validación de RAP se imprimen en la consola; un error de CREATE
o guardado no se presenta como éxito.

## Paso 3 — verla en Fiori

1. Volver a la preview de Solicitudes con ese usuario.
2. Borrar filtros anteriores y pulsar Go, o filtrar por el número mostrado.
3. Seleccionar la fila BORRADOR y pulsar Iniciar flujo.
4. Informar ClasificacionBpm = B para probar no BPM (A para el caso BPM).
5. Refrescar la solicitud y Tareas: deben aparecer tres tareas, inicialmente
   asignadas al creador. Su captura/cierre sigue las validaciones normales.

No se crean segmentos ni valores de campos automáticamente, ni se finalizan
áreas con datos ficticios. El siguiente trabajo será la captura dinámica de esos
valores. La preview sigue sin incorporar un formulario de alta: la clase permite
crear la primera solicitud de prueba hasta construir la aplicación freestyle.

## Alcance de las comprobaciones

El perfil se contrasta localmente con los nombres/tipos de campos del contrato y
con la muestra de metadata. El parser abaplint se ejecuta con gramática Cloud.
No se conectó SAP, no se ejecutó esta carga, no se ejecutó ABAP Unit en SAP y no
se creó una solicitud desde este entorno. Activar, ejecutar las pruebas y revisar
los mensajes de consola antes de continuar con la preview.

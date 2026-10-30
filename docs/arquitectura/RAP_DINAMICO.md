# Capa RAP dinámica para ABAP Cloud Trial

## Destino y decisiones previas a la implementación

El usuario confirmó ABAP Cloud Trial (TRL_EN). Esta rama parte de 83a47aa;
no reemplaza work ni main. Los nombres Dictionary corregidos se mantienen.

Las propiedades de OData son estáticas; el formulario es dinámico por datos.
CAMPO describe tipos/controles; REGLA define I/O/M/R, sección y orden por flujo,
versión y área; DATO contiene un valor por campo/segmento. Se conservan anotaciones
semánticas, de autorización y de servicio; no se generan UI.lineItem, UI.facet ni
UI.identification para una lista fija de campos. La UI debe ser freestyle y usar
el catálogo y reglas. Fiori Elements no genera esos controles leyendo filas EAV.

## Ampliaciones justificadas de persistencia

Antes de crear behaviors se añaden estos atributos, sin cambiar PK ni FK:

- SOL.LAST_CHANGED_AT, SEG.LAST_CHANGED_AT y TAREA.LAST_CHANGED_AT, con elemento
  ABP_LOCINST_LASTCHANGE_TSTMPL: ETags independientes administrados por RAP.
- DATO.MODIFICADO_EL utiliza ese mismo elemento compatible con timestamp largo;
  se conservan nombre, clave y representación de sus datos.
- SOL.CLASIFICACION_BPM CHAR(1): A/B, necesario para recordar la clasificación
  del caso. CONDICION_BPM en PASO es configuración; no registra la decisión.
- SEG.CONTEXTO_CLAVE CHAR(100): clave técnica derivada del subtipo y su contexto,
  no editable por consumidores. Un índice único MANDT/SOLICITUD_UUID/
  TIPO_SEGMENTO/CONTEXTO_CLAVE evita duplicados también entre transacciones.
  El resto de atributos organizativos sigue en los subtipos. Esta redundancia
  técnica resuelve el límite de unicidad documentado en la primera entrega.
- BOOLE_D se sustituye por ABAP_BOOLEAN, recomendado por el diagnóstico del Trial.

Para datos de prueba ya existentes, cargar CONTEXTO_CLAVE y timestamps antes de
crear el índice, o recrear las tablas de prueba afectadas. El generador de fuentes
no modifica filas SAP. No cambiar claves primarias ni borrar dominios activos.

## Agregados y concurrencia

Solicitud, Segmento, Tarea y Dato son raíces managed independientes, cada una con
ETag y lock propios. Segmento compone sus cinco subtipos organizativos. Las FK
entre agregados se validan al guardar; no son composiciones de una gran solicitud.
Dos áreas editando datos distintos no bloquean toda la solicitud. Dos cambios al
mismo Dato requieren If-Match y detectan conflicto. El índice natural de Segmento
resuelve la carrera de creación sin un lock global de captura.

Los contextos son inmutables tras crearse: raíz y subtipo se crean en una LUW;
GENERAL no tiene subtipo y los demás requieren exactamente el suyo. No se expone
borrado de solicitudes/segmentos para evitar huérfanos entre agregados. Primero
crear y guardar la solicitud, después cada contexto (con su subtipo), y finalmente
los valores. No se admite referenciar un contexto aún no guardado desde otro BO.

La configuración (seis entidades) se expone solo para consulta. Mantenerla fuera
del servicio transaccional con transportes/herramientas autorizadas. Versiones
publicadas, metadatos y criterios referenciados son inmutables por contrato.

## Contrato de lectura, escritura y acciones

| Grupo | Objetos | Uso |
|---|---|---|
| Interfaz | 15 YI_DM_* sobre las tablas | Relaciones, claves y semántica |
| Proyección transaccional | 9 YC_DM_* para SOL, SEG, cinco subtipos, TAREA y DATO | API de los cuatro BO |
| Consumo de configuración | 6 YC_DM_* de consulta, como SELECT sobre las interfaces | Evita exigir BO transaccional a catálogos de lectura |
| Soporte | YI_DM_SOL_USR, YI_DM_DATO_USR | Acceso por miembro de solicitud y campo; sin entity sets públicos |
| Parámetros | YD_DM_INICIAR, YD_DM_REABRIR | Clasificación A/B y UUID de tarea |
| Behaviors | 4 de interfaz + 4 de proyección | Managed, strict(2), locks y ETags |
| Behavior pools | YBP_I_DM_SOL/SEG/TAREA/DATO | Determinaciones, validaciones y acciones |
| Acceso de lectura | 18 DCL (9 interfaces y 9 proyecciones) | Creador/responsable y visibilidad por campo |
| Servicio | YUI_DM_O4 | 15 entity sets; binding por crear en ADT |

- SOL: crear solicitud propia (número único suministrado por el cliente), Iniciar,
  Cerrar, Aprobar y Reabrir. No se expone PATCH ni DELETE de cabecera.
- Iniciar(A/B): desde BORRADOR, fija clasificación y crea una tarea por cada PASO
  activo con condición vacía o coincidente. Inicialmente el creador es responsable;
  este puede reasignar cada tarea guardada mediante PATCH de Responsable.
ORDEN determina el orden de generación y FASE se expone como metadata. Esta
primera capa abre en paralelo todos los pasos activos aplicables; no implementa
un motor de predecesores o fases secuenciales implícitas. Si una misma área aparece
en varias fases, los campos de una tarea finalizada permanecen congelados hasta
reabrir las tareas afectadas; no se conserva un snapshot por ejecución de paso.

- TAREA: Iniciar y Finalizar; solo creador o responsable ejecutan esas acciones.
  La creación no se publica en la proyección: Iniciar de SOL usa la interfaz EML.
  Reabrir de TAREA es una acción de interfaz usada por SOL; no está en el servicio.
- Finalizar: acepta PENDIENTE/EN_CURSO, valida reglas M por todos los segmentos de
  su tipo, existencia de DATO, valor no vacío y formato. Un contexto requerido
  ausente también falla. No obliga a completar campos M al guardar progreso.
- Cerrar: acción explícita del creador, tras guardar valores y finalizar tareas
  en peticiones anteriores. Bloquea todas las tareas y exige cerrar las obligatorias.
  BPM pasa a REVISION y no BPM a LISTA_INTEG. Aprobar solo admite BPM en REVISION.
  Reabrir acepta una tarea de esa solicitud en REVISION/EN_CURSO y devuelve captura.
- SEG: crear contexto completo mediante deep create (raíz y un subtipo), o GENERAL
  sin subtipo. No se expone modificación o borrado posterior de contexto.
- DATO: crear/PATCH Valor; claves inmutables. I y R no permiten escritura. O y M
  requieren regla activa, catálogo activo, tipo de segmento coincidente y tarea
  abierta propia, o creador durante el borrador inicial. Campo visible en un área
  finalizada queda congelado hasta reabrir las tareas afectadas, incluso si otra
  área comparte el campo. El backend aplica esto además de lo que muestre la UI.

Cada transición debe ejecutarse después de confirmar el guardado anterior. No
agrupar cierre de solicitud con modificaciones de captura o cierre de tareas en
el mismo changeset; las validaciones leen el estado del buffer y rechazan esa
mezcla. Iniciar y Reabrir de SOL coordinan internamente sus cambios multi-BO.

## Consistencia entre captura y cierre

Los ETags resuelven cambios simultáneos a una misma fila, pero no bastan para
proteger una validación que lee varios datos. En la fase de interacción de cada
escritura de Valor, la determinación audit solicita SET LOCKS sobre las tareas
que usan ese campo, en orden de UUID. Finalizar ya toma el lock de su tarea;
Cerrar toma los de todas las tareas antes de comprobar sus estados. Un lock
fallido impide guardar mediante la validación, con mensaje de reintento. Se
revalida permiso después de tomar locks. Los locks duran hasta commit/rollback
RAP; nunca hasta que el usuario abandone el formulario. Datos de áreas con tareas
distintas no comparten lock, salvo campos compartidos por configuración.

En BORRADOR solo el creador captura valores y el lock es brevemente el de SOL;
impide iniciar el flujo mientras se guarda esa captura inicial. Crear un segmento
también toma brevemente ese lock para excluir cierres concurrentes. El índice
Z02 de SEG protege la unicidad natural incluso si dos transacciones pasan el
prechequeo. Su colisión concurrente puede llegar como error de unicidad del
runtime, además del mensaje funcional para duplicados ya persistidos.

No se escriben tablas managed con SQL, no se usan locks clásicos ni commits en
handlers. Las FK DDIC continúan siendo metadata; las comprobaciones de existencia,
versión, área, contexto y permisos están en los handlers.

## Permisos y límites del Trial

La base de autorización de esta rama es el creador y la asignación de tareas,
no un mapeo de roles PFCG del diseño On-Premise. DCL restringe lecturas y los
handlers restringen modificaciones. Los miembros de la solicitud ven su estado,
contextos y tareas; DATO se filtra también por regla visible de su área. Los
catálogos no contienen valores de solicitudes y se consultan como metadata.

La creación requiere usuario técnico autenticado y acceso al servicio, y las
validaciones asignan el creador real. Las decisiones globales (clasificar,
aprobar, reabrir) quedan en el creador en este primer contrato Trial. Antes de
productivo debe incorporarse la autorización IAM de Calidad/administración y
segregación de funciones, con catálogos/roles del sistema real. No se simula
AUTHORITY-CHECK sobre objetos Z inexistentes ni se permite a todos actualizar.

El cliente debe filtrar reglas por FlujoId/Version/Area y construir sus controles
con TipoDato, Longitud, Decimales, TipoControl, AyudaValores, EstadoCampo, SeccionId
y Orden. DCL no sustituye el filtro funcional de metadata en la UI. Usar ayudas
mediante endpoints CDS/API liberados y una lista permitida; AYUDA_VALORES no
habilita ejecutar consultas SQL sobre nombres arbitrarios de tablas/campos.

Tipos dinámicos admitidos: CHAR, STRING, NUMC, INT1, INT2, INT4, DEC, CURR, QUAN,
DATS, BOOL, UNIT, CUKY y LANG. Numéricos sin separadores de miles, decimal con punto,
fecha YYYYMMDD y claves SAP internas en mayúsculas. LONGITUD representa caracteres
en textos y número total de dígitos en numéricos; DECIMALES es la escala máxima.
VALOR sigue limitado a 1333 caracteres. OData lo expone como texto: los filtros y
ordenaciones numéricos/de fecha no son nativos por tipo dinámico; un orden por
VALOR es lexicográfico. La UI necesita conversiones por metadata y una consulta
específica si requiere ordenación/filtrado tipado en servidor. Sin textos multilingües, binarios,
clasificación multivalor ni propiedades OData adicionales generadas en ejecución.

LISTA_INTEG **no significa material activado ni evento encolado**. No se crea
outbox ni se llama a Product Master: son una ampliación posterior con integración
HTTP autorizada a S/4. No hay acceso a MARA/MARC ni BAPIs en esta entrega.

## Guía de consumo

1. Cargar configuración de prueba publicada, con campos/secciones/reglas y pasos
   coherentes; el servicio no publica CRUD de customizing.
2. POST Solicitudes con NumeroSolicitud, TipoMaterial, TipoOperacion, FlujoId,
   Version y Material si operación M/I. Guardar respuesta UUID y ETag.
3. POST Segmentos con SolicitudUUID, TipoSegmento y deep create de la navegación
   _Centro/_Almacen/_Ventas/_Valoracion/_Unidad. GENERAL no incluye navegación.
4. Crear Datos con SegmentoUUID/CampoId/Valor; los valores vacíos guardan progreso.
   Cambios posteriores usan PATCH con If-Match del Dato obtenido, sin comodín.
5. Iniciar SOL con ClasificacionBpm A/B usando la acción cualificada de $metadata.
   Refrescar Tareas y reasignar responsables desde el usuario creador.
6. Cada responsable captura sus valores; guarda, y después ejecuta Finalizar.
7. El creador refresca su ETag y ejecuta Cerrar; para A, después Aprobar o Reabrir.
   Tras acciones, recargar datos/tareas/ETags: no hay side effects de UI estáticos.

## Comprobaciones y alcance de la evidencia

- Validadores Python cruzan persistencia/CDS/BDEF/DCL/servicio, sin SAP.
- abaplint 2.120.92 analiza gramática ABAP/CDS/BDEF en modo Cloud y estructura
  BDEF/CDS. Se excluye solo la comprobación semántica CDS de YI_DM_SEG: esa versión
  del analizador confunde sus composiciones con columnas de la tabla. Su gramática
  se comprueba igualmente y validate_rap contrasta las composiciones y redirects.
- No se habilita check_syntax ABAP completo en CI: no están las clases y tipos
  internos de RAP de SAP. La gramática local no equivale a compilar/activar en ADT.
- Cinco métodos ABAP Unit puros verifican decimales, calendario, overflow,
  codificación del contexto y vacíos. Se entregan para ejecutar en SAP; no se han
  ejecutado aquí. Las pruebas Python no se presentan como pruebas del runtime RAP.
- Antes de publicar binding: activar todo en Trial, ejecutar ATC/ABAP Unit y probar
  DCL, If-Match, deep create y las carreras valor/Finalizar/Cerrar en dos sesiones.

Referencia de SET LOCKS y límites de fases RAP:
[SAP ABAP EML cheat sheet](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/08_EML_ABAP_for_RAP.md#set-locks-exclusively-locking-instances).

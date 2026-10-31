# DM — metadata UI y configuración

Rama `feature/dm-metadata`, independiente y con únicamente metadata más la
configuración mínima de abapGit y esta guía. No contiene definiciones de tablas,
CDS, behaviors, pools, servicios, loaders ABAP, aplicaciones UI5 ni correcciones
del backend. El backend debe existir y estar activo antes de importar esta rama.

## Contenido

- `src/yc_dm_*_ui.ddlx.asddlxs` y `.ddlx.xml`: 15 extensiones UI sobre YC_DM_*.
- `metadata/manifest.json`: relación objeto DDLX → CDS y campos/acciones usados.
- `metadata/configuracion/campos.csv`: catálogo DEMO de nueve campos.
- `metadata/configuracion/secciones.csv`: seis secciones DEMO.
- `metadata/configuracion/reglas.template.csv`: nueve plantillas de reglas.
- `metadata/configuracion/dm_configuracion.template.json`: los mismos registros,
  parámetros pendientes, convenciones de controles y limitaciones de la muestra.
- `.abapgit.xml` y `src/package.devc.xml`: infraestructura de importación de metadata.

La matriz funcional es un EJEMPLO para revisión, no una matriz aprobada ni datos
ya cargados en SAP. Muestra los seis tipos de segmento del modelo. Los nombres
MARA/MARC/etc. son referencias del catálogo, no lecturas a tablas estándar del
Trial ni llamadas al maestro de materiales.

## Importar las DDLX en el Trial

1. Conservar el enlace abapGit actual del backend. No cambiar ese enlace a esta
   rama: al contener solo metadata, la ausencia de sus objetos podría proponerse
   como baja de tablas/CDS/behaviors al sincronizar todo el paquete.
2. Crear en ADT un paquete separado, por ejemplo `YECMAT_META`, en el mismo
   software component del backend y con lenguaje ABAP Cloud. Evitar que su árbol
   de subpaquetes se solape con el repositorio ya enlazado. Vincular
   otro repositorio abapGit al MISMO URL de GitHub, rama `feature/dm-metadata`,
   seleccionando ese paquete separado como destino.
3. En cada uno de los 15 CDS de destino agregar esta anotación en la cabecera,
   conservando las anotaciones de autorización existentes:

   ```abap
   @Metadata.allowExtensions: true
   ```

   Los destinos son YC_DM_SOL, SEG, TAREA, DATO, los cinco YC_DM_SEG_CEN/ALM/VEN/
   VAL/UOM, y YC_DM_FLUJO/FLUJO_VR/PASO/CAMPO/SECCION/REGLA. Esa habilitación
   es una anotación en los CDS existentes: NO se incluye una copia de sus
   definiciones en esta rama. Si un control de paquetes limita el acceso del
   paquete de metadata, configurar su uso dentro del mismo componente con el administrador.
4. Confirmar que las raíces finales estén restauradas: SOL expone _Segmentos y
   _Tareas; SEG expone _Centro/_Almacen/_Ventas/_Valoracion/_Unidad. No activar
   estas facetas sobre versiones temporales de arranque que omitan navegaciones.
5. Importar únicamente los objetos DDLX y el paquete de metadata; activar las
   extensiones después de los CDS. No borrar objetos del paquete backend.
6. Usar un binding OData V4 UI del servicio existente para una preview Fiori
   Elements, o consumir las anotaciones desde la aplicación que corresponda.
   Esta rama no crea ni publica bindings. Verificar el servicio en el sistema;
   las comprobaciones locales no sustituyen su activación y preview en ADT.

No bajar AccessControl de CHECK a NOT_REQUIRED para activar una DDLX. Estas
extensiones solo contienen anotaciones UI; no cambian permisos ni behaviors.

## Qué presenta Fiori Elements

Las extensiones definen listados, filtros, cabeceras, identificaciones y facetas
para las propiedades YA EXISTENTES. Solicitudes muestra contextos/tareas; Segmentos
muestra los detalles organizativos. Se anotan las acciones públicas Iniciar,
Cerrar, Aprobar y Reabrir de Solicitud, e Iniciar/Finalizar de Tarea. La autorización
y las precondiciones de cada acción permanecen en el backend.

Catálogos/reglas/secciones conservan la capacidad de SOLO LECTURA que tenga el
servicio: una anotación no habilita CRUD. No hay semáforos calculados ni campos
nuevos. El grid Datos muestra CampoId y Valor, no una columna por campo funcional.
UUID de solicitud/contexto se conserva en formularios de prueba cuando hace falta
para crear una fila independiente; los ETags quedan ocultos.

El formulario de materiales con controles variables por CAMPO/REGLA sigue
requiriendo UI5 freestyle. Estas DDLX no generan controles en tiempo de ejecución,
no implementan deep create organizativo completo ni diálogos personalizados de
selección. En la preview genérica pueden requerirse IDs técnicos para acciones o
altas; no se presenta como la aplicación final de usuario.

## Configuración dinámica — preparar antes de cargar

Los CSV y el JSON son equivalentes y no se importan a tablas automáticamente por
abapGit. Antes de una carga autorizada en el Trial:

1. Revisar y aprobar campos SAP, longitudes/decimales y matriz por área. La muestra
   usa PCP, LOG y CONT; no inventa campos Z ni la configuración regulatoria/calidad.
2. Elegir FLUJO_ID y VERSION de una versión publicada existente. Esa versión debe
   tener pasos para las áreas usadas. No se crean flujos/versiones/pasos aquí.
3. Resolver `${FLUJO_ID}`, `${VERSION}` y cada `${UUID_REGLA_nn}`. VERSION debe ser
   un entero positivo; cada UUID debe ser RAW16 nuevo (32 dígitos hexadecimales).
   No reutilizar UUID al copiar reglas a otra versión o flujo.
4. Cargar SECCION y CAMPO antes de REGLA con una utilidad de carga autorizada del
   proyecto. El servicio actual no expone su edición. La utilidad NO está incluida
   porque esta rama debe contener solo metadata. No ejecutar plantillas sin
   resolver ni sobrescribir metadatos ya usados por versiones publicadas.
5. Consultar Campos/Secciones/Reglas por OData para confirmar la carga y después
   aplicar los filtros de flujo/versión/área en la UI.

I/O/M/R significa invisible/opcional/obligatorio/solo lectura. El campo
TIPO_CONTROL usa las convenciones Input, Integer y Decimal del JSON; su renderer
UI5 está pendiente. AYUDA_VALORES está vacío: no se simulan endpoints de ayuda.
Los tipos dinámicos se validan también en backend, no solo en la pantalla.

MAKT se representa con un solo idioma; el modelo no tiene clave de idioma.
CURR requiere resolver moneda y convenciones de valoración. Numerador y denominador
de conversión requieren controles de negocio positivos adicionales al formato.
Estos límites se registran también en el JSON y deben revisarse antes de usar la
muestra como configuración funcional real.

## Validación local realizada

Se comprobaron las 15 extensiones contra los nombres de campos, navegaciones y
acciones del backend disponible, las referencias CAMPO/SECCION de las reglas y
la equivalencia JSON/CSV. Los campos obligatorios de altas de prueba no quedan
ocultos por las anotaciones. abaplint 2.120.92 no reportó errores de gramática en
las fuentes/metadata DDLX. No se ejecutó activación SAP ni se cargaron registros.

# YECMAT · App de mantenimientos

Aplicación SAPUI5 para VS Code y servicio RAP de administración de **Campos, Secciones, Flujos, Versiones, Pasos y Reglas**.

Rama independiente: `feature/dm-mantenimientos`. Incluye frontend en `webapp/` y objetos ABAP nuevos en `src/`. No redefine las seis tablas de configuración existentes ni el servicio de captura. La app de captura seguirá leyendo esa misma configuración.

## Probar la app en VS Code

Requisitos: Node.js 22/24 LTS, Git, VS Code y SAP Fiori tools – Extension Pack.

```sh
git clone --single-branch --branch feature/dm-mantenimientos https://github.com/Eliasc77/YECMAT.git YECMAT_ADMIN
cd YECMAT_ADMIN
npm ci
npm run start:demo
```

En PowerShell puedes usar `npm.cmd` en lugar de `npm`. Si no se abre el navegador, entra a `http://localhost:8080/index.html?mode=demo`.

**El modo demo no consulta ni guarda en SAP.** Trabaja en memoria y pierde los cambios al recargar. El aviso amarillo permanece visible. Usa los mismos nueve campos y reglas del perfil demo existente.

## Qué permite mantener

| Mantenimiento | Contenido |
| --- | --- |
| Campos | Identificador, descripción, tabla/campo SAP, contexto, tipo de dato, longitud, decimales, control, referencia de ayuda y activo. |
| Secciones | Identificador, descripción, orden global y activo. |
| Flujos | Tipo de material, operación C/M/I, centro criterio y activo. Un centro criterio vacío significa cualquiera. |
| Versiones | Creación como borrador, vigencias, copia de pasos/reglas, publicación y retiro. |
| Pasos | Área, fase descriptiva, condición A/B/ambas, orden, obligatorio y activo. |
| Reglas | Flujo/version/área/campo, sección, orden, activo y estado M/O/I/R. |

Las claves se fijan al crear el registro. **Nuevo** rechaza claves existentes; **Editar** requiere un registro existente. No hay borrado físico: se inactivan registros que admiten cambios o se retiran versiones.

## Recorrido recomendado para cambiar la demo

La versión 1 ya publicada está protegida. Para cambiar la obligatoriedad de unidad alternativa:

1. En **Versiones**, selecciona `DM_DEMO_ZFER / 1` y pulsa **Copiar version**. Indica `2` y guarda.
2. En **Reglas**, filtra por ese flujo y versión `2`.
3. Edita las reglas de `MARM_UMREZ` y `MARM_UMREN`, cambiando `M` a `O`. Guarda cada cambio.
4. Revisa los pasos, reglas y vigencias de la versión 2.
5. Si las vigencias se solapan, retira la versión 1 antes de publicar la 2. No se permite tener versiones publicadas ambiguas para los mismos criterios.
6. Selecciona la versión 2 y pulsa **Publicar**.
7. Crea una **solicitud nueva** con la versión 2 desde la app de captura.

Las solicitudes existentes permanecen vinculadas a su versión original: no se migran ni cambian sus reglas. Retirar una versión impide seleccionarla para nuevas solicitudes; si tienes solicitudes aún sin iniciar con esa versión, revisa el retiro antes de hacerlo. Sus datos y definiciones históricas se conservan.

Para un flujo completamente nuevo: crea campos/secciones que falten → flujo → versión borrador → pasos → reglas → publicar. Las áreas se definen mediante los pasos, no con una tabla adicional. Las tareas del backend actual se generan en paralelo: **Orden y Fase no crean dependencias secuenciales**.

## Instalar el servicio en SAP Trial

Consulta [instalación ABAP](docs/INSTALACION_SAP.md). Necesitas el backend `YMMT_DM_*` ya activo y los objetos de este proyecto. El servicio de captura actual expone los catálogos solo para lectura; **instalar únicamente el frontend no habilita el guardado administrativo**.

El nuevo servicio es `YUI_DM_CFG_O4`. Crea un binding llamado `YBD_DM_CFG_O4` y publica su endpoint. La URI preparada en el manifest es:

```text
/sap/opu/odata4/sap/ybd_dm_cfg_o4/srvd/sap/yui_dm_cfg_o4/0001/
```

Si el binding genera otra ruta o versión de endpoint, actualiza `webapp/manifest.json` con la URI que muestra ADT. La app obtiene el namespace de Aplicar desde el `$metadata` del servicio activado.

El proxy de `ui5.yaml` utiliza el **host API `.abap.`**, con `authenticationType: reentranceTicket` y cliente `100`. El host web `.abap-web.` devuelve el acceso OAuth si se usa sin la sesión apropiada. No cambies el proxy al host web ni copies cookies/tickets al proyecto.

Después de activar, publicar y ejecutar la inicialización, configura el sistema en **SAP Fiori → SAP SYSTEMS** de VS Code y ejecuta:

```sh
npm start
```

Completa el acceso SAP solicitado por Fiori tools. La URL debe estar **sin `mode=demo`**. La cabecera indica si se está comprobando la conexión, si hay datos demo o si está conectado a SAP. La app lee `$metadata` antes de habilitar cambios: comprueba las entidades y los parámetros de `Aplicar`, y obtiene su namespace desde el servicio. No permite guardar contra un binding de captura por error.

Si la conexión falla, se deshabilitan los cambios y se muestra una orientación diferente para login OAuth, binding/ruta, contrato incompatible o registro `GLOBAL` no visible. Una tabla vacía en ese estado no significa que SAP no tenga registros.

Para usar el frontend y la captura a la vez, arráncalos en puertos distintos: por ejemplo `npm start -- --port 8081` para este proyecto.

## Trabajo desde la web

El panel **Preparar una configuracion** permite recorrer Campos → Secciones → Flujos → Versiones → Pasos → Reglas. En Versiones, **Ver pasos** y **Ver reglas** abren el mantenimiento filtrado por la versión seleccionada.

**Revisar version** muestra los pendientes de flujo, fechas, pasos A/B, campos, secciones, reglas y solapamientos. Esa revisión se ejecuta sobre la instantánea cargada, sin escribir en SAP. Publicar sigue validando definitivamente en el backend y requiere un borrador editable.

Cada mantenimiento ofrece **Plantilla CSV**, **Exportar CSV** e **Importar CSV**; en pantallas estrechas algunas acciones están en el menú de más opciones de la barra. La exportación contiene los registros filtrados que están cargados, no solamente los que se ven en la primera página de la tabla.

1. Descarga la plantilla del mantenimiento y completa las claves y datos.
2. Usa CSV UTF-8 separado por **punto y coma**. Las cabeceras son los nombres técnicos de la plantilla. Fechas: `YYYY-MM-DD`; booleanos: `true/false` o `X/vacío`.
3. Elige el archivo o pega su texto en **Importar CSV** y pulsa **Validar archivo**. La vista previa no guarda nada.
4. El modo inicial solo crea. Para actualizar debes marcar explícitamente la opción de actualizar registros existentes editables. Las columnas omitidas conservan su valor en las actualizaciones; no cambian claves ni habilitan edición de versiones protegidas.
5. Corrige todos los errores de la vista previa antes de pulsar **Importar registros**. Se admiten hasta 500 registros / 2 MB por carga.

Cada registro usa la misma acción RAP que el formulario y confirma su propia transacción. No es una transacción única para todo el CSV. Un error detiene la carga y muestra el número de registros con confirmación; actualiza y revisa los restantes antes de repetir. Si otra sesión cambia la revisión entre registros, la carga se detiene para no actualizar usando una revisión no revisada por el usuario.

Las importaciones de versiones solo crean/actualizan borradores y fechas: no publican ni retiran. Importa en orden para que existan las referencias: campos/secciones → flujos → versiones → pasos → reglas. La vista previa complementa la validación del backend; puede haber errores adicionales al guardar (por ejemplo un campo que ya tiene datos capturados).

La exportación protege los textos que podrían interpretarse como fórmulas al abrirlos en una hoja de cálculo; la importación de ese mismo formato recupera su texto.

## Reglas de edición y publicación

- Pasos y reglas solo se editan en una versión **BORRADOR sin solicitudes**. Publicar o retirar los protege.
- Campos y secciones referenciados por versiones protegidas no se redefinen ni se inactivan; crea otra clave. Un campo con datos capturados también queda protegido en el backend.
- En un flujo publicado/usado solo se permite activar o desactivar su uso. Cambios de criterios o significado requieren otro flujo.
- Las reglas activas requieren campos/secciones activos y al menos un paso activo para su área. No se puede quitar el último paso activo de un área con reglas activas.
- Publicar requiere vigencias válidas, pasos aplicables tanto a A como a B, reglas activas válidas y ausencia de solapamientos con versiones/criterios activos equivalentes.
- Un mismo campo puede pertenecer a distintas áreas mediante reglas distintas. La unicidad es flujo + versión + área + campo, conservando el UUID de la regla al editar.
- Las ayudas de valores son referencias de configuración. Esta app no genera catálogos SAP de búsqueda ni modifica el maestro de materiales.

## Permisos, concurrencia y persistencia

Solo los usuarios activos en **`YMMT_DM_CFG_USR`** pueden usar el servicio administrativo. La inicialización habilita una sola vez al usuario técnico que la ejecuta. Las consultas administrativas filtran por esa autorización, y la acción vuelve a comprobarla. No se conceden automáticamente permisos al creador de una solicitud ni a los responsables de PCP/LOG/CONT.

Además de esta lista, asigna el acceso IAM del nuevo servicio a los usuarios correspondientes en tu sistema. La app no administra roles IAM ni agrega administradores desde la UI. Los administradores adicionales deben habilitarse mediante una intervención ABAP autorizada sobre la tabla de permisos; no hay autoalta después de la inicialización.

Cada guardado invoca la acción **Aplicar** sobre un registro de control `GLOBAL`. RAP usa su lock y ETag para serializar cambios y rechazar una pantalla desactualizada con HTTP 412. La app también comprueba que las seis colecciones leídas correspondan a una misma revisión. La revisión es global: incluso cambios en distintos mantenimientos pueden requerir que otro administrador actualice su pantalla.

El handler valida y prepara el cambio; el **additional saver** escribe las tablas existentes dentro de la misma transacción RAP que actualiza la revisión. No hay `COMMIT WORK` en el handler ni en el saver.

| Configuración | Persistencia |
| --- | --- |
| Campos | `YMMT_DM_CAMPO` |
| Secciones | `YMMT_DM_SECCION` |
| Flujos | `YMMT_DM_FLUJO` |
| Versiones | `YMMT_DM_FLUJO_VR` |
| Pasos | `YMMT_DM_PASO` |
| Reglas | `YMMT_DM_REGLA` |

Esta versión utiliza **dos tablas de soporte**: `YMMT_DM_CFG_CTL` (revisión/concurrencia) y `YMMT_DM_CFG_USR` (administradores). Se quitó la dependencia de `YMMT_DM_CFG_LOG`: el mantenimiento ya no requiere ni escribe un log administrativo. Esto es independiente del historial fino de solicitudes, que sigue pendiente en la app de captura.

Si ya importaste la tabla antigua `YMMT_DM_CFG_LOG`, conserva sus datos. Su archivo está ignorado en `.abapgit.xml` para evitar proponer su eliminación al actualizar; no se ejecutan borrados ni migraciones destructivas.

Los cargadores antiguos y escrituras SQL manuales no participan del lock/ETag administrativo. No los ejecutes mientras se mantiene configuración con esta app. El saver compara la configuración con la leída al validar y aborta la transacción si detecta cambios externos; un conflicto detectado en esa fase tardía puede producir un error técnico en SAP, sin confirmar un cambio parcial.

## Verificación

```sh
npm test
npm run check
python tools/validate_backend.py
npm run build
```

Prueba de navegador demo (puerto 8083 libre):

```sh
npx playwright install chromium
npm run test:browser
```

`abaplint.json` habilita análisis gramatical ABAP/CDS/BDEF. La clase `YCL_DM_CFG_MODEL` incluye pruebas ABAP Unit que debes ejecutar en ADT. **El análisis local no compila ni activa el servicio en tu SAP**, y las pruebas de navegador demo no acreditan todavía una escritura real en el Trial.

La conexión autenticada, la activación y los controles RAP deben verificarse con [el plan SAP](docs/INSTALACION_SAP.md) antes de usar configuración real.

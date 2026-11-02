# Instalacion y prueba con una sola tabla de soporte

## Requisitos y alcance

El backend original debe estar activo: las seis tablas de configuracion `YMMT_DM_CAMPO`, `YMMT_DM_SECCION`, `YMMT_DM_FLUJO`, `YMMT_DM_FLUJO_VR`, `YMMT_DM_PASO`, `YMMT_DM_REGLA`, las tablas `YMMT_DM_SOL` y `YMMT_DM_DATO`, y los tipos `YMME_DM_*`. Usa el mismo software component.

**La unica tabla adicional que requiere este mantenimiento es `YMMT_DM_CFG_CTL`.** No necesitas crear `YMMT_DM_CFG_USR`, `YMMT_DM_CFG_LOG` ni la CDS `YI_DM_CFG_USR`.

El rol especifico de administrador DM esta comentado y pendiente de activar, segun lo solicitado para esta prueba. Se conserva el login y acceso al servicio SAP. Un consumidor con ese acceso puede consultar y modificar configuracion. Consulta [el punto de autorizacion y como habilitarlo despues](AUTORIZACION_IAM_PENDIENTE.md).

## Primera instalacion: importar todo el mantenimiento

Si todavia no instalaste el backend de mantenimiento, no basta con copiar dos clases. Importa la carpeta `/src/` de esta version mediante un enlace abapGit **nuevo**, rama `feature/dm-mantenimientos`, a un paquete separado como `YECMAT_CFG`. No cambies el enlace del backend de captura ni selecciones eliminaciones de sus objetos.

Objetos que necesitas:

| Tipo | Objetos |
| --- | --- |
| Tabla nueva | `YMMT_DM_CFG_CTL` |
| Parametro CDS | `YD_DM_CFG_CMD` |
| CDS de administracion | `YI_DM_CFG`, `YC_DM_CFG` |
| CDS de lectura de catalogos | `YA_DM_CAMPO`, `YA_DM_SECCION`, `YA_DM_FLUJO`, `YA_DM_FLUJO_VR`, `YA_DM_PASO`, `YA_DM_REGLA` |
| Clases | `YCL_DM_CFG_MODEL`, `YCL_DM_CFG_STORE`, `YCL_DM_CFG_SETUP`, `YBP_I_DM_CFG` con sus implementaciones locales |
| Behaviors | `YI_DM_CFG`, `YC_DM_CFG` |
| DCL | `YR_I_DM_CFG`, `YR_C_DM_CFG` |
| Service Definition | `YUI_DM_CFG_O4` |

Orden de activacion:

1. `YMMT_DM_CFG_CTL`.
2. Abstract entity `YD_DM_CFG_CMD` y clase `YCL_DM_CFG_MODEL`; luego `YCL_DM_CFG_STORE`.
3. Los seis `YA_DM_*` y `YI_DM_CFG`.
4. Behavior `YI_DM_CFG` y pool `YBP_I_DM_CFG` juntos. Si ADT exige un stub, crea primero la clase vacia `FOR BEHAVIOR OF YI_DM_CFG`, activa ambos y agrega las implementaciones locales entregadas.
5. `YC_DM_CFG`, su behavior y las DCL `YR_I_DM_CFG`, `YR_C_DM_CFG`.
6. `YCL_DM_CFG_SETUP` y `YUI_DM_CFG_O4`.

Los nombres YI/YC son compartidos por CDS y behaviors como tipos de objeto distintos. No reemplaces las CDS o los behaviors de solicitudes, tareas o datos de captura existentes.

## Inicializar y publicar

1. Ejecuta `YCL_DM_CFG_SETUP` con **Run As -> ABAP Application (Console)** desde ADT.
2. Si falta `GLOBAL`, se crea con revision 0 en `YMMT_DM_CFG_CTL`. Si ya existe, se conserva su revision. No se modifican campos, flujos ni solicitudes y no se conceden permisos ni se crean usuarios.
3. Crea un **Service Binding OData V4 - UI** llamado `YBD_DM_CFG_O4` para `YUI_DM_CFG_O4`, activalo y publica su endpoint local. Se mantiene cualquier autorizacion de entrada al servicio que requiera tu SAP.
4. Comprueba `$metadata`: `Configuration`, `Campos`, `Secciones`, `Flujos`, `Versiones`, `Pasos`, `Reglas` y la accion bound `Aplicar`.
5. Usa su URI exacta en `webapp/manifest.json` si difiere de la preparada. La app valida los parametros y obtiene el namespace desde esa metadata. Los parametros fuente estan en `docs/action-parameters.json`; las fechas del comando se envian como texto `YYYYMMDD`.
6. En VS Code usa el host API `.abap.` de tu sistema en `ui5.yaml`, cliente 100 y `reentranceTicket`. Ejecuta `npm ci` y `npm start`, completando el acceso SAP. En PowerShell puedes usar `npm.cmd`.

La web debe mostrar **Conectado a SAP** y el aviso de rol especifico pendiente. El modo demo, con `?mode=demo`, no lee ni escribe SAP.

## Si ya instalaste alguna version anterior

Actualiza y activa los objetos modificados de esta version, no solo el frontend:

- `YCL_DM_CFG_STORE`, `YBP_I_DM_CFG` y sus implementaciones locales: cambian la llamada de autorizacion a `can_maintain` y se elimina la dependencia de la lista de administradores.
- `YCL_DM_CFG_SETUP`: solo inicializa `GLOBAL`.
- Los seis `YA_DM_*`: se retiraron los joins a la lista de usuarios.
- `YI_DM_CFG`: se retiro la asociacion de acceso a usuarios.
- `YR_I_DM_CFG`: grant temporal de lectura sin filtro de administrador. `YR_C_DM_CFG` conserva la herencia.

Si ya existen `YMMT_DM_CFG_USR`, `YMMT_DM_CFG_LOG` o `YI_DM_CFG_USR`, puedes conservarlos junto con sus datos sin que la app dependa de ellos. Sus archivos legacy estan ignorados en `.abapgit.xml` para evitar proponer su eliminacion. No ejecutes borrados ni reinicialices las seis tablas de configuracion. Revisa siempre la seleccion de objetos de abapGit.

Actualiza la carpeta de VS Code, ejecuta `npm ci` y reinicia el servidor. La version actual del frontend es 0.3.0.

## Verificacion en SAP

1. Ejecutar las 12 pruebas ABAP Unit de `YCL_DM_CFG_MODEL` en ADT.
2. Ejecutar el setup, guardar una configuracion de prueba y ejecutar el setup otra vez: `GLOBAL` debe conservar su revision actual.
3. Leer las seis colecciones sin crear una tabla de administradores y comprobar ETag/revision del registro `GLOBAL`.
4. Crear un campo y una seccion nuevos de prueba, verificar sus filas y el avance de revision.
5. Repetir una creacion con la misma clave: debe fallar sin sobrescribirla.
6. Copiar una version publicada a un numero nuevo, comprobar nuevos UUID de reglas y editar solo el borrador.
7. Intentar modificar una regla/paso publicado, redefinir un campo protegido, guardar referencias invalidas o publicar vigencias ambiguas: debe rechazarse sin cambios parciales.
8. Probar retiro/publicacion con configuracion controlada y crear una solicitud nueva con la version correspondiente. Las solicitudes existentes conservan su version; revisa las que esten sin iniciar antes de retirar su version.
9. Abrir dos sesiones sobre la misma revision: el segundo guardado debe detectar conflicto y requerir actualizar.
10. En este modo temporal no se espera rechazo por faltar el rol DM: no esta activo. El login y acceso al servicio siguen siendo necesarios. Cuando se implemente IAM, ejecutar tambien las pruebas negativas de lectura y escritura del documento de autorizacion.
11. Verificar una importacion CSV pequena, un error de validacion y una copia atomica de version/pasos/reglas, comprobando que no se confirma una revision o un cambio parcial de esa operacion cuando falla.

Las pruebas de activacion y ejecucion real requieren tu sesion SAP; no han podido ejecutarse desde este entorno. El analisis estatico y los servicios simulados no reemplazan estas verificaciones.

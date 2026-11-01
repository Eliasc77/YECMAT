# Instalación y prueba en ABAP Cloud Trial

## Requisitos

- Backend vigente `YMMT_DM_*` activo, incluidas las seis tablas de configuración, `YMMT_DM_SOL` y `YMMT_DM_DATO`.
- Dominios/elementos `YMME_DM_*` ya activos en el mismo software component.
- ADT y permisos de desarrollo para crear el paquete, activar objetos y publicar un Service Binding.

## Importación separada

1. Crea un paquete **nuevo**, por ejemplo `YECMAT_CFG`, en el mismo software component del backend.
2. Crea **otro enlace abapGit** al repositorio `https://github.com/Eliasc77/YECMAT.git`, rama `feature/dm-mantenimientos`, apuntando a ese paquete nuevo. El directorio de objetos es `/src/`.
3. No cambies la rama del enlace existente de `YECMAT`, de metadata o de utilidades a esta rama: es independiente y no contiene sus objetos; ese cambio puede ofrecer eliminarlos. Si aparecen eliminaciones de objetos anteriores, cancela la importación y revisa el paquete/enlace.
4. Importa únicamente los objetos nuevos del mantenimiento. Los archivos `webapp/`, `package.json`, etc. son para VS Code y no se importan como objetos ABAP.

No se modifican las definiciones de tablas existentes ni los behaviors de solicitudes/tareas/datos. El cambio administrativo se escribe mediante el nuevo servicio.

## Orden de activación

1. Tablas nuevas `YMMT_DM_CFG_CTL`, `YMMT_DM_CFG_USR` y `YMMT_DM_CFG_LOG`.
2. Abstract entity `YD_DM_CFG_CMD` y clase de validación `YCL_DM_CFG_MODEL`; después `YCL_DM_CFG_STORE`.
3. CDS `YI_DM_CFG_USR`, los seis `YA_DM_*` y raíz `YI_DM_CFG`.
4. Behavior `YI_DM_CFG` y pool `YBP_I_DM_CFG` juntos (el pool incluye handler y additional saver).
5. Proyección `YC_DM_CFG`, su behavior y las dos DCL `YR_I_DM_CFG`, `YR_C_DM_CFG`.
6. Clase `YCL_DM_CFG_SETUP` y Service Definition `YUI_DM_CFG_O4`.

Si ADT requiere un stub para activar el behavior/pool, crea la clase de pool vacía `FOR BEHAVIOR OF YI_DM_CFG`, activa ambos y luego agrega sus implementaciones locales. No cambies el tipo de las vistas de catálogos de captura existentes.

## Inicialización y acceso

1. Revisa que el usuario de desarrollo que ejecutará la inicialización sea el administrador deseado.
2. Ejecuta `YCL_DM_CFG_SETUP` desde ADT con **Run As → ABAP Application (Console)**.
3. La primera ejecución crea `GLOBAL` con revisión 0 y registra al usuario técnico actual como administrador activo. No carga ni sobrescribe campos, reglas, flujos o solicitudes.
4. Una repetición con administradores existentes no cambia permisos ni datos. Una inicialización parcial se detiene para revisión, sin autoasignar permisos.
5. Agrega otros administradores solo mediante código ABAP autorizado que mantenga `YMMT_DM_CFG_USR`. No borres la tabla para volver a ejecutar la inicialización. El permiso de ejecutar clases de desarrollo debe mantenerse restringido según las reglas de tu sistema.

## Binding y frontend

1. Crea un **Service Binding OData V4 – UI** llamado `YBD_DM_CFG_O4` para `YUI_DM_CFG_O4`.
2. Actívalo y publica el endpoint local. Asigna el acceso IAM correspondiente si tu entorno lo requiere.
3. Comprueba `$metadata`: debe exponer `Configuration`, `Campos`, `Secciones`, `Flujos`, `Versiones`, `Pasos`, `Reglas` y la acción bound `Aplicar`.
4. Comprueba en el `$metadata` real el namespace de Aplicar y los tipos de los parámetros. `docs/action-parameters.json` enumera los parámetros fuente; `Schema.command()` prepara todos, con fechas como texto `YYYYMMDD` para el comando administrativo.
5. Copia la ruta exacta del servicio a `webapp/manifest.json` si difiere de la preparada.
6. En VS Code usa el host API en `ui5.yaml`, cliente 100 y autenticación `reentranceTicket`. Ejecuta `npm ci` y `npm start`.

Para probar con dos usuarios, ambos deben tener acceso IAM y estar activos en la tabla administrativa. La sesión SAP del proxy pertenece al usuario que se autentique; comprueba su usuario técnico antes de mantener configuración.

## Pruebas necesarias en SAP

1. Ejecutar las **12 pruebas ABAP Unit de `YCL_DM_CFG_MODEL`** en ADT.
2. Con un administrador, leer configuración y comprobar revisión/ETag del registro `GLOBAL`.
3. Crear un campo y una sección **nuevos de prueba**; comprobar sus filas en las tablas existentes y la operación en `YMMT_DM_CFG_LOG`.
4. Repetir una creación con la misma clave: debe fallar sin sobrescribirla.
5. Copiar una versión publicada a un número nuevo. Comparar pasos/reglas y comprobar nuevos UUID de reglas.
6. Editar una regla de la copia y verificar que la original no cambió.
7. Intentar cambiar regla/paso publicado, redefinir campo protegido, guardar una referencia inexistente o publicar vigencias ambiguas: debe rechazarse sin modificar tablas.
8. Retirar/publicar con una configuración de prueba controlada y crear una solicitud nueva para comprobar la versión escogida por captura. No usar una versión real con solicitudes sin iniciar para esta prueba.
9. Abrir dos sesiones administrativas con la misma revisión: guardar en una y comprobar que la otra recibe conflicto y necesita actualizar.
10. Intentar la lectura/acción con un usuario no habilitado: la consulta debe quedar restringida y la acción debe denegarse. Una llamada HTTP directa no debe eludir el permiso.
11. Provocar un error de validación y comprobar que no se incrementó revisión ni se escribió el log.
12. Comprobar que una copia se guarda atómicamente (versión, pasos, reglas y revisión) y que una operación fallida no deja configuración parcial.

Estas pruebas no han podido ejecutarse desde este entorno: requieren tu sistema SAP y su sesión. Conserva los errores completos de activación/ejecución para ajustar compatibilidad con la versión ABAP de tu Trial.

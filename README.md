# YECMAT · Captura de materiales en SAPUI5

Proyecto completo para **VS Code**, rama independiente `feature/dm-ui5-captura`.
No necesitas generar otra aplicación. Esta rama contiene solo el frontend, sus pruebas e instrucciones. El backend RAP, la metadata DDLX y las utilidades de carga permanecen en sus ramas y paquetes SAP actuales.

## 1. Abrir el proyecto

Instala **Node.js 22 o 24 LTS**, Git, VS Code y la extensión **SAP Fiori tools – Extension Pack** (`sapse.sap-ux-fiori-tools-extension-pack`).

En una terminal:

```sh
git clone --single-branch --branch feature/dm-ui5-captura https://github.com/Eliasc77/YECMAT.git YECMAT_UI5
cd YECMAT_UI5
code .
npm ci
```

Si ya tienes esta rama clonada, usa `git pull --ff-only` dentro de su carpeta. Conserva separada cualquier carpeta que estés usando para el backend. **Esta rama no se importa con abapGit**: se ejecuta desde VS Code.

## 2. Probar las pantallas sin SAP

```sh
npm run start:demo
```

Abre `http://localhost:8080/index.html?mode=demo` si el navegador no se abre automáticamente. El primer arranque descarga OpenUI5 mediante UI5 Tooling; requiere Internet.

El modo demo muestra un aviso amarillo y una solicitud `DEMO-001` con tareas PCP, LOG y CONT. Usa un repositorio en memoria: **no consulta ni modifica SAP**, y todo se pierde al recargar la página.

Prueba este recorrido:

1. Selecciona `DEMO-001` y la tarea `PCP`.
2. Agrega un contexto **General**. Completa descripción, unidad base (por ejemplo `UN`) y grupo de artículos. Guarda.
3. Agrega **Unidad alternativa**, por ejemplo `BOX`. Completa numerador `10` y denominador `1`. Guarda.
4. Finaliza PCP. Los campos quedan en consulta.
5. En LOG agrega **Centro** `1000`, captura grupo de compras y guarda. Finaliza LOG. Almacén es opcional en esta configuración demo.
6. En CONT agrega **Valoración**, área `1000`. Captura precio estándar con punto decimal, guarda y finaliza.
7. Cierra captura. La solicitud demo de clasificación B queda `LISTA_INTEG`.

También puedes crear una solicitud e iniciar el flujo con clasificación A o B. A pasa a `REVISION` al cerrar y ofrece Aprobar. B pasa directamente a `LISTA_INTEG`. Reabrir tarea actúa sobre la tarea seleccionada.

La demostración reproduce el recorrido de captura; las autorizaciones, bloqueos, validaciones completas y configuración reales siempre los determina RAP.

## 3. Conectar tu SAP ABAP Cloud Trial

El proyecto ya apunta al host que compartiste, cliente `100`:

```text
https://6449ad14-b137-4a27-8017-6421c2c4f0b0.abap-web.us10.hana.ondemand.com
```

Servicio en `webapp/manifest.json`:

```text
/sap/opu/odata4/sap/ybd_dm_o4/srvd/sap/yui_dm_o4/0001/
```

1. En VS Code abre la vista **SAP Fiori → SAP SYSTEMS** y agrega tu sistema ABAP Environment si aún no aparece. Usa el mismo host. Completa el inicio de sesión con tu cuenta SAP cuando Fiori tools lo solicite; si el asistente solicita la clave de servicio de BTP, selecciónala localmente.
2. Ejecuta:

   ```sh
   npm start
   ```

3. Completa el inicio de sesión SAP que abra el proxy. La conexión de `ui5.yaml` usa **`authenticationType: reentranceTicket`**, requerida para ABAP Environment en BTP; no utiliza autenticación básica.
4. Abre `http://localhost:8080/index.html`. Sin `mode=demo`, las lecturas y escrituras se realizan contra SAP.
5. Selecciona la solicitud de prueba que ya creaste con `YCL_DM_CREAR_SOL_DEMO` y la tarea PCP.

El proxy de SAP Fiori tools recibe las peticiones `/sap` en localhost y las reenvía al sistema. Haber iniciado sesión en el navegador remoto de SAP no garantiza que el proxy local tenga sesión: completa también el acceso de Fiori tools.

No guardes contraseñas, claves de servicio, cookies o tickets en los archivos del proyecto. La configuración versionada solo contiene el host y el cliente. Para otro host, cambia `url` en `ui5.yaml`; para otra ruta, cambia la URI del manifest. El cliente de la aplicación está en `Service.js` y en `ui5.yaml`.

## Qué incluye

- Lista y búsqueda local de las solicitudes que RAP permite consultar.
- Creación de solicitud con flujo activo y versión publicada vigente. RAP valida el tipo de material y la operación.
- Inicio del flujo, cierre de captura, aprobación y reapertura de la tarea seleccionada.
- Selección e inicio/finalización de tareas por área.
- Contextos General, Centro, Almacén, Ventas, Valoración y Unidad alternativa. Cada contexto con subtipo se crea en un único **deep insert** con su composición.
- Formularios construidos desde **Campos + Secciones + Reglas**, filtrados por flujo, versión, área y tipo de segmento.
- Reglas M obligatorias, O opcionales, I ocultas; otros estados visibles se muestran en consulta. Se respetan secciones y campos activos.
- Texto, texto largo, fechas y booleanos; los números se conservan como texto para evitar pérdida de precisión. Fechas se envían como `YYYYMMDD`, booleanos como `X`/vacío y decimales con punto.
- Lectura paginada OData V4, tokens CSRF y ETags originales en actualizaciones/acciones. Un conflicto `412` requiere recargar, sin sobrescribir automáticamente.
- Avisos de cambios pendientes al cambiar de contexto/tarea/solicitud, ejecutar acciones o salir de la página.

Las ayudas de valores configuradas en `AyudaValores` se muestran como referencia; esta versión permite introducir la clave interna SAP. El servicio recibido no expone catálogos para implementar esas búsquedas. Los permisos del usuario se comprueban en el backend; el estado de los botones es una guía de navegación.

## Guardado y límites

Cada valor se guarda en una petición independiente y se confirma antes del siguiente. Si una petición falla, el mensaje indica cuántos valores se confirmaron; el resto permanece pendiente en pantalla. **No hay una transacción única para todo el formulario.**

Finalizar y Cerrar son peticiones posteriores al guardado. Finalizar valida todos los contextos del área en RAP, incluidos los que no están abiertos en pantalla. No ejecuta guardado automático. Actualizar permite descartar cambios pendientes y volver a leer SAP.

`LISTA_INTEG` indica que la solicitud está lista para una integración posterior. Esta app no crea materiales en el maestro SAP ni implementa esa integración.

El cliente está preparado con el contrato `$metadata` que compartiste. La conexión autenticada y las escrituras reales deben verificarse en tu VS Code con tu sesión SAP; las pruebas locales usan datos demo y respuestas OData simuladas.

## Validar y compilar

```sh
npm test
npm run check
npm run build
```

`npm test` verifica reglas, precisión, contextos, captura demo, paginación, CSRF, ETags y errores de autenticación. `npm run check` valida sintaxis JS/JSON. El build genera `dist/` y `Component-preload.js` para preparar una futura publicación; no despliega a SAP. Las bibliotecas OpenUI5 las sirve UI5 Tooling durante el desarrollo y deberán estar disponibles también en el destino de despliegue.

Prueba opcional en un navegador real, con el puerto 8082 libre:

```sh
npx playwright install chromium
npm run test:browser
```

Esta prueba inicia su propio servidor demo y comprueba creación de solicitud, captura en las tres áreas, avisos de cambios pendientes y cierre. `docs/service-contract.json` registra solo los nombres y tipos del `$metadata` recibido, sin registros de negocio ni credenciales.

## Si algo falla

| Síntoma | Qué revisar |
| --- | --- |
| HTML de login en lugar de JSON | Sesión del proxy, sistema en SAP SYSTEMS y `reentranceTicket`. |
| No aparecen solicitudes | Usuario conectado, autorizaciones DCL y que exista la solicitud en cliente 100. |
| No aparecen campos | Configuración de Campos/Secciones/Reglas activa para el flujo, versión y área de la tarea. |
| Falta contexto obligatorio al finalizar | Agrega todos los tipos de contexto con reglas M y completa los campos de cada contexto. |
| Error 412 | Otro usuario modificó el registro. Recarga y revisa sus valores antes de guardar. |
| El contexto ya existe | Selecciona el contexto existente; sus claves no se editan después de crearlo. |
| Puerto 8080 ocupado | Detén el otro servidor o ejecuta `npx ui5 serve --config ui5-demo.yaml --port 8081` para demo. |

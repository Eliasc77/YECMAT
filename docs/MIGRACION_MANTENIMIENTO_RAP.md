# Mantenimiento DM con RAP y Preview Fiori elements

## Alcance

Rama `feature/dm-mantenimiento-rap`, basada en `main` fc30682 mas el refactor de
constantes publicado hasta e415d2f. Solo objetos Y*. No sustituye ni modifica la
app de solicitudes en VS Code ni sus entidades actuales.

Servicio nuevo: **YUI_DM_MNT_O4**. Crear en ADT su Service Binding
**YBD_DM_MNT_O4**, tipo **OData V4 - UI**. No usar el binding antiguo como preview
de este desarrollo: expone otras entidades y no estas operaciones draft.

Las tres entradas para el Preview son **Campos**, **Secciones** y **Flujos**.
Flujos navega a Versiones; cada version contiene Pasos y Reglas. Crear/Editar,
Guardar, Cancelar y borradores tecnicos son operaciones estandar de Fiori elements.
Las acciones Copiar, Publicar y Retirar se ejecutan sobre versiones guardadas;
no durante una edicion draft. Tras copiar, actualizar la lista de versiones.

## Dos significados de borrador

- **Draft tecnico RAP:** una edicion temporal que se activa o descarta. Se guarda
  en YMMT_DM_D_* y permite editar desde Fiori elements V4.
- **Estado de negocio BORRADOR:** una version de flujo aun no publicada. Se guarda
  definitivamente en YMMT_DM_FLUJO_VR y puede seguir usandose para configurar reglas.

Guardar una edicion RAP no publica automaticamente una version del flujo.
Los ETags detectan escrituras obsoletas; no sustituyen al draft tecnico.

## Base de datos

Las seis tablas activas conservan sus columnas y claves anteriores y agregan:

- LAST_CHANGED_AT: cambio del objeto, usado como total ETag en las raices.
- LOCAL_LAST_CHANGED_AT: ETag individual de la entidad.

Se agregan seis tablas tecnicas de draft: YMMT_DM_D_CAMPO, YMMT_DM_D_SECCION,
YMMT_DM_D_FLUJO, YMMT_DM_D_FLUJO_VR, YMMT_DM_D_PASO y YMMT_DM_D_REGLA.
No son nuevos catalogos funcionales ni nuevas tablas de autorizaciones o logs.
El include SYCH_BDL_DRAFT_ADMIN_INC es el estandar de administracion de draft.

## Transicion y concurrencia

**En esta fase se conserva YMMT_DM_CFG_CTL.** Se agrega RAP_ACTIVO como indicador
de cambio de escritor. Las nuevas raices usan su bloqueo a traves de un lock
handler unmanaged y precheck de creacion. Mientras se conserve ese bloqueo global,
distintos administradores no deben esperar editar catalogos diferentes en paralelo.
El flujo es el agregado draft: no se editan dos versiones del mismo flujo de forma
independiente. Sus pasos y reglas forman parte de ese agregado.

Antes del cambio, Aplicar sigue funcionando y el nuevo servicio puede consultarse.
YCL_DM_MNT_SETUP inicializa solo los timestamps que esten a cero y habilita
RAP_ACTIVO bajo el mismo bloqueo. Una vez habilitado, **Aplicar rechaza escrituras**
con un mensaje que indica usar RAP Preview. Sus lecturas y los catalogos para
captura permanecen disponibles. No hay dos escritores administrativos activos.
La revision numerica antigua no es el ETag de las nuevas entidades.

No se debe ejecutar el cambio durante una edicion administrativa. No modificar
estas tablas mediante SQL, Data Preview u otros escritores al margen del BO.
La retirada definitiva de CFG_CTL/Aplicar y del bloqueo global es una fase posterior;
requiere retirar el endpoint anterior y disenar la coordinacion entre catalogos.
No borrar CFG_CTL con esta entrega.

## Validaciones y controles

YCL_DM_MNT_MODEL adapta el agregado que RAP tiene en memoria y reutiliza
YCL_DM_CFG_MODEL. El framework managed persiste los datos; no se utiliza
CFG_STORE.stage/persist para los cambios nuevos.

- No se permite eliminar datos activos. Se desactivan campos/pasos/reglas cuando
  corresponde; Discard solo descarta la edicion tecnica.
- Versiones publicadas, retiradas o usadas protegen sus definiciones.
- Un campo utilizado permite cambiar solo AyudaValores; su estructura sigue protegida.
- Pasos y reglas de versiones protegidas no permiten edicion.
- Las claves de registros guardados no se cambian.
- Se validan referencias, tipos, longitudes, fechas, areas con paso y reglas activas.
- La publicacion verifica vigencias, cobertura de A/B y responsable unico de captura.
- Un campo puede aparecer como lectura en otra area sin crear otro responsable.
- Los cambios simultaneos en pasos/reglas se validan contra la propuesta final.
- Cada transaccion modifica un solo agregado raiz (campo, seccion o flujo). El
  backend rechaza changesets que mezclen raices; todos los detalles de un flujo
  pueden guardarse juntos. El contexto se limpia en el saver, incluso al fallar.

Al crear un registro, marcar Activo/Obligatorio segun corresponda; no se fuerzan
booleanos ni EstadoCampo recibidos desde la pantalla. Una version nueva si inicia
en BORRADOR y recibe su usuario/fecha. M/O/I/R y C/M/I se ingresan como codigos;
la primera entrega no agrega catálogos de seleccion para esos enumerados.

## Autorizacion

Se reutiliza can_maintain de CFG_STORE, que conserva el modo temporal sin rol IAM
pedido para el Trial. RAP_ACTIVO habilita el nuevo escritor; **no es un permiso
por usuario**. Se requiere la sesion y acceso al servicio SAP. Las CDS nuevas
mantienen TODO IAM y #NOT_REQUIRED igual que los catalogos actuales.
La configuracion del rol administrativo y sus DCL sigue pendiente.

## Orden de importacion y activacion

1. Sincronizar esta rama en el mismo repositorio/paquete que los objetos Y*.
   Revisar el inventario de objetos; no importar cambios Z*.
2. Activar las siete tablas activas modificadas y las seis tablas de draft nuevas.
   Los cambios sobre tablas activas son aditivos; no recrearlas ni borrar sus datos.
3. Activar la entidad abstracta YD_DM_M_COPIAR y las nuevas CDS YI_DM_M_* y YC_DM_M_*
   en conjunto, porque tienen referencias ciclicas de composicion/padre.
4. Activar en conjunto los behaviors base/proyeccion, sus tres pools y las clases
   YCL_DM_MNT_MODEL, YCL_DM_MNT_ACCESO, YCL_DM_MNT_TRANS, YCL_DM_MNT_SETUP. Activar tambien el cambio
   de YBP_I_DM_CFG que impide escrituras anteriores despues del cambio.
5. Activar las seis Metadata Extensions YC_DM_M_*_UI y YUI_DM_MNT_O4.
6. Crear YBD_DM_MNT_O4 como **OData V4 - UI**, asignar YUI_DM_MNT_O4 y publicar.
7. Ejecutar las pruebas ABAP Unit de YCL_DM_CFG_MODEL y YCL_DM_MNT_MODEL.
8. Revisar el Preview en modo consulta antes de habilitar la escritura.
9. Con la configuracion cerrada para los administradores, ejecutar YCL_DM_MNT_SETUP
   con F9. Si GLOBAL no existe, ejecutar antes YCL_DM_CFG_SETUP.
   Este es el paso que habilita la escritura nueva y deshabilita Aplicar.
10. Abrir el Preview del nuevo binding, seleccionar Campos, Secciones o Flujos.
    No es necesario iniciar npm ni modificar la app de solicitudes para probarlo.

Si la version del Trial exige ajustar los detalles tecnicos de las tablas draft,
ADT ofrece Generate Draft Table desde el behavior para verificar su estructura.
Si aparece el error de indice Inverted Individual, ajustar el tipo de clave en
los ajustes tecnicos de la tabla. Esa propiedad depende del release; no se usa
un valor XML supuesto para forzarla.

## Prueba funcional minima en SAP

- Campos: crear uno inactivo; editarlo; cancelar y comprobar que no cambio el activo.
- Campo utilizado: AyudaValores editable, estructura de lectura. Verificar rechazo
  del backend si se intenta alterar Longitud mediante una llamada directa.
- Flujos: crear un flujo con una version de negocio BORRADOR, un paso para A/B y
  una regla; Guardar. Comprobar los registros activos y timestamps.
- Modificar un campo en un draft y Discard: no debe alterar el dato activo.
- En la version activa: Copiar a otro numero, comprobar pasos/reglas y sus flags.
- Publicar: comprobar validaciones; si otra version publicada se solapa, retirarla
  o ajustar las vigencias antes de publicar.
- Abrir dos sesiones: comprobar bloqueo y, con un ETag anterior, rechazo HTTP 412.
- Expirar un draft, cambiar el activo y reanudar: comprobar total ETag.
- Despues del cambio: Aplicar debe rechazar escritura; la captura debe seguir
  leyendo sus catalogos y guardando solicitudes mediante su servicio original.

## Verificacion disponible aqui

- tools/check_dm_rap.py verifica esquema aditivo, claves/columnas de draft,
  asociaciones del contrato, ETags, switch de escritor y ausencia de cambios Z*.
- abaplint analiza la gramatica de los objetos Y*.
- Se entregan 11 pruebas ABAP Unit del adaptador, ademas de las 12 existentes.

**No se ha realizado activacion, ejecucion ABAP Unit ni prueba real de Preview
contra el Trial desde este entorno.** El analisis local no sustituye el compilador
ABAP ni garantiza compatibilidad con el release del sistema.

## Referencias

- SAP: Prerequisites for Using SAP Fiori Elements (edicion V4 con draft):
  https://help.sap.com/docs/ABAP_PLATFORM_NEW/468a97775123488ab3345a0c48cadd8f/f2344b5e78164b2b9c27ef8b068f295c.html
- Ejemplo oficial de estructura draft y behavior:
  https://github.com/SAP-samples/abap-cheat-sheets/blob/main/src/zdemo_abap_rap_draft_m.bdef.asbdef

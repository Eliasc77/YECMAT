# Despliegue en SAP BTP ABAP Environment Trial

## Prerrequisitos

- SAP BTP ABAP Environment Trial y Eclipse/ADT actualizado.
- Plugin abapGit para ADT.
- Paquete `YECMAT` y autorización para publicar service bindings.

## Orden

1. Vincular el paquete `YECMAT` a `https://github.com/Eliasc77/YECMAT`, rama
   `main`, y ejecutar Pull. `.abapgit.xml` y metadata están incluidos.
2. Activar las definiciones de tabla `zdm_*.ddls.asddls`.
3. Activar CDS de interfaz y consumo.
4. Activar behavior definitions y clases behavior pool.
5. Activar service definition y service binding OData V4 UI.
6. Cargar `ZDM_FIELD_C` con la matriz aprobada del Excel.
7. Crear los roles PFCG y asignar autorizaciones por centro, tipo y área.
8. Ejecutar `ZCL_DM_TRIAL_ACTIVATION` como ABAP Application (Console) para probar
   el modo MOCK.
9. Para integración real, crear el Service Consumption Model y Communication
   Arrangement de la API pública del S/4 externo.

## Bloqueos antes de productivo

- Los métodos `get_instance_authorizations` permiten provisionalmente las
  operaciones para facilitar la activación inicial. Sustituirlos por
  `AUTHORITY-CHECK` contra los objetos PFCG creados; la UI nunca es control de
  seguridad suficiente.
- Sustituir el mock por una API HTTP liberada; BAPIs, commits clásicos y acceso a
  MARA/MARC no son válidos en BTP ABAP Environment.
- Generar y publicar un service binding OData V4 UI llamado, por ejemplo,
  `ZUI_DM_O4` desde la service definition incluida.

## Decisiones que requieren datos del sistema

- El PDF usa `ZLEE` y el Excel también menciona `ZENV`: confirmar si son alias o
  tipos distintos antes de cargar customizing.
- Confirmar nombres reales de características/clases, campos Z y códigos de
  estado de material.
- Definir pools de correo, SLA por área y mecanismo productivo para ejecutar el
  outbox (Application Jobs recomendado).

No se deben guardar credenciales ni destinos RFC en Git.

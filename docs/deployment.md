# Despliegue en S/4HANA 2022

## Prerrequisitos

- ABAP Platform 2022 (base de la imagen proporcionada).
- ADT actualizado y abapGit.
- Gateway/OData V4 y SAP Fiori habilitados.
- Autorización para crear objetos Z y publicar service bindings.

## Orden

1. Crear el paquete en ADT y crear los objetos con las fuentes de `src/`. Si se
   desea importación abapGit directa, serializar una primera vez desde el release
   destino para incorporar sus XML de metadata (no se inventan porque varían por
   versión de serializador).
2. Activar las definiciones de tabla `zdm_*.ddls.asddls`.
3. Activar CDS de interfaz y consumo.
4. Activar behavior definitions y clases behavior pool.
5. Activar service definition y service binding OData V4 UI.
6. Cargar `ZDM_FIELD_C` con la matriz aprobada del Excel.
7. Crear los roles PFCG y asignar autorizaciones por centro, tipo y área.
8. Adaptar/probar `ZCL_DM_MATERIAL_PORT` en mandante de calidad.
9. Programar el consumidor outbox y el job horario de alertas.

## Bloqueos antes de productivo

- Los métodos `get_instance_authorizations` permiten provisionalmente las
  operaciones para facilitar la activación inicial. Sustituirlos por
  `AUTHORITY-CHECK` contra los objetos PFCG creados; la UI nunca es control de
  seguridad suficiente.
- Verificar los componentes exactos de `BAPI_MARA`, `BAPI_MARC` y `BAPI_MBEW`
  disponibles en el sistema y completar textos, clasificación, unidades y
  extensiones mediante `EXTENSIONIN` cuando corresponda.
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

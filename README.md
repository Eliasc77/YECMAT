# YECMAT – Gestión de datos maestros de materiales

Implementación base con **ABAP RESTful Application Programming Model (RAP)** para
SAP S/4HANA 2022 / ABAP Platform 2022.

La solución recibe solicitudes de creación, modificación e inactivación de
materiales, permite que las áreas trabajen en paralelo y recién actualiza el
maestro estándar al finalizar el flujo. El diseño evita mantener bloqueos sobre
MARA/MARC durante la captura.

## Alcance implementado

- Solicitud y tareas independientes por área (`PCP`, `AR`, `CONT`, `LOG`, `AS`,
  `CC` y solicitante).
- Valores genéricos por campo técnico para soportar una matriz dinámica sin
  regenerar la aplicación.
- Estados de semáforo `G/R/A/V`, clasificación BPM/no BPM y acciones RAP para
  finalizar, reabrir, rechazar y aprobar.
- Validación de obligatoriedad contra `ZDM_FIELD_C` al finalizar un área.
- Auditoría de cambios y patrón outbox para procesamiento asíncrono.
- Contrato para encapsular `BAPI_MATERIAL_SAVEDATA`; la adaptación exacta de
  campos Z queda localizada en una sola clase.

## Estructura

- `src/`: fuentes ADT/abapGit.
- `docs/requirements.md`: especificación consolidada de los adjuntos.
- `docs/architecture.md`: decisiones técnicas, estados y concurrencia.
- `docs/deployment.md`: orden de activación y configuración en SAP.
- `docs/test-plan.md`: pruebas funcionales y de concurrencia.

## Uso

Crear los objetos desde ADT con las fuentes versionadas en `src/` (o añadir la
metadata XML del serializador abapGit del sistema destino), activar en el orden
indicado en `docs/deployment.md` y publicar el binding OData V4. No se requiere
Node.js ni servicios locales: el runtime es el servidor ABAP.

> Las tablas estándar solo se modifican desde el consumidor de outbox. Nunca se
> llama la BAPI mientras un usuario está editando una solicitud.

## Estado de la entrega

Este repositorio contiene el núcleo backend y el contrato OData. La activación
en un sistema SAP real sigue siendo obligatoria porque tipos DDIC, campos Z,
objetos de autorización y la firma/configuración efectiva de la BAPI dependen
del mandante. No se debe transportar a productivo sin ejecutar el plan de
pruebas y reemplazar la autorización provisional de los behavior pools.

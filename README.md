# YECMAT – Gestión de datos maestros de materiales

Implementación base con **ABAP RESTful Application Programming Model (RAP)** para
SAP BTP ABAP Environment Trial, usando exclusivamente fuentes ABAP Cloud.

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
- Activación `MOCK` ejecutable dentro del trial y patrón outbox preparado para
  sustituirse por una API HTTP pública de Product Master de un S/4 externo.

## Estructura

- `src/`: fuentes ADT/abapGit.
- `docs/requirements.md`: especificación consolidada de los adjuntos.
- `docs/architecture.md`: decisiones técnicas, estados y concurrencia.
- `docs/deployment.md`: orden de activación y configuración en SAP.
- `docs/test-plan.md`: pruebas funcionales y de concurrencia.

## Uso

Vincular el paquete ADT con este repositorio mediante abapGit y ejecutar Pull
sobre `main`. El repositorio incluye `.abapgit.xml` y metadata de sus objetos.
Después se crea y publica el binding OData V4 en ADT. No se requiere Node.js ni
servicios locales: el runtime es SAP BTP ABAP Environment.

> BTP Trial no contiene MARA/MARC ni permite BAPIs clásicas. La activación real
> debe llamar por HTTPS una API liberada del sistema S/4 destino.

## Estado de la entrega

Este repositorio contiene el núcleo backend, el contrato OData y una activación
simulada para probar el flujo íntegro en el trial. No se debe transportar a
productivo sin conectar la API pública de Product Master y reemplazar la
autorización provisional de los behavior pools.

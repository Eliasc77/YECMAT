# Arquitectura RAP

## Agregados

```text
Solicitud ZDM_REQ_H
  ├── 1..n tareas de área ZDM_REQ_A     (raíz RAP, ETag propio)
  ├── 1..n valores ZDM_REQ_F            (raíz RAP, ETag propio)
  ├── 0..n auditorías ZDM_AUDIT         (solo lectura)
  └── 0..n mensajes outbox ZDM_OUTBOX   (procesamiento asíncrono)

Customizing ZDM_FIELD_C
  └── tipo material + operación + área + campo → I/O/M/R
```

`I/O/M/R` significa invisible, opcional, obligatorio y solo lectura.

No se usa una composición RAP única para las ediciones concurrentes: bloquear
la raíz de una composición serializaría todas las áreas. Cada tarea y valor es
una raíz transaccional con `last_changed_at` como ETag. La cabecera se actualiza
solo en transiciones cortas y nunca se mantiene bloqueada durante la captura.

## Estados

- Solicitud: `DRAFT`, `CLASSIFY`, `PARALLEL`, `QA_REVIEW`, `QUEUED`, `ACTIVE`,
  `ERROR`, `REJECTED`.
- Área: `G` no requerida, `R` pendiente, `A` en proceso, `V` finalizada.
- Outbox: `N` nueva, `P` procesando, `S` exitosa, `E` error.

Toda transición comprueba el estado actual. `finishArea` valida solo los campos
de su área. `rejectArea` reabre únicamente el área indicada. El último cierre
no BPM y `approveAndActivate` escriben una fila outbox de forma idempotente.

## Creación del material

`ZCL_DM_MATERIAL_PORT` es la frontera con SAP. El consumidor bloquea la fila
outbox, reconstruye las estructuras BAPI desde el staging/customizing, ejecuta
`BAPI_MATERIAL_SAVEDATA` y confirma o revierte. El `request_uuid` es la clave de
idempotencia; un evento exitoso no vuelve a procesarse.

Los campos de clasificación/textos/unidades y ampliaciones Z requieren adaptar
el mapper a la configuración real del mandante. Esa adaptación no afecta al BO
RAP ni a la UI.

## Alertas y KPI

Un job Application Job consulta tareas `R/A` vencidas y envía avisos mediante
`CL_BCS`. El cuello de botella es `max(finished_at) - parallel_started_at`; el
área con mayor `finished_at` se marca como responsable de la demora.

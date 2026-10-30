# Requerimiento consolidado

> Referencia funcional histórica del modelo BTP Trial. Los nombres ZDM_* describen
> el modelo anterior. Consultar [MODELO_DATOS.md](arquitectura/MODELO_DATOS.md) para
> persistencia vigente. Behaviors, auditoría, outbox e integración requieren reconstrucción.

Fuente funcional: `Configuración DM v2 (1).pdf` y `Resumen por áreas.xlsx`.
Los documentos son referencias; este archivo expresa el comportamiento que
implementa la solución.

## Operaciones

- Creación/copia, modificación e inactivación.
- Centros: `1000` Vitaline y `1100` Lansier.
- Tipos identificados: `ZFER`, `ZHAW`, `ZHAL`, `ZROH`, `ZVER`, `ZLEE`/`ZENV`,
  `ZSUM`, `ZERS` y `ZHIB`.
- Para producto terminado y semielaborado inicia PCP; para los demás inicia un
  solicitante autorizado.

## Flujo

1. El iniciador crea el borrador de solicitud.
2. Calidad clasifica BPM (`A`) o no BPM (`B`).
3. Las tareas requeridas de AR, Logística y Contabilidad se habilitan en paralelo.
4. Cada área guarda progreso sin validar obligatorios y finaliza validando la
   matriz `tipo de material + área + campo técnico`.
5. En flujo A, Calidad aprueba o devuelve un área específica para corrección.
6. En flujo B, al finalizar la última tarea se encola automáticamente la creación.
7. Un consumidor asíncrono crea/modifica/inactiva el material y registra el
   resultado, sin bloquear la sesión de usuario.

## Campos y propiedad inicial

| Área | Campos principales |
|---|---|
| SOLIC/PCP | texto breve, texto de compras, centro, tipo, UM base, grupo de artículos, almacén, condiciones, ventas, empaque, peso/volumen |
| AR | textos básicos e inspección, registro sanitario, línea, conservación, EAN/UPC, titularidad |
| CONT | código ONU/SUNAT, precio estándar, centro de beneficio, cantidad base |
| LOG | grupo de compras, precio variable, cantidades de lote, plazo de entrega |
| AS | estado de material |
| CC | normas técnicas y decisión/aprobación BPM |

La propiedad y obligatoriedad exactas son datos de customizing en `ZDM_FIELD_C`.
Esto resuelve diferencias entre el PDF y el Excel sin codificarlas en la UI.

## Reglas no incluidas como constantes

Las matrices extensas de vistas, almacenes, grupos de artículo, valoración,
unidades alternativas, clasificación, ventas, CeBe, planificación, QM y coste se
deben cargar como customizing. No se incrustan en código porque cambian por
centro/tipo y deben mantenerse sin transporte de lógica.

## Seguridad

Objetos de autorización previstos por rol:
`Z_DM_ACCESO_SOLICITANTE`, `Z_DM_ACCESO_REGULATORIO`,
`Z_DM_ACCESO_CONTABILIDAD`, `Z_DM_ACCESO_LOGISTICA`,
`Z_DM_ACCESO_PCP` y `Z_DM_ACCESO_CALIDAD`.

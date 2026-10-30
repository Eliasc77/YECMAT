# Plan de comprobación DM

## Comprobaciones locales

`python3 tools/validate_dm.py` verifica XML, 15 tablas, 6 dominios, 6 elementos, campos/PK/tipos,
componentes FK con elementos de datos y dominios compatibles, FK completas con mandante, metadata DD05M/DD08V, índices y coherencia DER/JSON/
diccionario. `python3 -m tools.validate_rap` contrasta los objetos RAP.
`python3 -m unittest discover -s tests -v` prueba que el validador
detecta alteraciones críticas sobre copias temporales. No compilan ABAP.

## Pruebas pendientes en ADT/SAP

1. Importar/activar 15 tablas; revisar tipos reales, claves, FK, índices físicos,
   configuración Unicode, versión abapGit y ATC en el release destino.
2. Mismo UUID/número en mandantes distintos: aislamiento. Número repetido en el
   mismo mandante: rechazo por índice único.
3. En los handlers RAP: rechazar UUID inicial, huérfanos, tareas de otra versión
   de SOL y AREA distinta al PASO. Impedir bajas de padres utilizados.
4. Permitir varios centros, almacenes, canales de ventas, tipos de valoración y
   unidades dentro de una solicitud; no mezclar valores entre contextos.
5. Rechazar subtipo incorrecto, múltiples subtipos, organizativo sin subtipo y
   GENERAL con subtipo; permitir GENERAL sin subtipo.
6. Dos sesiones creando mismo contexto: una sola creación; repetir con GENERAL.
   Fallo al crear subtipo: rollback completo. Verificar lock hasta commit.
7. Mismo campo en contextos distintos: valores independientes; duplicado en mismo
   segmento: rechazo por PK. Rechazar campo de otro tipo de segmento.
8. Rechazar reglas duplicadas, área sin paso, campo inactivo, estados inválidos y
   longitud/decimales inválidos. Guardar progreso admite vacíos; completar valida
   obligatorios por contexto, incluso cuando falta DATO.
9. Publicar otra versión: SOL previa mantiene versión y semántica originales.
   Rechazar cambios de configuración publicada, criterios históricos y vigencias
   solapadas o selección ambigua.
10. Validar conversiones MATNR/MEINS, fechas, decimales y booleanos sin pérdida;
    rechazar más de 1333 caracteres sin truncamiento.
11. Con los behaviors: editar áreas/contextos independientes simultáneamente; detectar
    conflicto sobre mismo dato y ejecutar transiciones globales atómicas. No usar
    timestamp de creación como ETag de modificación.
12. Verificar autorizaciones backend desde OData e intentos de saltar la UI,
    aislamiento por mandante, servicio/binding V4 en release real.

13. Probar If-Match válido/obsoleto en DATO y acciones; dos usuarios editando
    campos distintos de áreas distintas deben guardar, y el mismo dato debe
    detectar conflicto. Campos compartidos con área finalizada no son editables.
14. Mantener una escritura de Valor sin terminar la LUW y ejecutar Finalizar o
    Cerrar desde otra sesión: debe recibirse mensaje de tarea en edición. Tras
    commit/rollback reintentar; no debe cerrarse con valores inválidos concurrentes.
15. Ejecutar los cinco métodos ABAP Unit de YCL_DM_RULES. En dos sesiones, probar
    contexto duplicado, root/subtipo incompleto y cambio de responsable concurrente.
16. Intentar crear contexto o guardar valores junto con cierre en un changeset:
    debe rechazarse la mezcla. Seguir el contrato de peticiones separadas.

Son criterios pendientes, no resultados de pruebas ejecutadas en SAP.

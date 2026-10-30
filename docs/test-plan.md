# Plan de comprobación DM

## Comprobaciones locales

`python3 tools/validate_dm.py` verifica XML, 15 tablas exactas, campos/PK/tipos,
FK completas con mandante, metadata DD05M/DD08V, índices y coherencia DER/JSON/
diccionario. `python3 -m unittest discover -s tests -v` prueba que el validador
detecta alteraciones críticas sobre copias temporales. No compilan ABAP.

## Pruebas pendientes en ADT/SAP

1. Importar/activar 15 tablas; revisar tipos reales, claves, FK, índices físicos,
   configuración Unicode, versión abapGit y ATC en el release destino.
2. Mismo UUID/número en mandantes distintos: aislamiento. Número repetido en el
   mismo mandante: rechazo por índice único.
3. Con RAP implementado: rechazar UUID inicial, huérfanos, tareas de otra versión
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
11. Tras behaviors: editar áreas/contextos independientes simultáneamente; detectar
    conflicto sobre mismo dato y ejecutar transiciones globales atómicas. No usar
    timestamp de creación como ETag de modificación.
12. Verificar autorizaciones backend desde OData e intentos de saltar la UI,
    aislamiento por mandante, servicio/binding V4 en release real.

Son criterios pendientes, no resultados de pruebas ejecutadas en SAP.

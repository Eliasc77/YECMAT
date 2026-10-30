# Preparación e importación en S/4HANA On-Premise

No se ha conectado SAP ni activado objetos. Confirmar release S/4HANA, SAP_BASIS,
ADT, abapGit y soporte de RAP/OData V4 antes de importar.

1. Ejecutar validaciones locales del README y revisar el inventario de bajas.
2. Revisar dependencias externas en ADT, respaldar datos y preparar transporte de
   transición. Git no identifica consumidores fuera de este repositorio.
3. Conservar el paquete existente; verificar configuración para ABAP estándar
   On-Premise, namespace Y y autorizaciones. La metadata de paquete se conserva
   sin modificar. El objetivo inicial es On-Premise; si el paquete usa lenguaje
   restringido, verificar disponibilidad de cada tipo estándar en el sistema real.
   La corrección elimina FIELDNAME/TABNAME, sin certificar toda la compatibilidad Cloud.
4. Confirmar elementos MANDT, SYSUUID_X16, SYUNAME, TIMESTAMPL, BOOLE_D, MATNR,
   MTART, WERKS_D, LGORT_D, VKORG, VTWEG, BWKEY, BWTAR_D y MEINS.
   Revisar extensión/longitud de material y conversión CUNIT.
5. Importar primero objetos nuevos sin ejecutar bajas. Revisar el plan abapGit.
   Activar primero los seis dominios YMMD_DM_* y luego los seis elementos
   YMME_DM_* incluidos. Después activar las tablas.
   Orden de tablas (prefijo YMMT_DM_): FLUJO/CAMPO/SECCION; FLUJO_VR; PASO/REGLA/SOL;
   TAREA/SEG; SEG_CEN/ALM/VEN/VAL/UOM y DATO.
6. Activar en ADT/SE11, comprobar PK/FK, índices Z01/Z02, clases de entrega,
   configuración técnica y ejecutar ATC. La comprobación local no lo sustituye.
7. Cargar catálogo/secciones, flujo/versiones en borrador, pasos y reglas usando
   herramientas autorizadas; validar vigencias, criterios, áreas y campos antes
   de publicar configuración. No hay carga inicial implícita.
8. Diseñar RAP: altas atómicas SEG/subtipo, locks, validaciones, autorizaciones,
   auditoría y estrategia ETag/draft; crear CDS, behaviors, clases, proyecciones,
   servicio y binding V4 según release. No reutilizar directamente el servicio viejo.
9. Preparar migración histórica asignando versión y contexto explícitos; reconciliar
   conteos y valores antes del corte. Auditoría, outbox e integración con material
   estándar requieren diseño propio: no tienen sustituto en las 15 tablas del DER.
10. Ejecutar el plan SAP antes de publicar servicios o retirar objetos antiguos.

No hay scripts DROP TABLE/DELETE FROM ni migración destructiva. La baja de una
fuente Git no autoriza borrar el objeto físico ni sus registros en SAP.

# Validaciones del modelo y capa RAP

## Evidencia local de esta rama

| Comprobación | Resultado |
|---|---|
| Validador de persistencia | 15 tablas, 6 dominios, 6 elementos; 107 campos, 16 FK, 6 índices |
| Validador RAP | 30 CDS de tabla + 4 auxiliares/parámetros, 18 DCL, 8 BDEF, 4 pools y 15 entity sets |
| Pruebas Python | 23 pruebas de contrato y regresión aprobadas |
| abaplint 2.120.92 | 0 incidencias en 165 archivos de fuentes/metadata, gramática Cloud |
| Mermaid 11.12.0 | DER actualizado analizado como erDiagram |
| XML | Metadata bien formada, pares fuente/XML presentes |
| Persistencia | PK y FK conservadas; cinco columnas nuevas, tipos de audit/booleano actualizados e índice SEG.Z02 |
| Git | Rama feature/dm-rap-dinamico desde 83a47aa; sin bajas de fuentes existentes en esta rama |

Las regresiones incluyen PK/FK, dominios, tipos, índice único, campos y cardinalidad,
mapeo behavior/persistencia, ETag de interfaz y proyección, DCL faltante, redirect
de composición, exposición accidental de auxiliares y guardas de cierre/locks.
No son pruebas de ejecución de handlers, DCL ni EML en un runtime SAP.

abaplint comprueba gramática ABAP/CDS/BDEF y estructuras BDEF/CDS. Su verificación
semántica CDS excluye solo YI_DM_SEG por una limitación conocida al reconocer las
composiciones: su gramática y sus relaciones se verifican de todos modos. No se
habilita el check_syntax ABAP completo sin las clases estándar de RAP de SAP.
No se declara ninguna fuente compilada ni activada en el Trial.

Se incluyen cinco métodos ABAP Unit para ejecutar en ADT, no ejecutados localmente.
La CI usa la misma versión fija del parser y verifica además que el generador no
deje cambios sobre las fuentes versionadas. Handlers y reglas son código manual.

## Inventario y decisiones

La base de esta rama es el commit 83a47aa, que corrigió el diagnóstico de FK sin
elementos de datos y FIELDNAME restringido. El historial de las 54 bajas del modelo
antiguo y el respaldo 2d493ef se conserva en [LIMPIEZA.md](LIMPIEZA.md).

Los nuevos objetos RAP se enumeran por función en
[RAP_DINAMICO.md](RAP_DINAMICO.md). Las ampliaciones de tabla se justifican allí y
se reflejan en DER, diccionario y contrato JSON; no hay una ampliación implícita
que quede fuera de esos artefactos.

## Pendiente en SAP

1. Preparar los datos de prueba antes de activar el índice natural de SEG.
2. Importar/activar objetos en conjunto y revisar disponibilidad de APIs/tipos del
   Trial; ejecutar ATC y ABAP Unit. La gramática local no reemplaza esta comprobación.
3. Probar autorización DCL/handlers con creador, dos responsables y usuario ajeno.
4. Probar deep create, unicidad, If-Match, locks, save/rollback y cierre concurrente
   con dos sesiones, según [test-plan.md](../test-plan.md).
5. Crear binding OData V4 Web API y acceso IAM solo tras validar; UI freestyle,
   segregación IAM de Calidad e integración con S/4 externo son fases posteriores.

No se conectó SAP ni se modificaron datos físicos. El estado LISTA_INTEG no afirma
activación ni encolado de materiales. Consultar la guía de importación antes del Pull.

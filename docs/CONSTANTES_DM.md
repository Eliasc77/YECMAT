# Constantes del contrato DM

Base revisada: `main`, commit `fc30682ddf3609fbb02fcb107236b0332d01321d`.

## Objeto nuevo

`YIF_DM_CONSTANTS` es una interfaz global ABAP, sin implementacion ni persistencia.
Se consume directamente; no es necesario declarar INTERFACES en cada clase:

```abap
IF row-Estado = yif_dm_constants=>c_estado_solicitud-borrador.
  " ...
ENDIF.

SELECT SINGLE flujo_id
  FROM ymmt_dm_flujo_vr
  WHERE estado = @yif_dm_constants=>c_estado_version-publicada
  INTO @DATA(flow_id).
```

Los tipos CHAR y longitudes explicitas conservan los valores del contrato sin
introducir dependencias de activacion con las tablas. Las constantes se agrupan
por significado, aunque dos dominios compartan un literal:

| Grupo | Contenido |
|---|---|
| c_estado_solicitud | BORRADOR, EN_CURSO, REVISION, LISTA_INTEG de solicitudes |
| c_estado_tarea | PENDIENTE, EN_CURSO, FINALIZADA de tareas |
| c_estado_version | BORRADOR, PUBLICADA, RETIRADA de versiones |
| c_clasificacion_bpm | A con revision y B directo |
| c_operacion_material | C/M/I y conjuntos de operaciones admitidas |
| c_estado_campo | M/O/I/R y conjunto de estados de campo |
| c_tipo_segmento | GENERAL, CENTRO, ALMACEN, VENTAS, VALORACION, UNIDAD |
| c_operacion_config | CREAR, GUARDAR, COPIAR, PUBLICAR, RETIRAR |
| c_entidad_config | Nombres publicos de los seis mantenimientos OData |
| c_tipo_dato | Tipos de datos admitidos por captura |
| c_control_pantalla | Input, TextArea, DatePicker, CheckBox, Decimal, Integer |
| c_configuracion | Identificador GLOBAL del control de configuracion |
| c_estado_contexto | Estado ACTIVO de un segmento |
| c_fase | Fase CAPTURA usada por los datos demo |
| c_validacion | Digitos, patrones de formato, separadores y fecha maxima |

Se mantienen `abap_true` y `abap_false` como constantes estandar. El refactor no
cambia estados, reglas, transiciones, validaciones ni valores persistidos.

## Que permanece literal

- Datos del perfil demo y de fixtures: nombres de flujo, material ZFER, areas
  PCP/LOG/CONT, identificadores de campo, secciones y mapeos SAP. Son registros
  configurables o ejemplos, no un catalogo global de areas o campos permitidos.
- Textos de mensajes y etiquetas. Su traduccion seria otra tarea.
- Nombres tecnicos de tablas y propiedades ABAP: no son valores de dominio.
- Numeros de orden, precision, rangos numericos y contadores: no se cambian en
  esta sustitucion de codigos del contrato.
- Valores esperados de las aserciones de pruebas, deliberadamente independientes
  de las constantes que usa el codigo productivo.
- Anotaciones CDS, DCL, dominios y JavaScript: el alcance son las clases ABAP.
  No todos esos lenguajes pueden consumir una interfaz ABAP. Sus contratos
  permanecen iguales, por lo que las apps actuales siguen enviando lo mismo.

## Pull y activacion en ADT

Importar primero `YIF_DM_CONSTANTS` y activarla. Luego activar las clases cambiadas
junto con sus includes y pruebas. No se crean ni modifican tablas, CDS, behaviors
ni Service Bindings por este refactor.

Clases modificadas (10 objetos, 11 fuentes):

- YBP_I_DM_CFG (implementacion local)
- YBP_I_DM_DATO (implementacion local)
- YBP_I_DM_SEG (implementacion local)
- YBP_I_DM_SOL (implementacion local)
- YBP_I_DM_TAREA (implementacion local)
- YCL_DM_CFG_MODEL (codigo y Test Classes)
- YCL_DM_CFG_SETUP
- YCL_DM_CREAR_SOL_DEMO
- YCL_DM_DEMO_CONFIG
- YCL_DM_RULES

La lista anterior contiene 10 objetos de clase: son 11 fuentes modificadas
porque YCL_DM_CFG_MODEL incluye tambien Test Classes.

## Verificacion

`python tools/check_dm_constants.py` comprueba referencias y longitudes y expande
las constantes para comparar los tokens de las 18 fuentes Y* contra la base main.
Tambien verifica que las siete fuentes Z* permanezcan identicas a main, sin
dependencias de la interfaz nueva.
Esto detecta cambios accidentales de logica, mensajes o datos durante el refactor.
Los hashes son una fotografia de esta migracion, no pruebas funcionales futuras.

`npm exec --yes --package=@abaplint/cli@2.120.92 -- abaplint abaplint.json`
analiza la gramatica de los objetos Y* y excluye el modelo Z*.
La activacion y ABAP Unit requieren SAP/ADT; no se han ejecutado contra el Trial
desde este entorno.

## Alcance final

70 constantes y 284 referencias sustituidas en 10 clases Y* (11 fuentes al
contar Test Classes). Los objetos Z* existentes en main se conservan intactos:
no se eliminan, renombran ni migran. La interfaz no incluye estados, semaforos
o eventos exclusivos de ese modelo anterior. No requiere importar objetos Z*.

## Nombres legibles

Los grupos y componentes del negocio usan nombres en espanol sin tildes.
Por ejemplo, `c_estado_solicitud-borrador` y
`c_control_pantalla-texto_multilinea`. Los tipos tecnicos CHAR/UNIT/QUAN,
los valores persistidos y los nombres de controles SAPUI5 permanecen intactos.
La interfaz conserva su nombre YIF_DM_CONSTANTS para evitar renombrar el objeto.

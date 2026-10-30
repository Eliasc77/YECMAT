# Diccionario de datos DM

La entidad fuente `YMMT_DM_FLUJO_VER` se implementa como `YMMT_DM_FLUJO_VR`
por el límite de 16 caracteres del nombre de tabla Dictionary clásica.

Las 15 tablas son transparentes y dependientes del mandante. `MANDT` es siempre el primer componente de la PK y de cada FK e índice.
Los campos funcionales y claves se conservan del DER fuente. Los tipos DDIC estándar se resuelven en el sistema destino, sin fijar longitudes que contradigan sus elementos de datos.

## Tipos SAP usados

| Elemento | Representación esperada en S/4HANA On-Premise |
|---|---|
| MANDT | CLNT(3) |
| SYSUUID_X16 | RAW(16), UUID binario |
| MATNR | CHAR según sistema, normalmente 40 en S/4HANA; verificar extensión de material |
| MTART / WERKS_D / LGORT_D / VKORG / BWKEY | CHAR(4) |
| VTWEG | CHAR(2) |
| BWTAR_D | CHAR(10); inicial permitido sin valoración separada |
| MEINS | UNIT(3), clave interna SAP; conversión CUNIT en frontera de servicio |
| SYUNAME | CHAR(12), usuario ABAP |
| TIMESTAMPL | DEC(21,7), instante UTC largo |
| ABP_LOCINST_LASTCHANGE_TSTMPL | Timestamp largo mantenido por RAP para ETag local |
| ABAP_BOOLEAN | CHAR(1), X / espacio; sustituye BOOLE_D obsoleto |

Los CHAR(n) son tipos Dictionary integrados, longitud en caracteres; INT4 tiene 4 bytes y longitud de salida 10. DATS usa 8 caracteres.
`NOTNULL` evita NULL SQL; no rechaza valores iniciales ABAP. UUID no inicial, referencias y valores obligatorios necesitan validaciones de aplicación.
`VALOR` tiene máximo 1333 caracteres, límite deliberado de CHAR DDIC; no se truncan entradas. Textos largos o binarios requieren una extensión posterior del modelo.
Configuración: clase de entrega C / APPL2. Transacciones: A / APPL0. Sin buffering ni dependencia de idioma. Idioma original E en metadata; textos de descripción en español.

## Dominios y elementos de datos propios

Los componentes de las FK usan elementos de datos, basados en el mismo dominio
en padre e hijo. No se definen FK directamente sobre CHAR/INT4 integrados.
Los seis pares se importan antes de activar las tablas.

| Elemento | Dominio | Tipo base | Uso |
|---|---|---|---|
| `YMME_DM_FLUJO_ID` | `YMMD_DM_FLUJO_ID` | `CHAR(20)` | Flujo |
| `YMME_DM_VERSION` | `YMMD_DM_VERSION` | `INT4(10)` | Version |
| `YMME_DM_PASO_ID` | `YMMD_DM_PASO_ID` | `CHAR(20)` | Paso |
| `YMME_DM_CAMPO_ID` | `YMMD_DM_CAMPO_ID` | `CHAR(30)` | Campo |
| `YMME_DM_SECCION` | `YMMD_DM_SECCION` | `CHAR(20)` | Seccion |
| `YMME_DM_NOMBRE` | `YMMD_DM_NOMBRE` | `CHAR(30)` | Nombre tecnico SAP |

`YMME_DM_NOMBRE` se usa en TABLA_SAP y CAMPO_SAP: sustituye las referencias
a TABNAME/FIELDNAME por CHAR(30) propio. ADT rechazó FIELDNAME en el sistema
destino; no se cambia la longitud ni se añade información funcional.

## YMMT_DM_FLUJO

DM - Definicion de flujo. Clase de entrega `C`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK |
| `FLUJO_ID` | `YMME_DM_FLUJO_ID` | PK |
| `DESCRIPCION` | `CHAR80` | — |
| `TIPO_MATERIAL` | `MTART` | — |
| `TIPO_OPERACION` | `CHAR1` | — |
| `CENTRO_CRITERIO` | `WERKS_D` | — |
| `ACTIVO` | `ABAP_BOOLEAN` | — |


## YMMT_DM_FLUJO_VR

DM - Version de flujo. Clase de entrega `C`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_FLUJO` |
| `FLUJO_ID` | `YMME_DM_FLUJO_ID` | PK, FK → `YMMT_DM_FLUJO` |
| `VERSION` | `YMME_DM_VERSION` | PK |
| `ESTADO` | `CHAR12` | — |
| `VIGENTE_DESDE` | `DATS` | — |
| `VIGENTE_HASTA` | `DATS` | — |
| `CREADO_POR` | `SYUNAME` | — |
| `CREADO_EL` | `TIMESTAMPL` | — |


## YMMT_DM_PASO

DM - Paso de flujo versionado. Clase de entrega `C`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_FLUJO_VR` |
| `FLUJO_ID` | `YMME_DM_FLUJO_ID` | PK, FK → `YMMT_DM_FLUJO_VR` |
| `VERSION` | `YMME_DM_VERSION` | PK, FK → `YMMT_DM_FLUJO_VR` |
| `PASO_ID` | `YMME_DM_PASO_ID` | PK |
| `AREA` | `CHAR10` | — |
| `FASE` | `CHAR20` | — |
| `CONDICION_BPM` | `CHAR1` | — |
| `ORDEN` | `INT4` | — |
| `OBLIGATORIO` | `ABAP_BOOLEAN` | — |
| `ACTIVO` | `ABAP_BOOLEAN` | — |


## YMMT_DM_SOL

DM - Solicitud de material. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_FLUJO_VR` |
| `SOLICITUD_UUID` | `SYSUUID_X16` | PK |
| `NUMERO_SOLICITUD` | `CHAR20` | UK |
| `TIPO_MATERIAL` | `MTART` | — |
| `TIPO_OPERACION` | `CHAR1` | — |
| `MATERIAL` | `MATNR` | — |
| `FLUJO_ID` | `YMME_DM_FLUJO_ID` | FK → `YMMT_DM_FLUJO_VR` |
| `VERSION` | `YMME_DM_VERSION` | FK → `YMMT_DM_FLUJO_VR` |
| `ESTADO` | `CHAR12` | — |
| `CREADO_POR` | `SYUNAME` | — |
| `CREADO_EL` | `TIMESTAMPL` | — |
| `CLASIFICACION_BPM` | `CHAR1` | — |
| `LAST_CHANGED_AT` | `ABP_LOCINST_LASTCHANGE_TSTMPL` | — |

- Índice `Z01` único: `MANDT, NUMERO_SOLICITUD`.
- Índice `Z02` no único: `MANDT, FLUJO_ID, VERSION`.

## YMMT_DM_TAREA

DM - Instancia de paso. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SOL`, `YMMT_DM_PASO` |
| `TAREA_UUID` | `SYSUUID_X16` | PK |
| `SOLICITUD_UUID` | `SYSUUID_X16` | FK → `YMMT_DM_SOL` |
| `FLUJO_ID` | `YMME_DM_FLUJO_ID` | FK → `YMMT_DM_PASO` |
| `VERSION` | `YMME_DM_VERSION` | FK → `YMMT_DM_PASO` |
| `PASO_ID` | `YMME_DM_PASO_ID` | FK → `YMMT_DM_PASO` |
| `AREA` | `CHAR10` | — |
| `ESTADO` | `CHAR12` | — |
| `RESPONSABLE` | `SYUNAME` | — |
| `CREADO_EL` | `TIMESTAMPL` | — |
| `LAST_CHANGED_AT` | `ABP_LOCINST_LASTCHANGE_TSTMPL` | — |

- Índice `Z01` único: `MANDT, SOLICITUD_UUID, FLUJO_ID, VERSION, PASO_ID`.

## YMMT_DM_SEG

DM - Contexto de datos de solicitud. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SOL` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK |
| `SOLICITUD_UUID` | `SYSUUID_X16` | FK → `YMMT_DM_SOL` |
| `TIPO_SEGMENTO` | `CHAR10` | — |
| `ESTADO` | `CHAR12` | — |
| `CONTEXTO_CLAVE` | `CHAR100` | — |
| `LAST_CHANGED_AT` | `ABP_LOCINST_LASTCHANGE_TSTMPL` | — |

- Índice `Z01` no único: `MANDT, SOLICITUD_UUID, TIPO_SEGMENTO`.
- Índice `Z02` único: `MANDT, SOLICITUD_UUID, TIPO_SEGMENTO, CONTEXTO_CLAVE`.

## YMMT_DM_SEG_CEN

DM - Segmento Centro. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SEG` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK, FK → `YMMT_DM_SEG` |
| `CENTRO` | `WERKS_D` | — |


## YMMT_DM_SEG_ALM

DM - Segmento Almacen. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SEG` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK, FK → `YMMT_DM_SEG` |
| `CENTRO` | `WERKS_D` | — |
| `ALMACEN` | `LGORT_D` | — |


## YMMT_DM_SEG_VEN

DM - Segmento Ventas. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SEG` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK, FK → `YMMT_DM_SEG` |
| `ORG_VENTAS` | `VKORG` | — |
| `CANAL` | `VTWEG` | — |


## YMMT_DM_SEG_VAL

DM - Segmento Valoracion. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SEG` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK, FK → `YMMT_DM_SEG` |
| `AREA_VALORACION` | `BWKEY` | — |
| `TIPO_VALORACION` | `BWTAR_D` | — |


## YMMT_DM_SEG_UOM

DM - Segmento Unidad alternativa. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SEG` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK, FK → `YMMT_DM_SEG` |
| `UNIDAD_ALTERNATIVA` | `MEINS` | — |


## YMMT_DM_CAMPO

DM - Catalogo de campos. Clase de entrega `C`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK |
| `CAMPO_ID` | `YMME_DM_CAMPO_ID` | PK |
| `DESCRIPCION` | `CHAR80` | — |
| `TABLA_SAP` | `YMME_DM_NOMBRE` | — |
| `CAMPO_SAP` | `YMME_DM_NOMBRE` | — |
| `TIPO_SEGMENTO` | `CHAR10` | — |
| `TIPO_DATO` | `CHAR10` | — |
| `LONGITUD` | `INT4` | — |
| `DECIMALES` | `INT4` | — |
| `AYUDA_VALORES` | `CHAR30` | — |
| `TIPO_CONTROL` | `CHAR20` | — |
| `ACTIVO` | `ABAP_BOOLEAN` | — |


## YMMT_DM_SECCION

DM - Seccion de formulario. Clase de entrega `C`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK |
| `SECCION_ID` | `YMME_DM_SECCION` | PK |
| `DESCRIPCION` | `CHAR80` | — |
| `ORDEN` | `INT4` | — |
| `ACTIVO` | `ABAP_BOOLEAN` | — |


## YMMT_DM_REGLA

DM - Regla de campo versionada. Clase de entrega `C`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_FLUJO_VR`, `YMMT_DM_CAMPO`, `YMMT_DM_SECCION` |
| `REGLA_UUID` | `SYSUUID_X16` | PK |
| `FLUJO_ID` | `YMME_DM_FLUJO_ID` | FK → `YMMT_DM_FLUJO_VR` |
| `VERSION` | `YMME_DM_VERSION` | FK → `YMMT_DM_FLUJO_VR` |
| `AREA` | `CHAR10` | — |
| `CAMPO_ID` | `YMME_DM_CAMPO_ID` | FK → `YMMT_DM_CAMPO` |
| `SECCION_ID` | `YMME_DM_SECCION` | FK → `YMMT_DM_SECCION` |
| `ESTADO_CAMPO` | `CHAR1` | — |
| `ORDEN` | `INT4` | — |
| `ACTIVO` | `ABAP_BOOLEAN` | — |

- Índice `Z01` único: `MANDT, FLUJO_ID, VERSION, AREA, CAMPO_ID`.

## YMMT_DM_DATO

DM - Valor por campo y contexto. Clase de entrega `A`.

| Campo | Tipo DDIC | Clave / referencia |
|---|---|---|
| `MANDT` | `MANDT` | PK, FK → `YMMT_DM_SEG`, `YMMT_DM_CAMPO` |
| `SEGMENTO_UUID` | `SYSUUID_X16` | PK, FK → `YMMT_DM_SEG` |
| `CAMPO_ID` | `YMME_DM_CAMPO_ID` | PK, FK → `YMMT_DM_CAMPO` |
| `VALOR` | `CHAR1333` | — |
| `MODIFICADO_POR` | `SYUNAME` | — |
| `MODIFICADO_EL` | `ABP_LOCINST_LASTCHANGE_TSTMPL` | — |

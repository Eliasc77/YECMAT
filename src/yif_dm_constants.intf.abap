"_ Constantes compartidas del modelo DM. No guardan datos ni ejecutan acciones.
INTERFACE yif_dm_constants PUBLIC.
  "_ Estados de la solicitud durante captura, revision e integracion.
  CONSTANTS: BEGIN OF c_estado_solicitud,
               borrador TYPE c LENGTH 8 VALUE 'BORRADOR',
               en_curso TYPE c LENGTH 8 VALUE 'EN_CURSO',
               revision TYPE c LENGTH 8 VALUE 'REVISION',
               "_ Datos listos para integrar; no significa que el material ya este creado.
               lista_integracion TYPE c LENGTH 11 VALUE 'LISTA_INTEG',
             END OF c_estado_solicitud.

  "_ Estados del trabajo que realiza cada area.
  CONSTANTS: BEGIN OF c_estado_tarea,
               pendiente TYPE c LENGTH 9 VALUE 'PENDIENTE',
               en_curso TYPE c LENGTH 8 VALUE 'EN_CURSO',
               finalizada TYPE c LENGTH 10 VALUE 'FINALIZADA',
             END OF c_estado_tarea.

  "_ Estados de una version de configuracion del flujo.
  CONSTANTS: BEGIN OF c_estado_version,
               borrador TYPE c LENGTH 8 VALUE 'BORRADOR',
               publicada TYPE c LENGTH 9 VALUE 'PUBLICADA',
               retirada TYPE c LENGTH 8 VALUE 'RETIRADA',
             END OF c_estado_version.

  "_ A requiere aprobacion; B pasa directo a integracion al cerrar captura.
  CONSTANTS: BEGIN OF c_clasificacion_bpm,
               con_revision TYPE c LENGTH 1 VALUE 'A',
               sin_revision TYPE c LENGTH 1 VALUE 'B',
             END OF c_clasificacion_bpm.

  "_ Codigos para crear, modificar o inactivar un material.
  CONSTANTS: BEGIN OF c_operacion_material,
               crear TYPE c LENGTH 1 VALUE 'C',
               modificar TYPE c LENGTH 1 VALUE 'M',
               inactivar TYPE c LENGTH 1 VALUE 'I',
               "_ Conjunto C/M/I utilizado al validar la operacion.
               permitidas TYPE c LENGTH 3 VALUE 'CMI',
               "_ Modificar e inactivar requieren un material existente.
               requieren_material TYPE c LENGTH 2 VALUE 'MI',
             END OF c_operacion_material.

  "_ Define si el campo es obligatorio, opcional, oculto o de consulta.
  CONSTANTS: BEGIN OF c_estado_campo,
               obligatorio TYPE c LENGTH 1 VALUE 'M',
               opcional TYPE c LENGTH 1 VALUE 'O',
               oculto TYPE c LENGTH 1 VALUE 'I',
               solo_lectura TYPE c LENGTH 1 VALUE 'R',
               "_ Conjunto I/O/M/R utilizado al validar el estado del campo.
               permitidos TYPE c LENGTH 4 VALUE 'IOMR',
             END OF c_estado_campo.

  "_ Identifica el contexto organizativo al que pertenece el dato.
  CONSTANTS: BEGIN OF c_tipo_segmento,
               general TYPE c LENGTH 7 VALUE 'GENERAL',
               centro TYPE c LENGTH 6 VALUE 'CENTRO',
               almacen TYPE c LENGTH 7 VALUE 'ALMACEN',
               ventas TYPE c LENGTH 6 VALUE 'VENTAS',
               valoracion TYPE c LENGTH 10 VALUE 'VALORACION',
               unidad_medida TYPE c LENGTH 6 VALUE 'UNIDAD',
             END OF c_tipo_segmento.

  "_ Operaciones que recibe la accion administrativa Aplicar.
  CONSTANTS: BEGIN OF c_operacion_config,
               crear TYPE c LENGTH 5 VALUE 'CREAR',
               guardar TYPE c LENGTH 7 VALUE 'GUARDAR',
               copiar TYPE c LENGTH 6 VALUE 'COPIAR',
               publicar TYPE c LENGTH 8 VALUE 'PUBLICAR',
               retirar TYPE c LENGTH 7 VALUE 'RETIRAR',
             END OF c_operacion_config.

  "_ Nombres de los mantenimientos que recibe Aplicar en EntitySet.
  CONSTANTS: BEGIN OF c_entidad_config,
               campos TYPE c LENGTH 6 VALUE 'Campos',
               secciones TYPE c LENGTH 9 VALUE 'Secciones',
               flujos TYPE c LENGTH 6 VALUE 'Flujos',
               versiones TYPE c LENGTH 9 VALUE 'Versiones',
               pasos TYPE c LENGTH 5 VALUE 'Pasos',
               reglas TYPE c LENGTH 6 VALUE 'Reglas',
             END OF c_entidad_config.

  "_ Tipos tecnicos usados para validar el formato del valor capturado.
  CONSTANTS: BEGIN OF c_tipo_dato,
               char TYPE c LENGTH 4 VALUE 'CHAR',
               string TYPE c LENGTH 6 VALUE 'STRING',
               "_ Clave de digitos que conserva los ceros iniciales.
               numc TYPE c LENGTH 4 VALUE 'NUMC',
               dec TYPE c LENGTH 3 VALUE 'DEC',
               curr TYPE c LENGTH 4 VALUE 'CURR',
               "_ Codigo tecnico SAP para una cantidad.
               quan TYPE c LENGTH 4 VALUE 'QUAN',
               int1 TYPE c LENGTH 4 VALUE 'INT1',
               int2 TYPE c LENGTH 4 VALUE 'INT2',
               int4 TYPE c LENGTH 4 VALUE 'INT4',
               dats TYPE c LENGTH 4 VALUE 'DATS',
               bool TYPE c LENGTH 4 VALUE 'BOOL',
               "_ Codigo tecnico SAP para una unidad de medida.
               unit TYPE c LENGTH 4 VALUE 'UNIT',
               "_ Codigo tecnico SAP para una moneda.
               cuky TYPE c LENGTH 4 VALUE 'CUKY',
               lang TYPE c LENGTH 4 VALUE 'LANG',
             END OF c_tipo_dato.

  "_ Identifica el control de pantalla configurado para el campo.
  CONSTANTS: BEGIN OF c_control_pantalla,
               entrada TYPE c LENGTH 5 VALUE 'Input',
               texto_multilinea TYPE c LENGTH 8 VALUE 'TextArea',
               selector_fecha TYPE c LENGTH 10 VALUE 'DatePicker',
               casilla TYPE c LENGTH 8 VALUE 'CheckBox',
               decimal TYPE c LENGTH 7 VALUE 'Decimal',
               entero TYPE c LENGTH 7 VALUE 'Integer',
             END OF c_control_pantalla.

  "_ Identifica el registro unico que controla la revision de configuracion.
  CONSTANTS: BEGIN OF c_configuracion,
               id_global TYPE c LENGTH 6 VALUE 'GLOBAL',
             END OF c_configuracion.

  "_ Marca el contexto organizativo como activo.
  CONSTANTS: BEGIN OF c_estado_contexto,
               activo TYPE c LENGTH 6 VALUE 'ACTIVO',
             END OF c_estado_contexto.

  "_ Identifica los pasos que corresponden a la captura de datos.
  CONSTANTS: BEGIN OF c_fase,
               captura TYPE c LENGTH 7 VALUE 'CAPTURA',
             END OF c_fase.

  "_ Valores auxiliares para comprobar formatos y fechas.
  CONSTANTS: BEGIN OF c_validacion,
               digitos TYPE c LENGTH 10 VALUE '0123456789',
               patron_identificador TYPE c LENGTH 13 VALUE '^[A-Z0-9\_]+$',
               patron_entero TYPE c LENGTH 10 VALUE '^-?[0-9]+$',
               patron_decimal TYPE c LENGTH 21 VALUE '^-?[0-9]+(\.[0-9]+)?$',
               "_ Limite superior usado cuando no se informa fin de vigencia.
               fecha_maxima TYPE c LENGTH 8 VALUE '99991231',
               "_ Permite detectar fechas con un anio invalido igual a cero.
               anio_cero TYPE c LENGTH 4 VALUE '0000',
               signo_menos TYPE c LENGTH 1 VALUE '-',
               punto_decimal TYPE c LENGTH 1 VALUE '.',
             END OF c_validacion.

ENDINTERFACE.

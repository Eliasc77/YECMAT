" Valores del contrato DM; no son configuracion de negocio ni textos de usuario.
INTERFACE yif_dm_constants PUBLIC.
  CONSTANTS: BEGIN OF c_req,
               draft TYPE c LENGTH 8 VALUE 'BORRADOR',
               in_progress TYPE c LENGTH 8 VALUE 'EN_CURSO',
               review TYPE c LENGTH 8 VALUE 'REVISION',
               ready TYPE c LENGTH 11 VALUE 'LISTA_INTEG',
             END OF c_req.

  CONSTANTS: BEGIN OF c_task,
               pending TYPE c LENGTH 9 VALUE 'PENDIENTE',
               in_progress TYPE c LENGTH 8 VALUE 'EN_CURSO',
               finished TYPE c LENGTH 10 VALUE 'FINALIZADA',
             END OF c_task.

  CONSTANTS: BEGIN OF c_ver,
               draft TYPE c LENGTH 8 VALUE 'BORRADOR',
               published TYPE c LENGTH 9 VALUE 'PUBLICADA',
               retired TYPE c LENGTH 8 VALUE 'RETIRADA',
             END OF c_ver.

  CONSTANTS: BEGIN OF c_bpm,
               review TYPE c LENGTH 1 VALUE 'A',
               direct TYPE c LENGTH 1 VALUE 'B',
             END OF c_bpm.

  CONSTANTS: BEGIN OF c_op,
               create TYPE c LENGTH 1 VALUE 'C',
               change TYPE c LENGTH 1 VALUE 'M',
               inactivate TYPE c LENGTH 1 VALUE 'I',
               allowed TYPE c LENGTH 3 VALUE 'CMI',
               needs_material TYPE c LENGTH 2 VALUE 'MI',
             END OF c_op.

  CONSTANTS: BEGIN OF c_rule,
               required TYPE c LENGTH 1 VALUE 'M',
               optional TYPE c LENGTH 1 VALUE 'O',
               hidden TYPE c LENGTH 1 VALUE 'I',
               readonly TYPE c LENGTH 1 VALUE 'R',
               allowed TYPE c LENGTH 4 VALUE 'IOMR',
             END OF c_rule.

  CONSTANTS: BEGIN OF c_seg,
               general TYPE c LENGTH 7 VALUE 'GENERAL',
               plant TYPE c LENGTH 6 VALUE 'CENTRO',
               storage TYPE c LENGTH 7 VALUE 'ALMACEN',
               sales TYPE c LENGTH 6 VALUE 'VENTAS',
               valuation TYPE c LENGTH 10 VALUE 'VALORACION',
               unit TYPE c LENGTH 6 VALUE 'UNIDAD',
             END OF c_seg.

  CONSTANTS: BEGIN OF c_cmd,
               create TYPE c LENGTH 5 VALUE 'CREAR',
               save TYPE c LENGTH 7 VALUE 'GUARDAR',
               copy TYPE c LENGTH 6 VALUE 'COPIAR',
               publish TYPE c LENGTH 8 VALUE 'PUBLICAR',
               retire TYPE c LENGTH 7 VALUE 'RETIRAR',
             END OF c_cmd.

  CONSTANTS: BEGIN OF c_set,
               fields TYPE c LENGTH 6 VALUE 'Campos',
               sections TYPE c LENGTH 9 VALUE 'Secciones',
               flows TYPE c LENGTH 6 VALUE 'Flujos',
               versions TYPE c LENGTH 9 VALUE 'Versiones',
               steps TYPE c LENGTH 5 VALUE 'Pasos',
               rules TYPE c LENGTH 6 VALUE 'Reglas',
             END OF c_set.

  CONSTANTS: BEGIN OF c_type,
               char TYPE c LENGTH 4 VALUE 'CHAR',
               string TYPE c LENGTH 6 VALUE 'STRING',
               numc TYPE c LENGTH 4 VALUE 'NUMC',
               dec TYPE c LENGTH 3 VALUE 'DEC',
               curr TYPE c LENGTH 4 VALUE 'CURR',
               quan TYPE c LENGTH 4 VALUE 'QUAN',
               int1 TYPE c LENGTH 4 VALUE 'INT1',
               int2 TYPE c LENGTH 4 VALUE 'INT2',
               int4 TYPE c LENGTH 4 VALUE 'INT4',
               dats TYPE c LENGTH 4 VALUE 'DATS',
               bool TYPE c LENGTH 4 VALUE 'BOOL',
               unit TYPE c LENGTH 4 VALUE 'UNIT',
               cuky TYPE c LENGTH 4 VALUE 'CUKY',
               lang TYPE c LENGTH 4 VALUE 'LANG',
             END OF c_type.

  CONSTANTS: BEGIN OF c_ui,
               input TYPE c LENGTH 5 VALUE 'Input',
               multiline TYPE c LENGTH 8 VALUE 'TextArea',
               date TYPE c LENGTH 10 VALUE 'DatePicker',
               checkbox TYPE c LENGTH 8 VALUE 'CheckBox',
               decimal TYPE c LENGTH 7 VALUE 'Decimal',
               integer TYPE c LENGTH 7 VALUE 'Integer',
             END OF c_ui.

  CONSTANTS: BEGIN OF c_cfg,
               global_id TYPE c LENGTH 6 VALUE 'GLOBAL',
             END OF c_cfg.

  CONSTANTS: BEGIN OF c_context,
               active TYPE c LENGTH 6 VALUE 'ACTIVO',
             END OF c_context.

  CONSTANTS: BEGIN OF c_phase,
               capture TYPE c LENGTH 7 VALUE 'CAPTURA',
             END OF c_phase.

  CONSTANTS: BEGIN OF c_valid,
               digits TYPE c LENGTH 10 VALUE '0123456789',
               identifier_regex TYPE c LENGTH 13 VALUE '^[A-Z0-9\_]+$',
               integer_regex TYPE c LENGTH 10 VALUE '^-?[0-9]+$',
               decimal_regex TYPE c LENGTH 21 VALUE '^-?[0-9]+(\.[0-9]+)?$',
               date_max TYPE c LENGTH 8 VALUE '99991231',
               date_zero_year TYPE c LENGTH 4 VALUE '0000',
               minus TYPE c LENGTH 1 VALUE '-',
               decimal_point TYPE c LENGTH 1 VALUE '.',
             END OF c_valid.

ENDINTERFACE.

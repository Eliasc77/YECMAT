CLASS ycl_dm_demo_config DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CONSTANTS flujo_id TYPE ymme_dm_flujo_id VALUE 'DM_DEMO_ZFER'.
    CONSTANTS version_id TYPE ymme_dm_version VALUE 1.
    TYPES tt_flujos TYPE STANDARD TABLE OF ymmt_dm_flujo WITH EMPTY KEY.
    TYPES tt_versiones TYPE STANDARD TABLE OF ymmt_dm_flujo_vr WITH EMPTY KEY.
    TYPES tt_pasos TYPE STANDARD TABLE OF ymmt_dm_paso WITH EMPTY KEY.
    TYPES tt_campos TYPE STANDARD TABLE OF ymmt_dm_campo WITH EMPTY KEY.
    TYPES tt_secciones TYPE STANDARD TABLE OF ymmt_dm_seccion WITH EMPTY KEY.
    TYPES tt_reglas TYPE STANDARD TABLE OF ymmt_dm_regla WITH EMPTY KEY.
    TYPES: BEGIN OF ty_config,
             flujos TYPE tt_flujos,
             versiones TYPE tt_versiones,
             pasos TYPE tt_pasos,
             campos TYPE tt_campos,
             secciones TYPE tt_secciones,
             reglas TYPE tt_reglas,
           END OF ty_config.
    CLASS-METHODS build RETURNING VALUE(result) TYPE ty_config.
    CLASS-METHODS plan IMPORTING desired TYPE ty_config existing TYPE ty_config
      EXPORTING additions TYPE ty_config error TYPE string.
  PRIVATE SECTION.
    CLASS-METHODS validate IMPORTING config TYPE ty_config RETURNING VALUE(error) TYPE string.
ENDCLASS.

CLASS ycl_dm_demo_config IMPLEMENTATION.
  METHOD build.
    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.
    result-flujos = VALUE #( ( mandt = sy-mandt flujo_id = flujo_id
      descripcion = 'DEMO Trial - Creacion ZFER' tipo_material = 'ZFER'
      tipo_operacion = yif_dm_constants=>c_op-create activo = abap_true ) ).
    result-versiones = VALUE #( ( mandt = sy-mandt flujo_id = flujo_id version = version_id
      estado = yif_dm_constants=>c_ver-published vigente_desde = '20200101' vigente_hasta =
        yif_dm_constants=>c_valid-date_max
      creado_por = cl_abap_context_info=>get_user_technical_name( ) creado_el = now ) ).
    result-pasos = VALUE #(
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id paso_id = 'PCP_CAPTURA'
        area = 'PCP' fase = yif_dm_constants=>c_phase-capture orden = 10 obligatorio = abap_true activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id paso_id = 'LOG_CAPTURA'
        area = 'LOG' fase = yif_dm_constants=>c_phase-capture orden = 20 obligatorio = abap_true activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id paso_id = 'CONT_CAPTURA'
        area = 'CONT' fase = yif_dm_constants=>c_phase-capture orden = 30 obligatorio = abap_true activo = abap_true )
    ).
    result-campos = VALUE #(
      ( mandt = sy-mandt
        campo_id = 'MAKT_MAKTX'
        descripcion = 'Descripcion breve'
        tabla_sap = 'MAKT'
        campo_sap = 'MAKTX'
        tipo_segmento = yif_dm_constants=>c_seg-general
        tipo_dato = yif_dm_constants=>c_type-char
        longitud = 40
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-input
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MARA_MEINS'
        descripcion = 'Unidad de medida base'
        tabla_sap = 'MARA'
        campo_sap = 'MEINS'
        tipo_segmento = yif_dm_constants=>c_seg-general
        tipo_dato = yif_dm_constants=>c_type-unit
        longitud = 3
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-input
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MARA_MATKL'
        descripcion = 'Grupo de articulos'
        tabla_sap = 'MARA'
        campo_sap = 'MATKL'
        tipo_segmento = yif_dm_constants=>c_seg-general
        tipo_dato = yif_dm_constants=>c_type-char
        longitud = 9
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-input
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MARC_EKGRP'
        descripcion = 'Grupo de compras'
        tabla_sap = 'MARC'
        campo_sap = 'EKGRP'
        tipo_segmento = yif_dm_constants=>c_seg-plant
        tipo_dato = yif_dm_constants=>c_type-char
        longitud = 3
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-input
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MARD_LGPBE'
        descripcion = 'Ubicacion en almacen'
        tabla_sap = 'MARD'
        campo_sap = 'LGPBE'
        tipo_segmento = yif_dm_constants=>c_seg-storage
        tipo_dato = yif_dm_constants=>c_type-char
        longitud = 10
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-input
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MVKE_MTPOS'
        descripcion = 'Grupo de tipos de posicion'
        tabla_sap = 'MVKE'
        campo_sap = 'MTPOS'
        tipo_segmento = yif_dm_constants=>c_seg-sales
        tipo_dato = yif_dm_constants=>c_type-char
        longitud = 4
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-input
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MBEW_STPRS'
        descripcion = 'Precio estandar'
        tabla_sap = 'MBEW'
        campo_sap = 'STPRS'
        tipo_segmento = yif_dm_constants=>c_seg-valuation
        tipo_dato = yif_dm_constants=>c_type-curr
        longitud = 11
        decimales = 2
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-decimal
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MARM_UMREZ'
        descripcion = 'Numerador de conversion'
        tabla_sap = 'MARM'
        campo_sap = 'UMREZ'
        tipo_segmento = yif_dm_constants=>c_seg-unit
        tipo_dato = yif_dm_constants=>c_type-dec
        longitud = 5
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-integer
        activo = abap_true )
      ( mandt = sy-mandt
        campo_id = 'MARM_UMREN'
        descripcion = 'Denominador de conversion'
        tabla_sap = 'MARM'
        campo_sap = 'UMREN'
        tipo_segmento = yif_dm_constants=>c_seg-unit
        tipo_dato = yif_dm_constants=>c_type-dec
        longitud = 5
        decimales = 0
        ayuda_valores = ''
        tipo_control = yif_dm_constants=>c_ui-integer
        activo = abap_true )
    ).
    result-secciones = VALUE #(
      ( mandt = sy-mandt
        seccion_id = 'BASICOS'
        descripcion = 'Datos basicos'
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt
        seccion_id = 'COMPRAS'
        descripcion = 'Compras por centro'
        orden = 20
        activo = abap_true )
      ( mandt = sy-mandt
        seccion_id = yif_dm_constants=>c_seg-storage
        descripcion = 'Datos de almacen'
        orden = 30
        activo = abap_true )
      ( mandt = sy-mandt
        seccion_id = yif_dm_constants=>c_seg-sales
        descripcion = 'Datos de ventas'
        orden = 40
        activo = abap_true )
      ( mandt = sy-mandt
        seccion_id = yif_dm_constants=>c_seg-valuation
        descripcion = 'Datos de valoracion'
        orden = 50
        activo = abap_true )
      ( mandt = sy-mandt
        seccion_id = 'UNIDADES'
        descripcion = 'Unidades alternativas'
        orden = 60
        activo = abap_true )
    ).
    result-reglas = VALUE #(
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'PCP'
        campo_id = 'MAKT_MAKTX'
        seccion_id = 'BASICOS'
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'PCP'
        campo_id = 'MARA_MEINS'
        seccion_id = 'BASICOS'
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 20
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'PCP'
        campo_id = 'MARA_MATKL'
        seccion_id = 'BASICOS'
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 30
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'LOG'
        campo_id = 'MARC_EKGRP'
        seccion_id = 'COMPRAS'
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'LOG'
        campo_id = 'MARD_LGPBE'
        seccion_id = yif_dm_constants=>c_seg-storage
        estado_campo = yif_dm_constants=>c_rule-optional
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'PCP'
        campo_id = 'MVKE_MTPOS'
        seccion_id = yif_dm_constants=>c_seg-sales
        estado_campo = yif_dm_constants=>c_rule-optional
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'CONT'
        campo_id = 'MBEW_STPRS'
        seccion_id = yif_dm_constants=>c_seg-valuation
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'PCP'
        campo_id = 'MARM_UMREZ'
        seccion_id = 'UNIDADES'
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 10
        activo = abap_true )
      ( mandt = sy-mandt flujo_id = flujo_id version = version_id
        area = 'PCP'
        campo_id = 'MARM_UMREN'
        seccion_id = 'UNIDADES'
        estado_campo = yif_dm_constants=>c_rule-required
        orden = 20
        activo = abap_true )
    ).
  ENDMETHOD.
  METHOD validate.
    IF lines( config-flujos ) <> 1 OR lines( config-versiones ) <> 1.
      error = 'El perfil requiere un flujo y una version'. RETURN.
    ENDIF.
    DATA(flow) = config-flujos[ 1 ].
    DATA(ver) = config-versiones[ 1 ].
    IF flow-flujo_id <> flujo_id OR ver-flujo_id <> flow-flujo_id OR ver-version <> version_id
      OR flow-activo <> abap_true OR ver-estado <> yif_dm_constants=>c_ver-published
      OR ver-vigente_desde IS INITIAL OR ver-vigente_hasta < ver-vigente_desde.
      error = 'Cabecera del perfil DEMO invalida'. RETURN.
    ENDIF.
    DATA field_ids TYPE SORTED TABLE OF ymme_dm_campo_id WITH UNIQUE KEY table_line.
    DATA section_ids TYPE SORTED TABLE OF ymme_dm_seccion WITH UNIQUE KEY table_line.
    DATA step_ids TYPE SORTED TABLE OF ymme_dm_paso_id WITH UNIQUE KEY table_line.
    LOOP AT config-campos INTO DATA(field).
      INSERT field-campo_id INTO TABLE field_ids.
      IF sy-subrc <> 0 OR field-campo_id IS INITIAL OR field-longitud <= 0
        OR field-longitud > 1333 OR field-decimales < 0 OR field-decimales > field-longitud.
        error = 'Campo duplicado o longitud/decimales invalidos'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT config-secciones INTO DATA(section).
      INSERT section-seccion_id INTO TABLE section_ids.
      IF sy-subrc <> 0 OR section-seccion_id IS INITIAL.
        error = 'Seccion duplicada o sin identificador'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT config-pasos INTO DATA(step).
      INSERT step-paso_id INTO TABLE step_ids.
      IF sy-subrc <> 0 OR step-flujo_id <> flow-flujo_id OR step-version <> ver-version
        OR step-area IS INITIAL OR step-activo <> abap_true.
        error = 'Paso duplicado o fuera de la version'. RETURN.
      ENDIF.
    ENDLOOP.
    TYPES: BEGIN OF ty_rule_key,
             area TYPE ymmt_dm_regla-area,
             campo_id TYPE ymme_dm_campo_id,
           END OF ty_rule_key.
    DATA rule_keys TYPE HASHED TABLE OF ty_rule_key WITH UNIQUE KEY area campo_id.
    LOOP AT config-reglas INTO DATA(rule).
      INSERT VALUE #( area = rule-area campo_id = rule-campo_id ) INTO TABLE rule_keys.
      IF sy-subrc <> 0 OR rule-flujo_id <> flow-flujo_id OR rule-version <> ver-version
        OR rule-estado_campo NA yif_dm_constants=>c_rule-allowed OR rule-activo <> abap_true
        OR NOT line_exists( field_ids[ table_line = rule-campo_id ] )
        OR NOT line_exists( section_ids[ table_line = rule-seccion_id ] )
        OR NOT line_exists( config-pasos[ area = rule-area ] ).
        error = 'Regla duplicada o referencia invalida de campo/seccion/area/version'. RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD plan.
    CLEAR: additions, error.
    error = validate( desired ).
    IF error IS NOT INITIAL. RETURN. ENDIF.
    DATA candidate TYPE ty_config.
    IF existing-versiones IS INITIAL AND ( existing-pasos IS NOT INITIAL OR existing-reglas IS NOT INITIAL ).
      error = 'Hay pasos/reglas sin la version DEMO; revisar manualmente'. RETURN.
    ENDIF.

    LOOP AT desired-flujos INTO DATA(row_flujos).
      READ TABLE existing-flujos WITH KEY flujo_id = row_flujos-flujo_id INTO DATA(found_flujos).
      IF sy-subrc = 0.
        IF found_flujos <> row_flujos.
          error = 'Conflicto: YMMT_DM_FLUJO ya tiene otros valores; no se sobrescribe'. RETURN.
        ENDIF.
      ELSE.
        APPEND row_flujos TO candidate-flujos.
      ENDIF.
    ENDLOOP.
    LOOP AT desired-versiones INTO DATA(row_versiones).
      READ TABLE existing-versiones WITH KEY flujo_id = row_versiones-flujo_id version = row_versiones-version INTO
        DATA(found_versiones).
      IF sy-subrc = 0.
        row_versiones-creado_por = found_versiones-creado_por.
        row_versiones-creado_el = found_versiones-creado_el.
        IF found_versiones <> row_versiones.
          error = 'Conflicto: YMMT_DM_FLUJO_VR ya tiene otros valores; no se sobrescribe'. RETURN.
        ENDIF.
      ELSE.
        APPEND row_versiones TO candidate-versiones.
      ENDIF.
    ENDLOOP.
    LOOP AT desired-pasos INTO DATA(row_pasos).
      READ TABLE existing-pasos WITH KEY flujo_id = row_pasos-flujo_id version = row_pasos-version paso_id =
        row_pasos-paso_id INTO DATA(found_pasos).
      IF sy-subrc = 0.
        IF found_pasos <> row_pasos.
          error = 'Conflicto: YMMT_DM_PASO ya tiene otros valores; no se sobrescribe'. RETURN.
        ENDIF.
      ELSE.
        APPEND row_pasos TO candidate-pasos.
      ENDIF.
    ENDLOOP.
    LOOP AT desired-campos INTO DATA(row_campos).
      READ TABLE existing-campos WITH KEY campo_id = row_campos-campo_id INTO DATA(found_campos).
      IF sy-subrc = 0.
        IF found_campos <> row_campos.
          error = 'Conflicto: YMMT_DM_CAMPO ya tiene otros valores; no se sobrescribe'. RETURN.
        ENDIF.
      ELSE.
        APPEND row_campos TO candidate-campos.
      ENDIF.
    ENDLOOP.
    LOOP AT desired-secciones INTO DATA(row_secciones).
      READ TABLE existing-secciones WITH KEY seccion_id = row_secciones-seccion_id INTO DATA(found_secciones).
      IF sy-subrc = 0.
        IF found_secciones <> row_secciones.
          error = 'Conflicto: YMMT_DM_SECCION ya tiene otros valores; no se sobrescribe'. RETURN.
        ENDIF.
      ELSE.
        APPEND row_secciones TO candidate-secciones.
      ENDIF.
    ENDLOOP.
    LOOP AT desired-reglas INTO DATA(row_reglas).
      READ TABLE existing-reglas WITH KEY flujo_id = row_reglas-flujo_id version = row_reglas-version area =
        row_reglas-area campo_id = row_reglas-campo_id INTO DATA(found_reglas).
      IF sy-subrc = 0.
        row_reglas-regla_uuid = found_reglas-regla_uuid.
        IF found_reglas <> row_reglas.
          error = 'Conflicto: YMMT_DM_REGLA ya tiene otros valores; no se sobrescribe'. RETURN.
        ENDIF.
      ELSE.
        APPEND row_reglas TO candidate-reglas.
      ENDIF.
    ENDLOOP.
    LOOP AT existing-pasos INTO DATA(extra_pasos).
      IF NOT line_exists( desired-pasos[ flujo_id = extra_pasos-flujo_id version = extra_pasos-version paso_id =
        extra_pasos-paso_id ] ).
        error = 'La version existente tiene pasos adicionales; no se altera'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT existing-reglas INTO DATA(extra_reglas).
      IF NOT line_exists( desired-reglas[ flujo_id = extra_reglas-flujo_id version = extra_reglas-version area =
        extra_reglas-area campo_id = extra_reglas-campo_id ] ).
        error = 'La version existente tiene reglas adicionales; no se altera'. RETURN.
      ENDIF.
    ENDLOOP.
    IF existing-versiones IS NOT INITIAL AND candidate IS NOT INITIAL.
      error = 'La version DEMO ya esta publicada; no se completa ni modifica parcialmente'. RETURN.
    ENDIF.
    additions = candidate.
  ENDMETHOD.
ENDCLASS.

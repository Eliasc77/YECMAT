CLASS ycl_dm_rules DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS can_request
      IMPORTING request_id TYPE sysuuid_x16 change TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(allowed) TYPE abap_bool.
    CLASS-METHODS can_write
      IMPORTING segment_id TYPE sysuuid_x16 field_id TYPE ymme_dm_campo_id
      RETURNING VALUE(allowed) TYPE abap_bool.
    CLASS-METHODS lock_value
      IMPORTING segment_id TYPE sysuuid_x16 field_id TYPE ymme_dm_campo_id
      RETURNING VALUE(locked) TYPE abap_bool.
    CLASS-METHODS check_value
      IMPORTING metadata TYPE ymmt_dm_campo val TYPE string
      RETURNING VALUE(error) TYPE string.
    CLASS-METHODS required
      IMPORTING task TYPE ymmt_dm_tarea
      RETURNING VALUE(error) TYPE string.
    CLASS-METHODS context_key
      IMPORTING kind TYPE ymmt_dm_seg-tipo_segmento a TYPE string OPTIONAL b TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE ymmt_dm_seg-contexto_clave.
ENDCLASS.

CLASS ycl_dm_rules IMPLEMENTATION.
  METHOD can_request.
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    SELECT SINGLE creado_por FROM ymmt_dm_sol
      WHERE solicitud_uuid = @request_id INTO @DATA(owner).
    IF sy-subrc <> 0. RETURN. ENDIF.
    allowed = xsdbool( owner = user ).
    IF allowed = abap_false AND change = abap_false.
      SELECT SINGLE tarea_uuid FROM ymmt_dm_tarea
        WHERE solicitud_uuid = @request_id AND responsable = @user INTO @DATA(task_id).
      allowed = xsdbool( sy-subrc = 0 ).
    ENDIF.
  ENDMETHOD.

  METHOD can_write.
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    SELECT SINGLE FROM ymmt_dm_seg AS s
      INNER JOIN ymmt_dm_sol AS h ON h~solicitud_uuid = s~solicitud_uuid
      INNER JOIN ymmt_dm_campo AS c ON c~campo_id = @field_id
      FIELDS s~solicitud_uuid, s~tipo_segmento, h~flujo_id, h~version,
             h~creado_por, h~estado, c~tipo_segmento AS campo_segmento, c~activo
      WHERE s~segmento_uuid = @segment_id INTO @DATA(context).
    IF sy-subrc <> 0 OR context-activo <> abap_true
      OR context-tipo_segmento <> context-campo_segmento
      OR ( context-estado <> 'BORRADOR' AND context-estado <> 'EN_CURSO' ). RETURN. ENDIF.
    SELECT * FROM ymmt_dm_regla WHERE flujo_id = @context-flujo_id
      AND version = @context-version AND campo_id = @field_id AND activo = @abap_true
      AND ( estado_campo = 'O' OR estado_campo = 'M' ) INTO TABLE @DATA(rules).
    SELECT SINGLE t~tarea_uuid FROM ymmt_dm_tarea AS t
      INNER JOIN ymmt_dm_regla AS r ON r~flujo_id = t~flujo_id AND r~version = t~version AND r~area = t~area
      WHERE t~solicitud_uuid = @context-solicitud_uuid AND t~estado = 'FINALIZADA'
        AND r~campo_id = @field_id AND r~activo = @abap_true AND r~estado_campo <> 'I'
      INTO @DATA(closed_task).
    IF sy-subrc = 0. RETURN. ENDIF.
    LOOP AT rules INTO DATA(rule).
      IF context-estado = 'BORRADOR' AND context-creado_por = user.
        allowed = abap_true. RETURN.
      ENDIF.
      SELECT * FROM ymmt_dm_tarea WHERE solicitud_uuid = @context-solicitud_uuid
        AND area = @rule-area AND ( estado = 'PENDIENTE' OR estado = 'EN_CURSO' )
        INTO TABLE @DATA(tasks).
      LOOP AT tasks INTO DATA(task).
        IF task-responsable = user OR context-creado_por = user.
          allowed = abap_true. RETURN.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_value.
    "Interaction phase only: hold the same task locks as Finalizar/Cerrar until commit.
    IF can_write( segment_id = segment_id field_id = field_id ) = abap_false. RETURN. ENDIF.
    SELECT SINGLE s~solicitud_uuid, h~estado FROM ymmt_dm_seg AS s
      INNER JOIN ymmt_dm_sol AS h ON h~solicitud_uuid = s~solicitud_uuid
      WHERE s~segmento_uuid = @segment_id INTO @DATA(context).
    IF sy-subrc <> 0. RETURN. ENDIF.
    IF context-estado = 'BORRADOR'.
      SET LOCKS OF yi_dm_sol ENTITY Solicitud
        FROM VALUE #( ( SolicitudUUID = context-solicitud_uuid ) ) FAILED DATA(header_failed) REPORTED DATA(header_failed_messages).
      IF header_failed-solicitud IS NOT INITIAL. RETURN. ENDIF.
    ELSE.
      SELECT DISTINCT t~tarea_uuid AS TareaUUID FROM ymmt_dm_tarea AS t
        INNER JOIN ymmt_dm_regla AS r ON r~flujo_id = t~flujo_id AND r~version = t~version AND r~area = t~area
        WHERE t~solicitud_uuid = @context-solicitud_uuid AND r~campo_id = @field_id
          AND r~activo = @abap_true AND r~estado_campo <> 'I'
        ORDER BY t~tarea_uuid INTO TABLE @DATA(task_keys).
      IF task_keys IS INITIAL. RETURN. ENDIF.
      SET LOCKS OF yi_dm_tarea ENTITY Tarea FROM CORRESPONDING #( task_keys )
        FAILED DATA(task_failed) REPORTED DATA(task_failed_messages).
      IF task_failed-tarea IS NOT INITIAL. RETURN. ENDIF.
    ENDIF.
    locked = can_write( segment_id = segment_id field_id = field_id ).
  ENDMETHOD.

  METHOD context_key.
    "Length prefixes make the encoding unambiguous, including embedded separators.
    result = |{ kind }:{ strlen( a ) }:{ a }:{ strlen( b ) }:{ b }|.
  ENDMETHOD.

  METHOD check_value.
    IF metadata-longitud <= 0 OR metadata-longitud > 1333 OR metadata-decimales < 0
      OR metadata-decimales > metadata-longitud.
      error = 'Metadatos de longitud/decimales invalidos'. RETURN.
    ENDIF.
    DATA(value_type) = to_upper( metadata-tipo_dato ).
    DATA(numeric) = xsdbool( value_type = 'DEC' OR value_type = 'CURR' OR value_type = 'QUAN'
      OR value_type = 'INT1' OR value_type = 'INT2' OR value_type = 'INT4' ).
    IF strlen( val ) > 1333 OR ( numeric = abap_false AND strlen( val ) > metadata-longitud ).
      error = |Valor excede longitud { metadata-longitud }|. RETURN.
    ENDIF.
    "Empty values are allowed during capture; completion checks mandatory rules.
    IF val IS INITIAL. RETURN. ENDIF.
    CASE value_type.
      WHEN 'CHAR' OR 'STRING'.
      WHEN 'NUMC'.
        IF val CN '0123456789'. error = 'Solo se admiten digitos'. ENDIF.
      WHEN 'INT1' OR 'INT2' OR 'INT4'.
        IF NOT matches( val = val regex = '^-?[0-9]+$' ).
          error = 'Entero invalido'. RETURN.
        ENDIF.
        DATA(digits) = val.
        REPLACE ALL OCCURRENCES OF '-' IN digits WITH ''.
        IF strlen( digits ) > metadata-longitud.
          error = 'Longitud numerica excedida'. RETURN.
        ENDIF.
        TRY.
            DATA(integer) = CONV int4( val ).
            IF ( value_type = 'INT1' AND ( integer < 0 OR integer > 255 ) )
              OR ( value_type = 'INT2' AND ( integer < -32768 OR integer > 32767 ) ).
              error = 'Entero fuera del rango del tipo'.
            ENDIF.
          CATCH cx_sy_conversion_error.
            error = 'Entero fuera del rango INT4'.
        ENDTRY.
      WHEN 'DEC' OR 'CURR' OR 'QUAN'.
        IF NOT matches( val = val regex = '^-?[0-9]+(\.[0-9]+)?$' ).
          error = 'Decimal invalido; utilizar punto decimal'. RETURN.
        ENDIF.
        SPLIT val AT '.' INTO DATA(whole) DATA(fraction).
        REPLACE ALL OCCURRENCES OF '-' IN whole WITH ''.
        IF strlen( fraction ) > metadata-decimales
          OR strlen( whole ) + strlen( fraction ) > metadata-longitud.
          error = 'Precision o escala decimal excedida'.
        ENDIF.
      WHEN 'DATS'.
        IF strlen( val ) <> 8 OR val CN '0123456789'.
          error = 'Fecha invalida; utilizar YYYYMMDD'. RETURN.
        ENDIF.
        DATA(year) = CONV i( val(4) ).
        DATA(month) = CONV i( val+4(2) ).
        DATA(day) = CONV i( val+6(2) ).
        IF year = 0 OR month < 1 OR month > 12 OR day < 1.
          error = 'Fecha invalida'. RETURN.
        ENDIF.
        DATA(days) = COND i( WHEN month = 4 OR month = 6 OR month = 9 OR month = 11
                           THEN 30 WHEN month = 2 THEN 28 ELSE 31 ).
        IF month = 2 AND ( year MOD 400 = 0 OR ( year MOD 4 = 0 AND year MOD 100 <> 0 ) ).
          days = 29.
        ENDIF.
        IF day > days. error = 'Fecha invalida'. ENDIF.
      WHEN 'BOOL'.
        IF val <> 'X'. error = 'Booleano permitido: X o vacio'. ENDIF.
      WHEN 'UNIT' OR 'CUKY' OR 'LANG'.
        IF val <> to_upper( val ). error = 'Usar clave interna SAP en mayusculas'. ENDIF.
      WHEN OTHERS.
        error = 'Tipo dinamico no soportado por el contrato'.
    ENDCASE.
  ENDMETHOD.

  METHOD required.
    SELECT FROM ymmt_dm_regla AS r
      INNER JOIN ymmt_dm_campo AS c ON c~campo_id = r~campo_id
      FIELDS c~*
      WHERE r~flujo_id = @task-flujo_id AND r~version = @task-version
        AND r~area = @task-area AND r~activo = @abap_true
        AND r~estado_campo = 'M' AND c~activo = @abap_true
      INTO TABLE @DATA(fields).
    LOOP AT fields INTO DATA(field).
      SELECT segmento_uuid FROM ymmt_dm_seg
        WHERE solicitud_uuid = @task-solicitud_uuid AND tipo_segmento = @field-tipo_segmento
        INTO TABLE @DATA(segments).
      IF segments IS INITIAL.
        error = |Falta contexto { field-tipo_segmento } para { field-campo_id }|. RETURN.
      ENDIF.
      LOOP AT segments INTO DATA(segment).
        READ ENTITIES OF yi_dm_dato ENTITY Dato FIELDS ( Valor )
          WITH VALUE #( ( SegmentoUUID = segment-segmento_uuid CampoId = field-campo_id ) )
          RESULT DATA(values).
        IF values IS INITIAL OR values[ 1 ]-Valor IS INITIAL.
          error = |Campo obligatorio { field-campo_id } en segmento { segment-segmento_uuid }|. RETURN.
        ENDIF.
        error = check_value( metadata = field val = CONV string( values[ 1 ]-Valor ) ).
        IF error IS NOT INITIAL. RETURN. ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

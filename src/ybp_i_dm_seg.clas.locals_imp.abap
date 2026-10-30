CLASS lhc_Segmento DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    DATA blocked TYPE HASHED TABLE OF sysuuid_x16 WITH UNIQUE KEY table_line.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Segmento RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Segmento RESULT result.
    METHODS defaults FOR DETERMINE ON MODIFY IMPORTING keys FOR Segmento~defaults.
    METHODS context FOR DETERMINE ON SAVE IMPORTING keys FOR Segmento~context.
    METHODS validateContext FOR VALIDATE ON SAVE IMPORTING keys FOR Segmento~validateContext.
    METHODS build IMPORTING id TYPE sysuuid_x16 kind TYPE ymmt_dm_seg-tipo_segmento
      EXPORTING context_value TYPE ymmt_dm_seg-contexto_clave error TYPE string.
ENDCLASS.
CLASS lhc_Segmento IMPLEMENTATION.
  METHOD get_global_authorizations.
    DATA(allow) = COND #( WHEN cl_abap_context_info=>get_user_technical_name( ) IS NOT INITIAL
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = allow %update = allow ).
  ENDMETHOD.
  METHOD get_instance_authorizations.
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    result = VALUE #( FOR row IN rows ( %tky = row-%tky
      %update = COND #( WHEN ycl_dm_rules=>can_request( request_id = row-SolicitudUUID
        change = abap_true ) = abap_true THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ) ) ).
  ENDMETHOD.
  METHOD defaults.
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      DELETE TABLE blocked WITH TABLE KEY table_line = row-SegmentoUUID.
      IF ycl_dm_rules=>can_request( request_id = row-SolicitudUUID change = abap_true ) = abap_false.
        INSERT row-SegmentoUUID INTO TABLE blocked. CONTINUE.
      ENDIF.
      SET LOCKS OF yi_dm_sol ENTITY Solicitud
        FROM VALUE #( ( SolicitudUUID = row-SolicitudUUID ) ) FAILED DATA(header_failed) REPORTED DATA(header_failed_messages).
      IF header_failed-solicitud IS NOT INITIAL. INSERT row-SegmentoUUID INTO TABLE blocked. ENDIF.
    ENDLOOP.
    MODIFY ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento UPDATE FIELDS ( Estado )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky Estado = 'ACTIVO' ) ).
  ENDMETHOD.
  METHOD build.
    CLEAR: error, context_value.
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Centro ALL FIELDS
      WITH VALUE #( ( SegmentoUUID = id ) ) RESULT DATA(centros).
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Almacen ALL FIELDS
      WITH VALUE #( ( SegmentoUUID = id ) ) RESULT DATA(almacenes).
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Ventas ALL FIELDS
      WITH VALUE #( ( SegmentoUUID = id ) ) RESULT DATA(ventas).
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Valoracion ALL FIELDS
      WITH VALUE #( ( SegmentoUUID = id ) ) RESULT DATA(valoraciones).
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Unidad ALL FIELDS
      WITH VALUE #( ( SegmentoUUID = id ) ) RESULT DATA(unidades).
    DATA(count) = lines( centros ) + lines( almacenes ) + lines( ventas )
      + lines( valoraciones ) + lines( unidades ).
    DATA a TYPE string. DATA b TYPE string.
    CASE kind.
      WHEN 'GENERAL'.
        IF count <> 0. error = 'GENERAL no admite subtipo'. ENDIF.
      WHEN 'CENTRO'.
        IF count <> 1 OR centros IS INITIAL.
          error = 'CENTRO requiere exclusivamente su subtipo'.
        ELSE. a = centros[ 1 ]-Centro. ENDIF.
      WHEN 'ALMACEN'.
        IF count <> 1 OR almacenes IS INITIAL.
          error = 'ALMACEN requiere exclusivamente su subtipo'.
        ELSE. a = almacenes[ 1 ]-Centro. b = almacenes[ 1 ]-Almacen. ENDIF.
      WHEN 'VENTAS'.
        IF count <> 1 OR ventas IS INITIAL.
          error = 'VENTAS requiere exclusivamente su subtipo'.
        ELSE. a = ventas[ 1 ]-OrgVentas. b = ventas[ 1 ]-Canal. ENDIF.
      WHEN 'VALORACION'.
        IF count <> 1 OR valoraciones IS INITIAL.
          error = 'VALORACION requiere exclusivamente su subtipo'.
        ELSE. a = valoraciones[ 1 ]-AreaValoracion. b = valoraciones[ 1 ]-TipoValoracion. ENDIF.
      WHEN 'UNIDAD'.
        IF count <> 1 OR unidades IS INITIAL.
          error = 'UNIDAD requiere exclusivamente su subtipo'.
        ELSE. a = unidades[ 1 ]-UnidadAlternativa. ENDIF.
      WHEN OTHERS. error = 'Tipo de segmento desconocido'.
    ENDCASE.
    IF kind <> 'GENERAL' AND a IS INITIAL. error = 'Contexto organizativo vacio'. ENDIF.
    IF ( kind = 'ALMACEN' OR kind = 'VENTAS' ) AND b IS INITIAL.
      error = 'La segunda dimension organizativa es obligatoria'.
    ENDIF.
    IF a <> to_upper( a ) OR b <> to_upper( b ).
      error = 'Usar claves organizativas internas SAP en mayusculas'.
    ENDIF.
    IF error IS INITIAL.
      context_value = ycl_dm_rules=>context_key( kind = kind a = a b = b ).
    ENDIF.
  ENDMETHOD.
  METHOD context.
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      build( EXPORTING id = row-SegmentoUUID kind = row-TipoSegmento
             IMPORTING context_value = DATA(value) error = DATA(error) ).
      IF error IS INITIAL.
        MODIFY ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento UPDATE FIELDS ( ContextoClave )
          WITH VALUE #( ( %tky = row-%tky ContextoClave = value ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD validateContext.
    READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      build( EXPORTING id = row-SegmentoUUID kind = row-TipoSegmento
             IMPORTING context_value = DATA(value) error = DATA(error) ).
      READ ENTITIES OF yi_dm_sol ENTITY Solicitud FIELDS ( Estado )
        WITH VALUE #( ( SolicitudUUID = row-SolicitudUUID ) ) RESULT DATA(headers).
      DATA(state) = COND ymmt_dm_sol-estado( WHEN headers IS NOT INITIAL THEN headers[ 1 ]-Estado ELSE '' ).
      IF headers IS INITIAL OR ( state <> 'BORRADOR' AND state <> 'EN_CURSO' )
        OR ycl_dm_rules=>can_request( request_id = row-SolicitudUUID change = abap_true ) = abap_false.
        error = 'Crear contexto requiere una solicitud guardada y propia en captura'.
      ENDIF.
      IF row-TipoSegmento = 'CENTRO' OR row-TipoSegmento = 'ALMACEN'.
        SELECT SINGLE f~centro_criterio FROM ymmt_dm_sol AS h
          INNER JOIN ymmt_dm_flujo AS f ON f~flujo_id = h~flujo_id
          WHERE h~solicitud_uuid = @row-SolicitudUUID INTO @DATA(criterion).
        IF sy-subrc = 0 AND criterion IS NOT INITIAL.
          DATA plant TYPE werks_d.
          CLEAR plant.
          READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Centro ALL FIELDS
            WITH VALUE #( ( SegmentoUUID = row-SegmentoUUID ) ) RESULT DATA(centros).
          READ ENTITIES OF yi_dm_seg IN LOCAL MODE ENTITY Segmento BY \_Almacen ALL FIELDS
            WITH VALUE #( ( SegmentoUUID = row-SegmentoUUID ) ) RESULT DATA(almacenes).
          IF centros IS NOT INITIAL. plant = centros[ 1 ]-Centro. ENDIF.
          IF almacenes IS NOT INITIAL. plant = almacenes[ 1 ]-Centro. ENDIF.
          IF plant <> criterion. error = 'Centro incompatible con el criterio de flujo'. ENDIF.
        ENDIF.
      ENDIF.
      IF error IS INITIAL.
        SELECT SINGLE segmento_uuid FROM ymmt_dm_seg WHERE solicitud_uuid = @row-SolicitudUUID
          AND tipo_segmento = @row-TipoSegmento AND contexto_clave = @value
          AND segmento_uuid <> @row-SegmentoUUID INTO @DATA(duplicate).
        IF sy-subrc = 0. error = 'El contexto ya existe en la solicitud'. ENDIF.
      ENDIF.
      LOOP AT rows INTO DATA(other) WHERE SolicitudUUID = row-SolicitudUUID
          AND TipoSegmento = row-TipoSegmento AND SegmentoUUID <> row-SegmentoUUID.
        IF other-ContextoClave = value. error = 'Contexto repetido en la misma peticion'. ENDIF.
      ENDLOOP.
      IF line_exists( blocked[ table_line = row-SegmentoUUID ] ).
        error = 'Solicitud no accesible o en transicion; actualizar y reintentar'.
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-segmento.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-segmento.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Centro DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateSubtype FOR VALIDATE ON SAVE IMPORTING keys FOR Centro~validateSubtype.
ENDCLASS.
CLASS lhc_Centro IMPLEMENTATION.
  METHOD validateSubtype.
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE segmento_uuid FROM ymmt_dm_seg
        WHERE segmento_uuid = @key-SegmentoUUID INTO @DATA(existing).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = key-%tky ) TO failed-centro.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'El contexto es inmutable; crear raiz y subtipo juntos' ) ) TO reported-centro.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Almacen DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateSubtype FOR VALIDATE ON SAVE IMPORTING keys FOR Almacen~validateSubtype.
ENDCLASS.
CLASS lhc_Almacen IMPLEMENTATION.
  METHOD validateSubtype.
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE segmento_uuid FROM ymmt_dm_seg
        WHERE segmento_uuid = @key-SegmentoUUID INTO @DATA(existing).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = key-%tky ) TO failed-almacen.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'El contexto es inmutable; crear raiz y subtipo juntos' ) ) TO reported-almacen.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Ventas DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateSubtype FOR VALIDATE ON SAVE IMPORTING keys FOR Ventas~validateSubtype.
ENDCLASS.
CLASS lhc_Ventas IMPLEMENTATION.
  METHOD validateSubtype.
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE segmento_uuid FROM ymmt_dm_seg
        WHERE segmento_uuid = @key-SegmentoUUID INTO @DATA(existing).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = key-%tky ) TO failed-ventas.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'El contexto es inmutable; crear raiz y subtipo juntos' ) ) TO reported-ventas.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Valoracion DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateSubtype FOR VALIDATE ON SAVE IMPORTING keys FOR Valoracion~validateSubtype.
ENDCLASS.
CLASS lhc_Valoracion IMPLEMENTATION.
  METHOD validateSubtype.
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE segmento_uuid FROM ymmt_dm_seg
        WHERE segmento_uuid = @key-SegmentoUUID INTO @DATA(existing).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = key-%tky ) TO failed-valoracion.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'El contexto es inmutable; crear raiz y subtipo juntos' ) ) TO reported-valoracion.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Unidad DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateSubtype FOR VALIDATE ON SAVE IMPORTING keys FOR Unidad~validateSubtype.
ENDCLASS.
CLASS lhc_Unidad IMPLEMENTATION.
  METHOD validateSubtype.
    LOOP AT keys INTO DATA(key).
      SELECT SINGLE segmento_uuid FROM ymmt_dm_seg
        WHERE segmento_uuid = @key-SegmentoUUID INTO @DATA(existing).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = key-%tky ) TO failed-unidad.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'El contexto es inmutable; crear raiz y subtipo juntos' ) ) TO reported-unidad.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

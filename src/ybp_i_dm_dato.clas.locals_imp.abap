CLASS lhc_Dato DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_blocked,
             SegmentoUUID TYPE sysuuid_x16,
             CampoId TYPE ymme_dm_campo_id,
           END OF ty_blocked.
    DATA blocked TYPE HASHED TABLE OF ty_blocked WITH UNIQUE KEY SegmentoUUID CampoId.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Dato RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Dato RESULT result.
    METHODS audit FOR DETERMINE ON MODIFY IMPORTING keys FOR Dato~audit.
    METHODS validateValue FOR VALIDATE ON SAVE IMPORTING keys FOR Dato~validateValue.
ENDCLASS.
CLASS lhc_Dato IMPLEMENTATION.
  METHOD get_global_authorizations.
    DATA(allow) = COND #( WHEN cl_abap_context_info=>get_user_technical_name( ) IS NOT INITIAL
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = allow %update = allow ).
  ENDMETHOD.
  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys ( %tky = key-%tky
      %update = COND #( WHEN ycl_dm_rules=>can_write( segment_id = key-SegmentoUUID
        field_id = key-CampoId ) = abap_true THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ) ) ).
  ENDMETHOD.
  METHOD audit.
    LOOP AT keys INTO DATA(key).
      DELETE TABLE blocked WITH TABLE KEY SegmentoUUID = key-SegmentoUUID CampoId = key-CampoId.
      IF ycl_dm_rules=>lock_value( segment_id = key-SegmentoUUID field_id = key-CampoId ) = abap_false.
        INSERT VALUE #( SegmentoUUID = key-SegmentoUUID CampoId = key-CampoId ) INTO TABLE blocked.
      ENDIF.
    ENDLOOP.
    MODIFY ENTITIES OF yi_dm_dato IN LOCAL MODE ENTITY Dato UPDATE FIELDS ( ModificadoPor )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky
        ModificadoPor = cl_abap_context_info=>get_user_technical_name( ) ) ).
  ENDMETHOD.
  METHOD validateValue.
    READ ENTITIES OF yi_dm_dato IN LOCAL MODE ENTITY Dato ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      DATA(error) = CONV string( '' ).
      SELECT SINGLE * FROM ymmt_dm_campo WHERE campo_id = @row-CampoId INTO @DATA(metadata).
      IF sy-subrc <> 0 OR metadata-activo <> abap_true
        OR ycl_dm_rules=>can_write( segment_id = row-SegmentoUUID field_id = row-CampoId ) = abap_false.
        error = 'Campo/contexto no editable, solicitud cerrada o usuario sin tarea habilitada'.
      ELSE.
        error = ycl_dm_rules=>check_value( metadata = metadata val = CONV string( row-Valor ) ).
      ENDIF.
      SELECT SINGLE solicitud_uuid FROM ymmt_dm_seg WHERE segmento_uuid = @row-SegmentoUUID INTO @DATA(parent_id).
      READ ENTITIES OF yi_dm_sol ENTITY Solicitud FIELDS ( Estado )
        WITH VALUE #( ( SolicitudUUID = parent_id ) ) RESULT DATA(headers).
      IF headers IS INITIAL OR ( headers[ 1 ]-Estado <> 'BORRADOR' AND headers[ 1 ]-Estado <> 'EN_CURSO' ).
        error = 'Guardar valores antes de cerrar la solicitud'.
      ENDIF.
      IF line_exists( blocked[ SegmentoUUID = row-SegmentoUUID CampoId = row-CampoId ] ).
        error = 'Campo no editable o tarea en edicion; actualizar y reintentar'.
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-dato.
        APPEND VALUE #( %tky = row-%tky %element-Valor = if_abap_behv=>mk-on
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
          text = error ) ) TO reported-dato.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

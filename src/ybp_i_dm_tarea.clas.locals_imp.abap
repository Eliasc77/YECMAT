CLASS lhc_Tarea DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Tarea RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Tarea RESULT result.
    METHODS defaults FOR DETERMINE ON MODIFY IMPORTING keys FOR Tarea~defaults.
    METHODS validateTask FOR VALIDATE ON SAVE IMPORTING keys FOR Tarea~validateTask.
    METHODS Iniciar FOR MODIFY IMPORTING keys FOR ACTION Tarea~Iniciar RESULT result.
    METHODS Finalizar FOR MODIFY IMPORTING keys FOR ACTION Tarea~Finalizar RESULT result.
    METHODS Reabrir FOR MODIFY IMPORTING keys FOR ACTION Tarea~Reabrir RESULT result.
ENDCLASS.
CLASS lhc_Tarea IMPLEMENTATION.
  METHOD get_global_authorizations.
    DATA(allow) = COND #( WHEN cl_abap_context_info=>get_user_technical_name( ) IS NOT INITIAL
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = allow %update = allow %action-Iniciar = allow
      %action-Finalizar = allow %action-Reabrir = allow ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      DATA(owner) = ycl_dm_rules=>can_request( request_id = row-SolicitudUUID change = abap_true ).
      DATA(update_auth) = COND #( WHEN owner = abap_true THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
      DATA(work_auth) = COND #( WHEN owner = abap_true OR row-Responsable = cl_abap_context_info=>get_user_technical_name( )
        THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
      APPEND VALUE #( %tky = row-%tky %update = update_auth %action-Iniciar = work_auth
        %action-Finalizar = work_auth %action-Reabrir = update_auth ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD defaults.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    DATA now TYPE timestampl. GET TIME STAMP FIELD now.
    LOOP AT rows INTO DATA(row).
      READ ENTITIES OF yi_dm_sol ENTITY Solicitud ALL FIELDS
        WITH VALUE #( ( SolicitudUUID = row-SolicitudUUID ) ) RESULT DATA(headers).
      IF headers IS INITIAL. CONTINUE. ENDIF.
      DATA(header) = headers[ 1 ].
      SELECT SINGLE area FROM ymmt_dm_paso WHERE flujo_id = @header-FlujoId
        AND version = @header-Version AND paso_id = @row-PasoId INTO @DATA(area).
      IF sy-subrc <> 0. CONTINUE. ENDIF.
      MODIFY ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea
        UPDATE FIELDS ( FlujoId Version Area Estado CreadoEl )
        WITH VALUE #( ( %tky = row-%tky FlujoId = header-FlujoId Version = header-Version
          Area = area Estado = 'PENDIENTE' CreadoEl = now ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validateTask.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      READ ENTITIES OF yi_dm_sol ENTITY Solicitud ALL FIELDS
        WITH VALUE #( ( SolicitudUUID = row-SolicitudUUID ) ) RESULT DATA(headers).
      DATA(error) = CONV string( '' ).
      IF headers IS INITIAL.
        error = 'Solicitud inexistente'.
      ELSE.
        DATA(header) = headers[ 1 ].
        SELECT SINGLE * FROM ymmt_dm_paso WHERE flujo_id = @row-FlujoId
          AND version = @row-Version AND paso_id = @row-PasoId INTO @DATA(step).
        IF sy-subrc <> 0 OR step-area <> row-Area OR row-FlujoId <> header-FlujoId
          OR row-Version <> header-Version OR step-activo <> abap_true
          OR ( step-condicion_bpm IS NOT INITIAL AND step-condicion_bpm <> header-ClasificacionBpm ).
          error = 'Paso/area/version no corresponden a la solicitud'.
        ELSEIF header-Estado <> 'EN_CURSO' OR row-Responsable IS INITIAL.
          error = 'Solicitud fuera de captura o responsable vacio'.
        ENDIF.
        SELECT SINGLE tarea_uuid FROM ymmt_dm_tarea WHERE tarea_uuid = @row-TareaUUID INTO @DATA(existing).
        IF sy-subrc <> 0 AND header-CreadoPor <> cl_abap_context_info=>get_user_technical_name( ).
          error = 'Solo el creador genera tareas'.
        ENDIF.
      ENDIF.
      IF error IS INITIAL AND row-Estado = 'FINALIZADA'.
        DATA task TYPE ymmt_dm_tarea.
        task = VALUE #( solicitud_uuid = row-SolicitudUUID flujo_id = row-FlujoId
          version = row-Version area = row-Area paso_id = row-PasoId ).
        error = ycl_dm_rules=>required( task ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-tarea.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-tarea.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD Iniciar.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-Estado <> 'PENDIENTE'.
        APPEND VALUE #( %tky = row-%tky ) TO failed-tarea. CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea UPDATE FIELDS ( Estado )
        WITH VALUE #( ( %tky = row-%tky Estado = 'EN_CURSO' ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD Finalizar.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      DATA task TYPE ymmt_dm_tarea.
      task = VALUE #( solicitud_uuid = row-SolicitudUUID flujo_id = row-FlujoId
        version = row-Version area = row-Area paso_id = row-PasoId ).
      DATA(error) = ycl_dm_rules=>required( task ).
      IF row-Estado <> 'PENDIENTE' AND row-Estado <> 'EN_CURSO'. error = 'La tarea no esta abierta'. ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-tarea.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-tarea.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea UPDATE FIELDS ( Estado )
        WITH VALUE #( ( %tky = row-%tky Estado = 'FINALIZADA' ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD Reabrir.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-Estado <> 'FINALIZADA'.
        APPEND VALUE #( %tky = row-%tky ) TO failed-tarea. CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea UPDATE FIELDS ( Estado )
        WITH VALUE #( ( %tky = row-%tky Estado = 'PENDIENTE' ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_tarea IN LOCAL MODE ENTITY Tarea ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.
ENDCLASS.

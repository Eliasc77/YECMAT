CLASS lhc_Solicitud DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Solicitud RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Solicitud RESULT result.
    METHODS defaults FOR DETERMINE ON MODIFY IMPORTING keys FOR Solicitud~defaults.
    METHODS validateRequest FOR VALIDATE ON SAVE IMPORTING keys FOR Solicitud~validateRequest.
    METHODS Iniciar FOR MODIFY IMPORTING keys FOR ACTION Solicitud~Iniciar RESULT result.
    METHODS Cerrar FOR MODIFY IMPORTING keys FOR ACTION Solicitud~Cerrar RESULT result.
    METHODS Aprobar FOR MODIFY IMPORTING keys FOR ACTION Solicitud~Aprobar RESULT result.
    METHODS Reabrir FOR MODIFY IMPORTING keys FOR ACTION Solicitud~Reabrir RESULT result.
ENDCLASS.

CLASS lhc_Solicitud IMPLEMENTATION.
  METHOD get_global_authorizations.
    DATA(allow) = COND #( WHEN cl_abap_context_info=>get_user_technical_name( ) IS NOT INITIAL
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = allow %update = allow %action-Iniciar = allow
      %action-Cerrar = allow %action-Aprobar = allow %action-Reabrir = allow ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys
      LET allow = COND #( WHEN ycl_dm_rules=>can_request(
        request_id = key-SolicitudUUID change = abap_true ) = abap_true
        THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized )
      IN ( %tky = key-%tky %update = allow %action-Iniciar = allow
           %action-Cerrar = allow %action-Aprobar = allow %action-Reabrir = allow ) ).
  ENDMETHOD.

  METHOD defaults.
    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.
    MODIFY ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud
      UPDATE FIELDS ( Estado CreadoPor CreadoEl )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky Estado = 'BORRADOR'
        CreadoPor = cl_abap_context_info=>get_user_technical_name( ) CreadoEl = now ) ).
  ENDMETHOD.

  METHOD validateRequest.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    DATA(today) = cl_abap_context_info=>get_system_date( ).
    LOOP AT rows INTO DATA(row).
      DATA(error) = CONV string( '' ).
      SELECT SINGLE FROM ymmt_dm_flujo_vr AS v
        INNER JOIN ymmt_dm_flujo AS f ON f~flujo_id = v~flujo_id
        FIELDS f~tipo_material, f~tipo_operacion, f~activo,
               v~estado, v~vigente_desde, v~vigente_hasta
        WHERE v~flujo_id = @row-FlujoId AND v~version = @row-Version INTO @DATA(config).
      IF sy-subrc <> 0 OR row-Version <= 0 OR row-NumeroSolicitud IS INITIAL.
        error = 'Numero y version de flujo existentes son obligatorios'.
      ELSEIF config-tipo_material <> row-TipoMaterial OR config-tipo_operacion <> row-TipoOperacion.
        error = 'Criterios de solicitud incompatibles con el flujo'.
      ENDIF.
      SELECT SINGLE solicitud_uuid FROM ymmt_dm_sol
        WHERE solicitud_uuid = @row-SolicitudUUID INTO @DATA(existing).
      IF sy-subrc <> 0 AND ( config-estado <> 'PUBLICADA' OR config-activo <> abap_true
        OR config-vigente_desde IS INITIAL OR config-vigente_desde > today
        OR ( config-vigente_hasta IS NOT INITIAL AND config-vigente_hasta < today ) ).
        error = 'La version elegida no esta publicada y vigente'.
      ENDIF.
      IF row-TipoOperacion NA 'CMI' OR ( row-TipoOperacion CA 'MI' AND row-Material IS INITIAL ).
        error = 'Operacion C/M/I; material obligatorio para M/I'.
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-solicitud.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD Iniciar.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      DATA(input) = keys[ KEY entity %tky = row-%tky ]-%param.
      DATA(error) = CONV string( '' ).
      IF row-Estado <> 'BORRADOR' OR ( input-ClasificacionBpm <> 'A' AND input-ClasificacionBpm <> 'B' ).
        error = 'Iniciar requiere BORRADOR y clasificacion A/B'.
      ENDIF.
      SELECT * FROM ymmt_dm_paso WHERE flujo_id = @row-FlujoId AND version = @row-Version
        AND activo = @abap_true
        AND ( condicion_bpm = @input-ClasificacionBpm OR condicion_bpm = '' )
        ORDER BY orden, paso_id INTO TABLE @DATA(steps).
      IF steps IS INITIAL. error = 'La version no tiene pasos aplicables'. ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-solicitud.
        CONTINUE.
      ENDIF.
      DATA tasks TYPE TABLE FOR CREATE yi_dm_tarea\Tarea.
      CLEAR tasks.
      LOOP AT steps INTO DATA(step).
        APPEND VALUE #( %cid = |{ row-SolicitudUUID }-{ sy-tabix }|
          SolicitudUUID = row-SolicitudUUID PasoId = step-paso_id
          Responsable = cl_abap_context_info=>get_user_technical_name( ) ) TO tasks.
      ENDLOOP.
      MODIFY ENTITIES OF yi_dm_tarea ENTITY Tarea
        CREATE FIELDS ( SolicitudUUID PasoId Responsable ) WITH tasks
        FAILED DATA(task_failed) REPORTED DATA(task_reported).
      IF task_failed-tarea IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = 'No se pudieron generar las tareas' ) ) TO reported-solicitud.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud
        UPDATE FIELDS ( ClasificacionBpm Estado )
        WITH VALUE #( ( %tky = row-%tky ClasificacionBpm = input-ClasificacionBpm Estado = 'EN_CURSO' ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD Cerrar.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      SELECT tarea_uuid AS TareaUUID FROM ymmt_dm_tarea
        WHERE solicitud_uuid = @row-SolicitudUUID ORDER BY tarea_uuid INTO TABLE @DATA(task_keys).
      SET LOCKS OF yi_dm_tarea ENTITY Tarea FROM CORRESPONDING #( task_keys )
        FAILED DATA(lock_failed) REPORTED DATA(lock_failed_messages).
      IF lock_failed-tarea IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Hay tareas o valores en edicion; actualizar y reintentar' ) ) TO reported-solicitud.
        CONTINUE.
      ENDIF.
      READ ENTITIES OF yi_dm_tarea ENTITY Tarea ALL FIELDS
        WITH CORRESPONDING #( task_keys ) RESULT DATA(tasks).
      DATA(pending) = xsdbool( row-Estado <> 'EN_CURSO' OR tasks IS INITIAL OR lines( tasks ) <> lines( task_keys ) ).
      LOOP AT tasks INTO DATA(task).
        SELECT SINGLE obligatorio FROM ymmt_dm_paso WHERE flujo_id = @task-FlujoId
          AND version = @task-Version AND paso_id = @task-PasoId INTO @DATA(required).
        IF sy-subrc <> 0 OR ( required = abap_true AND task-Estado <> 'FINALIZADA' ).
          pending = abap_true.
        ENDIF.
      ENDLOOP.
      IF pending = abap_true.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = 'Solicitud no iniciada o tareas obligatorias pendientes' ) ) TO reported-solicitud.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud UPDATE FIELDS ( Estado )
        WITH VALUE #( ( %tky = row-%tky Estado = COND #( WHEN row-ClasificacionBpm = 'A'
          THEN 'REVISION' ELSE 'LISTA_INTEG' ) ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD Aprobar.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      IF row-Estado <> 'REVISION' OR row-ClasificacionBpm <> 'A'.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = 'Solo se aprueba una solicitud BPM en REVISION' ) ) TO reported-solicitud.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud UPDATE FIELDS ( Estado )
        WITH VALUE #( ( %tky = row-%tky Estado = 'LISTA_INTEG' ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD Reabrir.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(rows).
    LOOP AT rows INTO DATA(row).
      DATA(task_id) = keys[ KEY entity %tky = row-%tky ]-%param-TareaUUID.
      SELECT SINGLE solicitud_uuid FROM ymmt_dm_tarea
        WHERE tarea_uuid = @task_id INTO @DATA(parent_id).
      IF sy-subrc <> 0 OR parent_id <> row-SolicitudUUID
        OR ( row-Estado <> 'REVISION' AND row-Estado <> 'EN_CURSO' ).
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud.
        APPEND VALUE #( %tky = row-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = 'Tarea ajena o solicitud fuera de revision/captura' ) ) TO reported-solicitud.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_tarea ENTITY Tarea EXECUTE Reabrir
        FROM VALUE #( ( TareaUUID = task_id ) ) FAILED DATA(task_failed).
      IF task_failed-tarea IS NOT INITIAL.
        APPEND VALUE #( %tky = row-%tky ) TO failed-solicitud. CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud UPDATE FIELDS ( Estado )
        WITH VALUE #( ( %tky = row-%tky Estado = 'EN_CURSO' ) ).
    ENDLOOP.
    READ ENTITIES OF yi_dm_sol IN LOCAL MODE ENTITY Solicitud ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR r IN done ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.
ENDCLASS.

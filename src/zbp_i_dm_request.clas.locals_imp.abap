CLASS lhc_Request DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Request RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Request RESULT result.
    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Request~setInitialStatus.
    METHODS validateOperation FOR VALIDATE ON SAVE
      IMPORTING keys FOR Request~validateOperation.
    METHODS classify FOR MODIFY
      IMPORTING keys FOR ACTION Request~classify RESULT result.
    METHODS rejectArea FOR MODIFY
      IMPORTING keys FOR ACTION Request~rejectArea RESULT result.
    METHODS approveAndActivate FOR MODIFY
      IMPORTING keys FOR ACTION Request~approveAndActivate RESULT result.
ENDCLASS.

CLASS lhc_Request IMPLEMENTATION.
  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    "La comprobación PFCG concreta debe mapear los seis objetos Z_DM_ACCESO_*.
    result = VALUE #( FOR key IN keys
      ( %tky = key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
        %action-classify = if_abap_behv=>auth-allowed
        %action-rejectArea = if_abap_behv=>auth-allowed
        %action-approveAndActivate = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD setInitialStatus.
    MODIFY ENTITIES OF zi_dm_request IN LOCAL MODE
      ENTITY Request UPDATE FIELDS ( Status )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'DRAFT' ) ).
  ENDMETHOD.

  METHOD validateOperation.
    READ ENTITIES OF zi_dm_request IN LOCAL MODE
      ENTITY Request FIELDS ( Operation Material ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).
    LOOP AT requests ASSIGNING FIELD-SYMBOL(<request>).
      IF <request>-Operation NA 'CMI'.
        APPEND VALUE #( %tky = <request>-%tky ) TO failed-request.
        APPEND VALUE #( %tky = <request>-%tky
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Operación válida: C, M o I' ) )
          TO reported-request.
      ELSEIF <request>-Operation CA 'MI' AND <request>-Material IS INITIAL.
        APPEND VALUE #( %tky = <request>-%tky ) TO failed-request.
        APPEND VALUE #( %tky = <request>-%tky
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Material es obligatorio para modificar/inactivar' ) )
          TO reported-request.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD classify.
    GET TIME STAMP FIELD DATA(now).
    READ ENTITIES OF zi_dm_request IN LOCAL MODE
      ENTITY Request ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<request>).
      READ TABLE keys ASSIGNING FIELD-SYMBOL(<action_key>)
        WITH KEY %tky = <request>-%tky.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(flow) = <action_key>-%param-FlowType.
      IF flow NA 'AB'.
        APPEND VALUE #( %tky = <request>-%tky ) TO failed-request.
        APPEND VALUE #( %tky = <request>-%tky
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                        text = 'Flujo válido: A (BPM) o B (no BPM)' ) )
          TO reported-request.
        CONTINUE.
      ENDIF.

      SELECT DISTINCT area FROM zdm_field_c
        WHERE material_type = @<request>-MaterialType
          AND operation = @<request>-Operation
          AND active = @abap_true
          AND field_status <> 'I'
        INTO TABLE @DATA(areas).

      IF areas IS NOT INITIAL.
        MODIFY ENTITIES OF zi_dm_areatask
          ENTITY AreaTask CREATE AUTO FILL CID FIELDS
            ( RequestUUID Area TrafficLight EnabledAt )
          WITH VALUE #( FOR area_row IN areas
            ( RequestUUID = <request>-RequestUUID
              Area = area_row-area
              TrafficLight = 'R'
              EnabledAt = now ) ).
      ENDIF.

      MODIFY ENTITIES OF zi_dm_request IN LOCAL MODE
        ENTITY Request UPDATE FIELDS ( FlowType Status ParallelStartedAt )
        WITH VALUE #( ( %tky = <request>-%tky FlowType = flow
                        Status = 'PARALLEL'
                        ParallelStartedAt = now ) ).
    ENDLOOP.

    READ ENTITIES OF zi_dm_request IN LOCAL MODE
      ENTITY Request ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR row IN done ( %tky = row-%tky %param = row ) ).
  ENDMETHOD.

  METHOD rejectArea.
    GET TIME STAMP FIELD DATA(now).
    DATA initial_finished_at TYPE zdm_req_a-finished_at.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE request_uuid FROM zdm_req_h
        WHERE request_uuid = @<key>-RequestUUID AND status = 'QA_REVIEW'
        INTO @DATA(request_uuid).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-request.
        CONTINUE.
      ENDIF.
      UPDATE zdm_req_a SET traffic_light = 'R', finished_at = @initial_finished_at
        WHERE request_uuid = @request_uuid AND area = @<key>-%param-Area.
      INSERT zdm_audit FROM @( VALUE #(
        audit_uuid = cl_system_uuid=>create_uuid_x16_static( )
        request_uuid = request_uuid area = <key>-%param-Area
        event_type = 'REJECT' new_value = <key>-%param-Reason
        changed_by = sy-uname changed_at = now ) ).
      MODIFY ENTITIES OF zi_dm_request IN LOCAL MODE ENTITY Request
        UPDATE FIELDS ( Status ) WITH VALUE #( ( %tky = <key>-%tky Status = 'PARALLEL' ) ).
    ENDLOOP.
    READ ENTITIES OF zi_dm_request IN LOCAL MODE ENTITY Request ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR row IN done ( %tky = row-%tky %param = row ) ).
  ENDMETHOD.

  METHOD approveAndActivate.
    GET TIME STAMP FIELD DATA(now).
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE status, flow_type FROM zdm_req_h
        WHERE request_uuid = @<key>-RequestUUID INTO @DATA(header).
      IF header-status <> 'QA_REVIEW' OR header-flow_type <> 'A'.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-request.
        CONTINUE.
      ENDIF.
      SELECT SINGLE event_uuid FROM zdm_outbox
        WHERE request_uuid = @<key>-RequestUUID AND event_type = 'MATERIAL'
        INTO @DATA(existing_event).
      IF sy-subrc <> 0.
        INSERT zdm_outbox FROM @( VALUE #(
          event_uuid = cl_system_uuid=>create_uuid_x16_static( )
          request_uuid = <key>-RequestUUID event_type = 'MATERIAL'
          status = 'N' created_at = now ) ).
      ENDIF.
      MODIFY ENTITIES OF zi_dm_request IN LOCAL MODE ENTITY Request
        UPDATE FIELDS ( Status ) WITH VALUE #( ( %tky = <key>-%tky Status = 'QUEUED' ) ).
    ENDLOOP.
    READ ENTITIES OF zi_dm_request IN LOCAL MODE ENTITY Request ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR row IN done ( %tky = row-%tky %param = row ) ).
  ENDMETHOD.
ENDCLASS.

CLASS lhc_AreaTask DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR AreaTask RESULT result.
    METHODS startWork FOR MODIFY
      IMPORTING keys FOR ACTION AreaTask~startWork RESULT result.
    METHODS finishArea FOR MODIFY
      IMPORTING keys FOR ACTION AreaTask~finishArea RESULT result.
ENDCLASS.

CLASS lhc_AreaTask IMPLEMENTATION.
  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys
      ( %tky = key-%tky %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
        %action-startWork = if_abap_behv=>auth-allowed
        %action-finishArea = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD startWork.
    MODIFY ENTITIES OF zi_dm_areatask IN LOCAL MODE ENTITY AreaTask
      UPDATE FIELDS ( TrafficLight StartedAt ResponsibleUser )
      WITH VALUE #( FOR key IN keys
        ( %tky = key-%tky TrafficLight = 'A' StartedAt = utclong_current( )
          ResponsibleUser = sy-uname ) ).
    READ ENTITIES OF zi_dm_areatask IN LOCAL MODE ENTITY AreaTask ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR row IN done ( %tky = row-%tky %param = row ) ).
  ENDMETHOD.

  METHOD finishArea.
    READ ENTITIES OF zi_dm_areatask IN LOCAL MODE ENTITY AreaTask ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(tasks).
    LOOP AT tasks ASSIGNING FIELD-SYMBOL(<task>).
      SELECT SINGLE material_type, operation, flow_type FROM zdm_req_h
        WHERE request_uuid = @<task>-RequestUUID INTO @DATA(header).
      SELECT field_name FROM zdm_field_c
        WHERE material_type = @header-material_type
          AND operation = @header-operation AND area = @<task>-Area
          AND field_status = 'M' AND active = @abap_true
        INTO TABLE @DATA(required_fields).

      DATA missing TYPE abap_bool.
      LOOP AT required_fields ASSIGNING FIELD-SYMBOL(<required>).
        SELECT SINGLE field_value FROM zdm_req_f
          WHERE request_uuid = @<task>-RequestUUID AND area = @<task>-Area
            AND field_name = @<required>-field_name
          INTO @DATA(field_value).
        IF sy-subrc <> 0 OR field_value IS INITIAL.
          missing = abap_true.
          APPEND VALUE #( %tky = <task>-%tky
            %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
              text = |Campo obligatorio pendiente: { <required>-field_name }| ) )
            TO reported-areatask.
        ENDIF.
      ENDLOOP.
      IF missing = abap_true.
        APPEND VALUE #( %tky = <task>-%tky ) TO failed-areatask.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_dm_areatask IN LOCAL MODE ENTITY AreaTask
        UPDATE FIELDS ( TrafficLight FinishedAt )
        WITH VALUE #( ( %tky = <task>-%tky TrafficLight = 'V'
                        FinishedAt = utclong_current( ) ) ).
      INSERT zdm_audit FROM @( VALUE #(
        audit_uuid = cl_system_uuid=>create_uuid_x16_static( )
        request_uuid = <task>-RequestUUID area = <task>-Area
        event_type = 'FINISH' changed_by = sy-uname
        changed_at = utclong_current( ) ) ).

      SELECT COUNT(*) FROM zdm_req_a
        WHERE request_uuid = @<task>-RequestUUID AND traffic_light <> 'V'
        INTO @DATA(open_tasks).
      "La tarea actual todavía no está grabada físicamente durante la interacción.
      IF open_tasks <= 1.
        DATA(next_status) = COND #( WHEN header-flow_type = 'A'
                                   THEN 'QA_REVIEW' ELSE 'QUEUED' ).
        UPDATE zdm_req_h SET status = @next_status
          WHERE request_uuid = @<task>-RequestUUID.
        IF header-flow_type = 'B'.
          SELECT SINGLE event_uuid FROM zdm_outbox
            WHERE request_uuid = @<task>-RequestUUID AND event_type = 'MATERIAL'
            INTO @DATA(existing_event).
          IF sy-subrc <> 0.
            INSERT zdm_outbox FROM @( VALUE #(
              event_uuid = cl_system_uuid=>create_uuid_x16_static( )
              request_uuid = <task>-RequestUUID event_type = 'MATERIAL'
              status = 'N' created_at = utclong_current( ) ) ).
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
    READ ENTITIES OF zi_dm_areatask IN LOCAL MODE ENTITY AreaTask ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(done).
    result = VALUE #( FOR row IN done ( %tky = row-%tky %param = row ) ).
  ENDMETHOD.
ENDCLASS.

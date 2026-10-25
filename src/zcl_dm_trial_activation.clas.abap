CLASS zcl_dm_trial_activation DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    METHODS process_next
      RETURNING VALUE(message) TYPE string.
ENDCLASS.

CLASS zcl_dm_trial_activation IMPLEMENTATION.
  METHOD process_next.
    SELECT SINGLE FROM zdm_outbox
      FIELDS event_uuid, request_uuid
      WHERE status = 'N'
      ORDER BY created_at
      INTO @DATA(event).
    IF sy-subrc <> 0.
      message = 'No hay activaciones pendientes'.
      RETURN.
    ENDIF.

    "MOCK para BTP Trial: no existe un sistema de materiales local.
    UPDATE zdm_outbox
      SET status = 'S',
          message_text = 'Simulación BTP Trial completada',
          processed_at = @utclong_current( )
      WHERE event_uuid = @event-event_uuid AND status = 'N'.
    IF sy-dbcnt = 1.
      UPDATE zdm_req_h
        SET status = 'ACTIVE', material_created_at = @utclong_current( ),
            error_text = ''
        WHERE request_uuid = @event-request_uuid.
      message = 'Solicitud activada en modo MOCK'.
    ELSE.
      message = 'El evento fue tomado por otro proceso'.
    ENDIF.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    out->write( process_next( ) ).
  ENDMETHOD.
ENDCLASS.

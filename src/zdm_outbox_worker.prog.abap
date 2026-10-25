REPORT zdm_outbox_worker.

PARAMETERS p_max TYPE i DEFAULT 50.

START-OF-SELECTION.
  SELECT * FROM zdm_outbox
    WHERE status IN ( 'N', 'E' ) AND retry_count < 5
    ORDER BY created_at
    INTO TABLE @DATA(events)
    UP TO @p_max ROWS.

  LOOP AT events ASSIGNING FIELD-SYMBOL(<event>).
    "Un bloqueo corto por evento impide consumidores duplicados.
    SELECT SINGLE FOR UPDATE * FROM zdm_outbox
      WHERE event_uuid = @<event>-event_uuid AND status IN ( 'N', 'E' )
      INTO @DATA(claimed).
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.
    UPDATE zdm_outbox SET status = 'P' WHERE event_uuid = @claimed-event_uuid.
    COMMIT WORK AND WAIT.

    DATA(result) = NEW zcl_dm_material_port( )->execute( claimed-request_uuid ).
    IF result-success = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
      UPDATE zdm_outbox SET status = 'S', message_text = @result-message,
        processed_at = @utclong_current( ) WHERE event_uuid = @claimed-event_uuid.
      UPDATE zdm_req_h SET status = 'ACTIVE', material = @result-material,
        material_created_at = @utclong_current( ), error_text = ''
        WHERE request_uuid = @claimed-request_uuid.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      UPDATE zdm_outbox SET status = 'E', retry_count = retry_count + 1,
        message_text = @result-message WHERE event_uuid = @claimed-event_uuid.
      UPDATE zdm_req_h SET status = 'ERROR', error_text = @result-message
        WHERE request_uuid = @claimed-request_uuid.
    ENDIF.
    COMMIT WORK AND WAIT.
  ENDLOOP.

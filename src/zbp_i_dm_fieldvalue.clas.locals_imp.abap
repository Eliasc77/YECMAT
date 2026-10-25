CLASS lhc_FieldValue DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR FieldValue RESULT result.
    METHODS validateOwnership FOR VALIDATE ON SAVE
      IMPORTING keys FOR FieldValue~validateOwnership.
ENDCLASS.

CLASS lhc_FieldValue IMPLEMENTATION.
  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys
      ( %tky = key-%tky %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD validateOwnership.
    READ ENTITIES OF zi_dm_fieldvalue IN LOCAL MODE ENTITY FieldValue ALL FIELDS
      WITH CORRESPONDING #( keys ) RESULT DATA(values).
    LOOP AT values ASSIGNING FIELD-SYMBOL(<value>).
      SELECT SINGLE material_type, operation FROM zdm_req_h
        WHERE request_uuid = @<value>-RequestUUID INTO @DATA(header).
      SELECT SINGLE field_status FROM zdm_field_c
        WHERE material_type = @header-material_type
          AND operation = @header-operation AND area = @<value>-Area
          AND field_name = @<value>-FieldName AND active = @abap_true
        INTO @DATA(field_status).
      IF sy-subrc <> 0 OR field_status CA 'IR'.
        APPEND VALUE #( %tky = <value>-%tky ) TO failed-fieldvalue.
        APPEND VALUE #( %tky = <value>-%tky
          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
            text = 'Campo no editable para el área' ) ) TO reported-fieldvalue.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

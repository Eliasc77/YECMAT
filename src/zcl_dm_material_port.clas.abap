CLASS zcl_dm_material_port DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dm_material_port.
  PRIVATE SECTION.
    METHODS value
      IMPORTING request_uuid TYPE sysuuid_x16 field_name TYPE zdm_req_f-field_name
      RETURNING VALUE(result) TYPE string.
ENDCLASS.

CLASS zcl_dm_material_port IMPLEMENTATION.
  METHOD value.
    SELECT SINGLE field_value FROM zdm_req_f
      WHERE request_uuid = @request_uuid AND field_name = @field_name
      INTO @result.
  ENDMETHOD.

  METHOD zif_dm_material_port~execute.
    SELECT SINGLE * FROM zdm_req_h WHERE request_uuid = @request_uuid
      INTO @DATA(request).
    IF sy-subrc <> 0.
      result-message = 'Solicitud inexistente'.
      RETURN.
    ENDIF.

    DATA head TYPE bapimathead.
    DATA basic TYPE bapi_mara.
    DATA basic_x TYPE bapi_marax.
    DATA plant TYPE bapi_marc.
    DATA plant_x TYPE bapi_marcx.
    DATA valuation TYPE bapi_mbew.
    DATA valuation_x TYPE bapi_mbewx.
    DATA descriptions TYPE STANDARD TABLE OF bapi_makt WITH EMPTY KEY.
    DATA return TYPE bapiret2.

    head-material = request-material.
    head-matl_type = request-material_type.
    head-ind_sector = 'Z'.
    head-basic_view = abap_true.
    head-purchase_view = abap_true.
    head-account_view = abap_true.

    basic-base_uom = value( request_uuid = request_uuid field_name = 'MARA-MEINS' ).
    basic-matl_group = value( request_uuid = request_uuid field_name = 'MARA-MATKL' ).
    basic_x-base_uom = abap_true.
    basic_x-matl_group = abap_true.

    plant-plant = request-plant.
    plant-pur_group = value( request_uuid = request_uuid field_name = 'MARC-EKGRP' ).
    plant_x-plant = request-plant.
    IF plant-pur_group IS NOT INITIAL.
      plant_x-pur_group = abap_true.
    ENDIF.

    valuation-val_area = request-plant.
    valuation-std_price = value( request_uuid = request_uuid field_name = 'MBEW-STPRS' ).
    valuation-price_ctrl = COND #( WHEN valuation-std_price IS INITIAL THEN 'V' ELSE 'S' ).
    valuation_x-val_area = request-plant.
    valuation_x-price_ctrl = abap_true.
    IF valuation-std_price IS NOT INITIAL.
      valuation_x-std_price = abap_true.
    ENDIF.

    APPEND VALUE #( langu = sy-langu
      matl_desc = value( request_uuid = request_uuid field_name = 'MAKT-MAKTX' ) )
      TO descriptions.

    CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
      EXPORTING headdata = head clientdata = basic clientdatax = basic_x
                plantdata = plant plantdatax = plant_x
                valuationdata = valuation valuationdatax = valuation_x
      IMPORTING return = return
      TABLES materialdescription = descriptions.

    result-success = xsdbool( return-type NA 'AEX' ).
    result-material = COND #( WHEN request-material IS NOT INITIAL
                              THEN request-material ELSE return-parameter ).
    result-message = return-message.
  ENDMETHOD.
ENDCLASS.

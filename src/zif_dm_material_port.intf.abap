INTERFACE zif_dm_material_port PUBLIC.
  TYPES: BEGIN OF ty_result,
           success  TYPE abap_bool,
           material TYPE matnr,
           message  TYPE string,
         END OF ty_result.
  METHODS execute
    IMPORTING request_uuid TYPE sysuuid_x16
    RETURNING VALUE(result) TYPE ty_result.
ENDINTERFACE.

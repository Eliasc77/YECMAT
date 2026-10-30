CLASS ltc_rules DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS decimal_scale FOR TESTING.
    METHODS calendar_dates FOR TESTING.
    METHODS integer_overflow FOR TESTING.
    METHODS context_encoding FOR TESTING.
    METHODS empty_progress FOR TESTING.
ENDCLASS.
CLASS ltc_rules IMPLEMENTATION.
  METHOD decimal_scale.
    DATA(meta) = VALUE ymmt_dm_campo( tipo_dato = 'DEC' longitud = 5 decimales = 2 ).
    cl_abap_unit_assert=>assert_initial( ycl_dm_rules=>check_value( metadata = meta val = '-100.12' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '1.234' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '1,25' ) ).
  ENDMETHOD.
  METHOD calendar_dates.
    DATA(meta) = VALUE ymmt_dm_campo( tipo_dato = 'DATS' longitud = 8 ).
    cl_abap_unit_assert=>assert_initial( ycl_dm_rules=>check_value( metadata = meta val = '20000229' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '19000229' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '20260431' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '20261301' ) ).
  ENDMETHOD.
  METHOD integer_overflow.
    DATA(meta) = VALUE ymmt_dm_campo( tipo_dato = 'INT4' longitud = 20 ).
    cl_abap_unit_assert=>assert_initial( ycl_dm_rules=>check_value( metadata = meta val = '-2147483648' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '2147483648' ) ).
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '1.5' ) ).
  ENDMETHOD.
  METHOD context_encoding.
    DATA(first) = ycl_dm_rules=>context_key( kind = 'ALMACEN' a = 'A:1' b = 'B' ).
    DATA(second) = ycl_dm_rules=>context_key( kind = 'ALMACEN' a = 'A' b = '1:B' ).
    cl_abap_unit_assert=>assert_differs( act = first exp = second ).
    cl_abap_unit_assert=>assert_equals( act = first
      exp = ycl_dm_rules=>context_key( kind = 'ALMACEN' a = 'A:1' b = 'B' ) ).
  ENDMETHOD.
  METHOD empty_progress.
    DATA(meta) = VALUE ymmt_dm_campo( tipo_dato = 'CHAR' longitud = 40 ).
    cl_abap_unit_assert=>assert_initial( ycl_dm_rules=>check_value( metadata = meta val = '' ) ).
    meta-longitud = 0.
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_rules=>check_value( metadata = meta val = '' ) ).
  ENDMETHOD.
ENDCLASS.

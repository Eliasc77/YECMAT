CLASS ltc_config DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS empty_system FOR TESTING.
    METHODS repeated_load_is_noop FOR TESTING.
    METHODS conflicting_field_aborts FOR TESTING.
    METHODS published_partial_aborts FOR TESTING.
    METHODS extra_step_aborts FOR TESTING.
    METHODS duplicate_rule_aborts FOR TESTING.
    METHODS existing_flow_can_be_reused FOR TESTING.
    METHODS audit_does_not_rewrite FOR TESTING.
ENDCLASS.
CLASS ltc_config IMPLEMENTATION.
  METHOD empty_system.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA existing TYPE ycl_dm_demo_config=>ty_config.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-flujos ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-versiones ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-pasos ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-campos ) exp = 9 ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-secciones ) exp = 6 ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-reglas ) exp = 9 ).
  ENDMETHOD.
  METHOD repeated_load_is_noop.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA(existing) = desired.
    LOOP AT existing-reglas ASSIGNING FIELD-SYMBOL(<rule>).
      <rule>-regla_uuid = CONV #( |{ sy-tabix WIDTH = 32 ALIGN = RIGHT PAD = '0' }| ).
    ENDLOOP.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions ).
  ENDMETHOD.
  METHOD conflicting_field_aborts.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA existing TYPE ycl_dm_demo_config=>ty_config.
    existing-campos = desired-campos.
    existing-campos[ 1 ]-longitud = 1.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions ).
  ENDMETHOD.
  METHOD published_partial_aborts.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA(existing) = desired.
    DELETE existing-reglas INDEX 1.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions ).
  ENDMETHOD.
  METHOD extra_step_aborts.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA(existing) = desired.
    APPEND VALUE #( mandt = sy-mandt flujo_id = ycl_dm_demo_config=>flujo_id
      version = 1 paso_id = 'EXTRA' area = 'EXTRA' ) TO existing-pasos.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions ).
  ENDMETHOD.
  METHOD duplicate_rule_aborts.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    APPEND desired-reglas[ 1 ] TO desired-reglas.
    DATA existing TYPE ycl_dm_demo_config=>ty_config.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions ).
  ENDMETHOD.
  METHOD existing_flow_can_be_reused.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA existing TYPE ycl_dm_demo_config=>ty_config.
    existing-flujos = desired-flujos.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions-flujos ).
    cl_abap_unit_assert=>assert_equals( act = lines( additions-versiones ) exp = 1 ).
  ENDMETHOD.
  METHOD audit_does_not_rewrite.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA(existing) = desired.
    existing-versiones[ 1 ]-creado_por = 'OTRO'.
    CLEAR existing-versiones[ 1 ]-creado_el.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_initial( additions ).
  ENDMETHOD.
ENDCLASS.

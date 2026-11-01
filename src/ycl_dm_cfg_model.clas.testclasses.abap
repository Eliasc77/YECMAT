CLASS ltc_model DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS fixture RETURNING VALUE(state) TYPE ycl_dm_cfg_model=>ty_state.
    METHODS protected_rule FOR TESTING.
    METHODS copy_preserves_history FOR TESTING.
    METHODS duplicate_create FOR TESTING.
    METHODS field_definition_frozen FOR TESTING.
    METHODS draft_rule_update FOR TESTING.
    METHODS used_draft_frozen FOR TESTING.
    METHODS publication_overlap FOR TESTING.
    METHODS publication_after_retire FOR TESTING.
    METHODS orphan_area FOR TESTING.
    METHODS invalid_date FOR TESTING.
    METHODS new_field FOR TESTING.
    METHODS protected_flow_criteria FOR TESTING.
ENDCLASS.
CLASS ltc_model IMPLEMENTATION.
  METHOD fixture.
    state-flujos = VALUE #( ( mandt = sy-mandt flujo_id = 'TEST' descripcion = 'Prueba' tipo_material = 'ZFER' tipo_operacion = 'C' activo = abap_true ) ).
    state-versiones = VALUE #( ( mandt = sy-mandt flujo_id = 'TEST' version = 1 estado = 'PUBLICADA' vigente_desde = '20200101' vigente_hasta = '99991231' ) ).
    state-campos = VALUE #( ( mandt = sy-mandt campo_id = 'MAKT_MAKTX' descripcion = 'Descripcion' tabla_sap = 'MAKT' campo_sap = 'MAKTX' tipo_segmento = 'GENERAL' tipo_dato = 'CHAR' longitud = 40 tipo_control = 'Input' activo = abap_true ) ).
    state-secciones = VALUE #( ( mandt = sy-mandt seccion_id = 'BASICOS' descripcion = 'Basicos' orden = 10 activo = abap_true ) ).
    state-pasos = VALUE #( ( mandt = sy-mandt flujo_id = 'TEST' version = 1 paso_id = 'PCP' area = 'PCP' fase = 'CAPTURA' orden = 10 obligatorio = abap_true activo = abap_true ) ).
    state-reglas = VALUE #( ( mandt = sy-mandt regla_uuid = '00000000000000000000000000000001' flujo_id = 'TEST' version = 1 area = 'PCP' campo_id = 'MAKT_MAKTX' seccion_id = 'BASICOS' estado_campo = 'M' orden = 10 activo = abap_true ) ).
  ENDMETHOD.
  METHOD protected_rule.
    ycl_dm_cfg_model=>plan( EXPORTING current = fixture( ) command = VALUE #( EntitySet = 'Reglas' Operation = 'GUARDAR' FlujoId = 'TEST' Version = 1 Area = 'PCP' CampoId = 'MAKT_MAKTX' SeccionId = 'BASICOS' EstadoCampo = 'O' Activo = abap_true ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD copy_preserves_history.
    DATA(before) = fixture( ).
    ycl_dm_cfg_model=>plan( EXPORTING current = before command = VALUE #( EntitySet = 'Versiones' Operation = 'COPIAR' FlujoId = 'TEST' Version = 1 VersionDestino = 2 ) IMPORTING next = DATA(after) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( after-versiones ) ).
    cl_abap_unit_assert=>assert_equals( exp = before-versiones[ 1 ] act = after-versiones[ version = 1 ] ).
    cl_abap_unit_assert=>assert_equals( exp = 'BORRADOR' act = after-versiones[ version = 2 ]-estado ).
    cl_abap_unit_assert=>assert_differs( exp = after-reglas[ version = 1 ]-regla_uuid act = after-reglas[ version = 2 ]-regla_uuid ).
  ENDMETHOD.
  METHOD duplicate_create.
    ycl_dm_cfg_model=>plan( EXPORTING current = fixture( ) command = VALUE #( EntitySet = 'Campos' Operation = 'CREAR' CampoId = 'MAKT_MAKTX' ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD field_definition_frozen.
    ycl_dm_cfg_model=>plan( EXPORTING current = fixture( ) command = VALUE #( EntitySet = 'Campos' Operation = 'GUARDAR' CampoId = 'MAKT_MAKTX' Descripcion = 'Descripcion' TablaSap = 'MAKT' CampoSap = 'MAKTX' TipoSegmento = 'GENERAL' TipoDato = 'CHAR' Longitud = 80 TipoControl = 'Input' Activo = abap_true ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD draft_rule_update.
    DATA(state) = fixture( ). state-versiones[ 1 ]-estado = 'BORRADOR'.
    ycl_dm_cfg_model=>plan( EXPORTING current = state command = VALUE #( EntitySet = 'Reglas' Operation = 'GUARDAR' FlujoId = 'TEST' Version = 1 Area = 'PCP' CampoId = 'MAKT_MAKTX' SeccionId = 'BASICOS' EstadoCampo = 'O' Activo = abap_true ) IMPORTING next = DATA(after) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_equals( exp = 'O' act = after-reglas[ 1 ]-estado_campo ).
    cl_abap_unit_assert=>assert_equals( exp = state-reglas[ 1 ]-regla_uuid act = after-reglas[ 1 ]-regla_uuid ).
  ENDMETHOD.
  METHOD used_draft_frozen.
    DATA(state) = fixture( ). state-versiones[ 1 ]-estado = 'BORRADOR'.
    state-used_versions = VALUE #( ( flujo_id = 'TEST' version = 1 ) ).
    ycl_dm_cfg_model=>plan( EXPORTING current = state command = VALUE #( EntitySet = 'Reglas' Operation = 'GUARDAR' FlujoId = 'TEST' Version = 1 Area = 'PCP' CampoId = 'MAKT_MAKTX' SeccionId = 'BASICOS' EstadoCampo = 'O' Activo = abap_true ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD publication_overlap.
    DATA(state) = fixture( ).
    ycl_dm_cfg_model=>plan( EXPORTING current = state command = VALUE #( EntitySet = 'Versiones' Operation = 'COPIAR' FlujoId = 'TEST' Version = 1 VersionDestino = 2 ) IMPORTING next = DATA(cloned) ).
    ycl_dm_cfg_model=>plan( EXPORTING current = cloned command = VALUE #( EntitySet = 'Versiones' Operation = 'PUBLICAR' FlujoId = 'TEST' Version = 2 ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD publication_after_retire.
    DATA(state) = fixture( ).
    ycl_dm_cfg_model=>plan( EXPORTING current = state command = VALUE #( EntitySet = 'Versiones' Operation = 'COPIAR' FlujoId = 'TEST' Version = 1 VersionDestino = 2 ) IMPORTING next = DATA(cloned) ).
    cloned-versiones[ version = 1 ]-estado = 'RETIRADA'.
    ycl_dm_cfg_model=>plan( EXPORTING current = cloned command = VALUE #( EntitySet = 'Versiones' Operation = 'PUBLICAR' FlujoId = 'TEST' Version = 2 ) IMPORTING next = DATA(after) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_equals( exp = 'PUBLICADA' act = after-versiones[ version = 2 ]-estado ).
  ENDMETHOD.
  METHOD orphan_area.
    DATA(state) = fixture( ). state-versiones[ 1 ]-estado = 'BORRADOR'.
    ycl_dm_cfg_model=>plan( EXPORTING current = state command = VALUE #( EntitySet = 'Pasos' Operation = 'GUARDAR' FlujoId = 'TEST' Version = 1 PasoId = 'PCP' Area = 'PCP' Fase = 'CAPTURA' Activo = abap_false ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD invalid_date.
    ycl_dm_cfg_model=>plan( EXPORTING current = fixture( ) command = VALUE #( EntitySet = 'Versiones' Operation = 'CREAR' FlujoId = 'TEST' Version = 2 VigenteDesde = '20260230' ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
  METHOD new_field.
    ycl_dm_cfg_model=>plan( EXPORTING current = fixture( ) command = VALUE #( EntitySet = 'Campos' Operation = 'CREAR' CampoId = 'MARA_MATKL' Descripcion = 'Grupo' TablaSap = 'MARA' CampoSap = 'MATKL' TipoSegmento = 'GENERAL' TipoDato = 'CHAR' Longitud = 9 TipoControl = 'Input' Activo = abap_true ) IMPORTING next = DATA(after) error = DATA(error) ).
    cl_abap_unit_assert=>assert_initial( error ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( after-campos ) ).
  ENDMETHOD.
  METHOD protected_flow_criteria.
    ycl_dm_cfg_model=>plan( EXPORTING current = fixture( ) command = VALUE #( EntitySet = 'Flujos' Operation = 'GUARDAR' FlujoId = 'TEST' Descripcion = 'Prueba' TipoMaterial = 'ZHAW' TipoOperacion = 'C' Activo = abap_true ) IMPORTING error = DATA(error) ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
ENDCLASS.

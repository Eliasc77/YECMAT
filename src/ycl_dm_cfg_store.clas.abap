CLASS ycl_dm_cfg_store DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS is_admin RETURNING VALUE(allowed) TYPE abap_bool.
    CLASS-METHODS read_state RETURNING VALUE(state) TYPE ycl_dm_cfg_model=>ty_state.
    CLASS-METHODS stage IMPORTING before TYPE ycl_dm_cfg_model=>ty_state after TYPE ycl_dm_cfg_model=>ty_state
      command TYPE yd_dm_cfg_cmd revision TYPE i EXPORTING error TYPE string.
    CLASS-METHODS persist.
    CLASS-METHODS clear.
    CLASS-METHODS pending RETURNING VALUE(result) TYPE abap_bool.
  PRIVATE SECTION.
    CLASS-DATA original TYPE ycl_dm_cfg_model=>ty_state.
    CLASS-DATA prepared TYPE ycl_dm_cfg_model=>ty_state.
    CLASS-DATA audit TYPE ymmt_dm_cfg_log.
    CLASS-DATA staged TYPE abap_bool.
ENDCLASS.

CLASS ycl_dm_cfg_store IMPLEMENTATION.
  METHOD is_admin.
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    SELECT SINGLE active FROM ymmt_dm_cfg_usr WHERE user_name = @user INTO @allowed.
    IF sy-subrc <> 0. allowed = abap_false. ENDIF.
  ENDMETHOD.
  METHOD read_state.
    SELECT * FROM ymmt_dm_campo ORDER BY PRIMARY KEY INTO TABLE @state-campos.
    SELECT * FROM ymmt_dm_seccion ORDER BY PRIMARY KEY INTO TABLE @state-secciones.
    SELECT * FROM ymmt_dm_flujo ORDER BY PRIMARY KEY INTO TABLE @state-flujos.
    SELECT * FROM ymmt_dm_flujo_vr ORDER BY PRIMARY KEY INTO TABLE @state-versiones.
    SELECT * FROM ymmt_dm_paso ORDER BY PRIMARY KEY INTO TABLE @state-pasos.
    SELECT * FROM ymmt_dm_regla ORDER BY PRIMARY KEY INTO TABLE @state-reglas.
    SELECT DISTINCT flujo_id, version FROM ymmt_dm_sol INTO TABLE @state-used_versions.
    SELECT DISTINCT campo_id FROM ymmt_dm_dato INTO TABLE @state-used_fields.
  ENDMETHOD.
  METHOD pending. result = staged. ENDMETHOD.
  METHOD clear. CLEAR: original, prepared, audit, staged. ENDMETHOD.
  METHOD stage.
    CLEAR error.
    IF staged = abap_true. error = 'Una sola operacion de configuracion por peticion; guardar y recargar antes de continuar'. RETURN. ENDIF.
    IF is_admin( ) = abap_false. error = 'Usuario no habilitado como administrador DM'. RETURN. ENDIF.
    TRY.
        audit = VALUE #( mandt = sy-mandt log_uuid = cl_system_uuid=>create_uuid_x16_static( ) revision = revision
          entity_set = command-EntitySet operation = command-Operation
          record_key = |{ command-FlujoId }/{ command-Version }/{ command-PasoId }/{ command-Area }/{ command-CampoId }/{ command-SeccionId }/{ command-VersionDestino }|
          changed_by = cl_abap_context_info=>get_user_technical_name( ) ).
        GET TIME STAMP FIELD audit-changed_at.
      CATCH cx_uuid_error INTO DATA(uuid_error). error = uuid_error->get_text( ). RETURN.
    ENDTRY.
    original = before. prepared = after. staged = abap_true.
  ENDMETHOD.
  METHOD persist.
    "Only the RAP additional saver calls this method. Never COMMIT/ROLLBACK here.
    IF staged = abap_false. RETURN. ENDIF.
    "Detect legacy/direct SQL writers which do not participate in the singleton lock.
    "A failed assertion aborts the complete RAP LUW; never overwrite a changed baseline.
    DATA(current) = read_state( ).
    ASSERT current-campos = original-campos AND current-secciones = original-secciones
      AND current-flujos = original-flujos AND current-versiones = original-versiones
      AND current-pasos = original-pasos AND current-reglas = original-reglas.
    "INSERT of a table without ACCEPTING DUPLICATE KEYS fails the LUW on a concurrent insert.
    DATA new_fields TYPE STANDARD TABLE OF ymmt_dm_campo WITH EMPTY KEY.
    LOOP AT prepared-campos INTO DATA(field).
      READ TABLE original-campos WITH KEY campo_id = field-campo_id INTO DATA(old_field).
      IF sy-subrc <> 0. APPEND field TO new_fields.
      ELSEIF old_field <> field. UPDATE ymmt_dm_campo FROM @field. ASSERT sy-subrc = 0. ENDIF.
    ENDLOOP.
    IF new_fields IS NOT INITIAL. INSERT ymmt_dm_campo FROM TABLE @new_fields. ENDIF.
    DATA new_sections TYPE STANDARD TABLE OF ymmt_dm_seccion WITH EMPTY KEY.
    LOOP AT prepared-secciones INTO DATA(section).
      READ TABLE original-secciones WITH KEY seccion_id = section-seccion_id INTO DATA(old_section).
      IF sy-subrc <> 0. APPEND section TO new_sections.
      ELSEIF old_section <> section. UPDATE ymmt_dm_seccion FROM @section. ASSERT sy-subrc = 0. ENDIF.
    ENDLOOP.
    IF new_sections IS NOT INITIAL. INSERT ymmt_dm_seccion FROM TABLE @new_sections. ENDIF.
    DATA new_flows TYPE STANDARD TABLE OF ymmt_dm_flujo WITH EMPTY KEY.
    LOOP AT prepared-flujos INTO DATA(flow).
      READ TABLE original-flujos WITH KEY flujo_id = flow-flujo_id INTO DATA(old_flow).
      IF sy-subrc <> 0. APPEND flow TO new_flows.
      ELSEIF old_flow <> flow. UPDATE ymmt_dm_flujo FROM @flow. ASSERT sy-subrc = 0. ENDIF.
    ENDLOOP.
    IF new_flows IS NOT INITIAL. INSERT ymmt_dm_flujo FROM TABLE @new_flows. ENDIF.
    DATA new_versions TYPE STANDARD TABLE OF ymmt_dm_flujo_vr WITH EMPTY KEY.
    LOOP AT prepared-versiones INTO DATA(version).
      READ TABLE original-versiones WITH KEY flujo_id = version-flujo_id version = version-version INTO DATA(old_version).
      IF sy-subrc <> 0. APPEND version TO new_versions.
      ELSEIF old_version <> version. UPDATE ymmt_dm_flujo_vr FROM @version. ASSERT sy-subrc = 0. ENDIF.
    ENDLOOP.
    IF new_versions IS NOT INITIAL. INSERT ymmt_dm_flujo_vr FROM TABLE @new_versions. ENDIF.
    DATA new_steps TYPE STANDARD TABLE OF ymmt_dm_paso WITH EMPTY KEY.
    LOOP AT prepared-pasos INTO DATA(step).
      READ TABLE original-pasos WITH KEY flujo_id = step-flujo_id version = step-version paso_id = step-paso_id INTO DATA(old_step).
      IF sy-subrc <> 0. APPEND step TO new_steps.
      ELSEIF old_step <> step. UPDATE ymmt_dm_paso FROM @step. ASSERT sy-subrc = 0. ENDIF.
    ENDLOOP.
    IF new_steps IS NOT INITIAL. INSERT ymmt_dm_paso FROM TABLE @new_steps. ENDIF.
    DATA new_rules TYPE STANDARD TABLE OF ymmt_dm_regla WITH EMPTY KEY.
    LOOP AT prepared-reglas INTO DATA(rule).
      READ TABLE original-reglas WITH KEY regla_uuid = rule-regla_uuid INTO DATA(old_rule).
      IF sy-subrc <> 0. APPEND rule TO new_rules.
      ELSEIF old_rule <> rule. UPDATE ymmt_dm_regla FROM @rule. ASSERT sy-subrc = 0. ENDIF.
    ENDLOOP.
    IF new_rules IS NOT INITIAL. INSERT ymmt_dm_regla FROM TABLE @new_rules. ENDIF.
    DATA logs TYPE STANDARD TABLE OF ymmt_dm_cfg_log WITH EMPTY KEY.
    APPEND audit TO logs. INSERT ymmt_dm_cfg_log FROM TABLE @logs.
    clear( ).
  ENDMETHOD.
ENDCLASS.

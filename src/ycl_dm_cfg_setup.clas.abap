CLASS ycl_dm_cfg_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.
CLASS ycl_dm_cfg_setup IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    "Idempotent developer bootstrap: only initializes GLOBAL, never grants access.
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    IF user IS INITIAL. out->write( 'No se pudo identificar el usuario tecnico' ). RETURN. ENDIF.
    SELECT SINGLE config_id FROM ymmt_dm_cfg_ctl WHERE config_id = 'GLOBAL' INTO @DATA(existing_root).
    IF sy-subrc = 0.
      out->write( 'GLOBAL ya existe. Se conserva la revision y la configuracion; no se cambian permisos.' ). RETURN.
    ENDIF.
    DATA roots TYPE STANDARD TABLE OF ymmt_dm_cfg_ctl WITH EMPTY KEY.
    DATA now TYPE timestampl. GET TIME STAMP FIELD now.
    APPEND VALUE #( mandt = sy-mandt config_id = 'GLOBAL' revision = 0 last_changed_by = user last_changed_at = now ) TO roots.
    TRY.
        INSERT ymmt_dm_cfg_ctl FROM TABLE @roots.
        COMMIT WORK AND WAIT.
      CATCH cx_sy_open_sql_db INTO DATA(error).
        ROLLBACK WORK. out->write( error->get_text( ) ). RETURN.
    ENDTRY.
    out->write( |GLOBAL inicializado por { user }. No se modificaron configuraciones ni solicitudes ni se asignaron roles.| ).
    out->write( 'Modo de prueba: el rol de administrador DM queda pendiente de activar.' ).
    out->write( 'Crear y publicar el Service Binding YBD_DM_CFG_O4 para YUI_DM_CFG_O4.' ).
  ENDMETHOD.
ENDCLASS.

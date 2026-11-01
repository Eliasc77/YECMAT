CLASS ycl_dm_cfg_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.
CLASS ycl_dm_cfg_setup IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    "One-time developer bootstrap. Does NOT grant new users after the first admin exists.
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    IF user IS INITIAL. out->write( 'No se pudo identificar el usuario tecnico' ). RETURN. ENDIF.
    SELECT SINGLE user_name FROM ymmt_dm_cfg_usr INTO @DATA(existing_admin).
    IF sy-subrc = 0.
      out->write( 'Administracion ya inicializada. No se cambian permisos ni configuracion.' ).
      out->write( 'Para otro administrador, un desarrollador autorizado debe mantener YMMT_DM_CFG_USR.' ).
      RETURN.
    ENDIF.
    SELECT SINGLE config_id FROM ymmt_dm_cfg_ctl WHERE config_id = 'GLOBAL' INTO @DATA(existing_root).
    IF sy-subrc = 0.
      out->write( 'Estado parcial detectado: existe GLOBAL sin administradores. Revisar con el responsable; no se autoasignan permisos.' ). RETURN.
    ENDIF.
    DATA roots TYPE STANDARD TABLE OF ymmt_dm_cfg_ctl WITH EMPTY KEY.
    DATA admins TYPE STANDARD TABLE OF ymmt_dm_cfg_usr WITH EMPTY KEY.
    DATA now TYPE timestampl. GET TIME STAMP FIELD now.
    APPEND VALUE #( mandt = sy-mandt config_id = 'GLOBAL' revision = 0 last_changed_by = user last_changed_at = now ) TO roots.
    APPEND VALUE #( mandt = sy-mandt user_name = user active = abap_true ) TO admins.
    TRY.
        INSERT ymmt_dm_cfg_ctl FROM TABLE @roots.
        INSERT ymmt_dm_cfg_usr FROM TABLE @admins.
        COMMIT WORK AND WAIT.
      CATCH cx_sy_open_sql_db INTO DATA(error).
        ROLLBACK WORK. out->write( error->get_text( ) ). RETURN.
    ENDTRY.
    out->write( |Administrador inicial: { user }. No se modificaron tablas de configuracion ni solicitudes.| ).
    out->write( 'Crear y publicar el Service Binding YBD_DM_CFG_O4 para YUI_DM_CFG_O4.' ).
  ENDMETHOD.
ENDCLASS.

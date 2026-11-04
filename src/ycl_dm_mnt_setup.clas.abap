CLASS ycl_dm_mnt_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.
CLASS ycl_dm_mnt_setup IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    IF ycl_dm_cfg_store=>can_maintain( ) = abap_false.
      out->write( 'Sin acceso al mantenimiento' ). RETURN.
    ENDIF.
    SELECT SINGLE config_id FROM ymmt_dm_cfg_ctl
      WHERE config_id = @yif_dm_constants=>c_configuracion-id_global INTO @DATA(id).
    IF sy-subrc <> 0.
      out->write( 'Ejecutar primero YCL_DM_CFG_SETUP para crear GLOBAL' ). RETURN.
    ENDIF.
    SET LOCKS OF yi_dm_cfg ENTITY Configuration
      FROM VALUE #( ( ConfigId = id ) ) FAILED DATA(fallos) REPORTED DATA(mensajes_bloqueo).
    IF fallos IS NOT INITIAL.
      out->write( 'Hay un mantenimiento en edicion. Cerrar y reintentar' ). RETURN.
    ENDIF.
    GET TIME STAMP FIELD DATA(now).
    TRY.
        UPDATE ymmt_dm_campo SET local_last_changed_at = @now
          WHERE local_last_changed_at = 0.
        UPDATE ymmt_dm_campo SET last_changed_at = @now WHERE last_changed_at = 0.
        UPDATE ymmt_dm_seccion SET local_last_changed_at = @now
          WHERE local_last_changed_at = 0.
        UPDATE ymmt_dm_seccion SET last_changed_at = @now WHERE last_changed_at = 0.
        UPDATE ymmt_dm_flujo SET local_last_changed_at = @now
          WHERE local_last_changed_at = 0.
        UPDATE ymmt_dm_flujo SET last_changed_at = @now WHERE last_changed_at = 0.
        UPDATE ymmt_dm_flujo_vr SET local_last_changed_at = @now
          WHERE local_last_changed_at = 0.
        UPDATE ymmt_dm_flujo_vr SET last_changed_at = @now WHERE last_changed_at = 0.
        UPDATE ymmt_dm_paso SET local_last_changed_at = @now
          WHERE local_last_changed_at = 0.
        UPDATE ymmt_dm_paso SET last_changed_at = @now WHERE last_changed_at = 0.
        UPDATE ymmt_dm_regla SET local_last_changed_at = @now
          WHERE local_last_changed_at = 0.
        UPDATE ymmt_dm_regla SET last_changed_at = @now WHERE last_changed_at = 0.
        UPDATE ymmt_dm_cfg_ctl SET rap_activo = @abap_true,
          revision = revision + 1, last_changed_at = @now
          WHERE config_id = @id AND rap_activo = @abap_false.
        COMMIT WORK AND WAIT.
      CATCH cx_sy_open_sql_db INTO DATA(error).
        ROLLBACK WORK. out->write( error->get_text( ) ). RETURN.
    ENDTRY.
    out->write( 'Mantenimiento RAP habilitado. El servicio anterior conserva lectura; Aplicar no permite guardar.' ).
    out->write( 'Crear/publicar YBD_DM_MNT_O4 para YUI_DM_MNT_O4 como OData V4 - UI.' ).
    out->write( 'Preview: Campos, Secciones o Flujos. No se modificaron datos de negocio.' ).
  ENDMETHOD.
ENDCLASS.

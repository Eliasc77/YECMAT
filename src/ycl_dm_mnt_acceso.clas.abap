CLASS ycl_dm_mnt_acceso DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS habilitado RETURNING VALUE(permitido) TYPE abap_bool.
ENDCLASS.
CLASS ycl_dm_mnt_acceso IMPLEMENTATION.
  METHOD habilitado.
    IF ycl_dm_cfg_store=>can_maintain( ) = abap_false. RETURN. ENDIF.
    SELECT SINGLE rap_activo FROM ymmt_dm_cfg_ctl
      WHERE config_id = @yif_dm_constants=>c_configuracion-id_global INTO @permitido.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Seccion DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS precheck_create FOR PRECHECK IMPORTING entities FOR CREATE Seccion.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Seccion RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK Seccion.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Seccion RESULT result.
    METHODS validar FOR VALIDATE ON SAVE IMPORTING keys FOR Seccion~validar.
ENDCLASS.
CLASS lhc_Seccion IMPLEMENTATION.
  METHOD precheck_create.
    SET LOCKS OF yi_dm_cfg ENTITY Configuration
      FROM VALUE #( ( ConfigId = yif_dm_constants=>c_configuracion-id_global ) )
      FAILED DATA(fallos) REPORTED DATA(mensajes_bloqueo).
    IF fallos IS NOT INITIAL OR ycl_dm_mnt_acceso=>habilitado( ) = abap_false.
      LOOP AT entities INTO DATA(entity).
        APPEND VALUE #( %cid = entity-%cid ) TO failed-seccion.
        APPEND VALUE #( %cid = entity-%cid %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Mantenimiento no habilitado o configuracion bloqueada por otro usuario' ) ) TO reported-seccion.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF yi_dm_m_seccion IN LOCAL MODE ENTITY Seccion
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    DATA(datos) = ycl_dm_cfg_store=>read_state( ).
    LOOP AT filas INTO DATA(fila).
      DATA(protegido) = ycl_dm_mnt_model=>seccion_protegida( datos = datos seccion = fila-SeccionId ).
      APPEND VALUE #( %tky = fila-%tky
        %update = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    "_ Durante la transicion se comparte el bloqueo del mantenimiento anterior.
    SET LOCKS OF yi_dm_cfg ENTITY Configuration
      FROM VALUE #( ( ConfigId = yif_dm_constants=>c_configuracion-id_global ) )
      FAILED DATA(fallos) REPORTED DATA(mensajes_bloqueo).
    IF fallos-configuration IS NOT INITIAL.
      LOOP AT keys INTO DATA(key).
        APPEND VALUE #( %tky = key-%tky ) TO failed-seccion.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Otro usuario esta modificando la configuracion; reintentar' ) ) TO reported-seccion.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
  METHOD get_global_authorizations.
    DATA(permiso) = COND #( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_true
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = permiso %update = permiso ).
  ENDMETHOD.
  METHOD validar.
    READ ENTITIES OF yi_dm_m_seccion IN LOCAL MODE ENTITY Seccion
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(anterior) = ycl_dm_cfg_store=>read_state( ).
      DATA(propuesto) = anterior.
      DELETE propuesto-secciones WHERE seccion_id = fila-SeccionId.
      APPEND VALUE #( mandt = sy-mandt
        seccion_id = fila-SeccionId
        descripcion = fila-Descripcion
        orden = fila-Orden
        activo = fila-Activo
      ) TO propuesto-secciones.
      DATA(error) = ycl_dm_mnt_trans=>registrar(
        raiz = CONV string( yif_dm_constants=>c_entidad_config-secciones )
        clave = CONV string( fila-SeccionId ) ).
      IF error IS INITIAL.
        error = COND string( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_false
          THEN 'El mantenimiento RAP no esta habilitado o no tiene acceso'
          ELSE ycl_dm_mnt_model=>validar( anterior = anterior propuesto = propuesto ) ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = fila-%tky ) TO failed-seccion.
        APPEND VALUE #( %tky = fila-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-seccion.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_mantenimiento DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.
CLASS lsc_mantenimiento IMPLEMENTATION.
  METHOD save_modified.
    "_ La persistencia la realiza RAP managed; solo se limpia el contexto de la LUW.
    ycl_dm_mnt_trans=>limpiar( ).
  ENDMETHOD.
  METHOD cleanup.
    ycl_dm_mnt_trans=>limpiar( ).
  ENDMETHOD.
  METHOD cleanup_finalize.
    ycl_dm_mnt_trans=>limpiar( ).
  ENDMETHOD.
ENDCLASS.

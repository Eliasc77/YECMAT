CLASS lhc_Campo DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS precheck_create FOR PRECHECK IMPORTING entities FOR CREATE Campo.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Campo RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK Campo.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Campo RESULT result.
    METHODS validar FOR VALIDATE ON SAVE IMPORTING keys FOR Campo~validar.
ENDCLASS.
CLASS lhc_Campo IMPLEMENTATION.
  METHOD precheck_create.
    SET LOCKS OF yi_dm_cfg ENTITY Configuration
      FROM VALUE #( ( ConfigId = yif_dm_constants=>c_configuracion-id_global ) )
      FAILED DATA(fallos) REPORTED DATA(mensajes_bloqueo).
    IF fallos IS NOT INITIAL OR ycl_dm_mnt_acceso=>habilitado( ) = abap_false.
      LOOP AT entities INTO DATA(entity).
        APPEND VALUE #( %cid = entity-%cid ) TO failed-campo.
        APPEND VALUE #( %cid = entity-%cid %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Mantenimiento no habilitado o configuracion bloqueada por otro usuario' ) ) TO reported-campo.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF yi_dm_m_campo IN LOCAL MODE ENTITY Campo
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    DATA(datos) = ycl_dm_cfg_store=>read_state( ).
    LOOP AT filas INTO DATA(fila).
      DATA(protegido) = ycl_dm_mnt_model=>campo_protegido( datos = datos campo = fila-CampoId ).
      APPEND VALUE #( %tky = fila-%tky
        %field-Descripcion = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-TablaSap = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-CampoSap = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-TipoSegmento = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-TipoDato = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-TipoControl = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-Longitud = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-Decimales = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-Activo = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
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
        APPEND VALUE #( %tky = key-%tky ) TO failed-campo.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Otro usuario esta modificando la configuracion; reintentar' ) ) TO reported-campo.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
  METHOD get_global_authorizations.
    DATA(permiso) = COND #( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_true
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = permiso %update = permiso ).
  ENDMETHOD.
  METHOD validar.
    READ ENTITIES OF yi_dm_m_campo IN LOCAL MODE ENTITY Campo
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(anterior) = ycl_dm_cfg_store=>read_state( ).
      DATA(propuesto) = anterior.
      DELETE propuesto-campos WHERE campo_id = fila-CampoId.
      APPEND VALUE #( mandt = sy-mandt
        campo_id = fila-CampoId
        descripcion = fila-Descripcion
        tabla_sap = fila-TablaSap
        campo_sap = fila-CampoSap
        tipo_segmento = fila-TipoSegmento
        tipo_dato = fila-TipoDato
        longitud = fila-Longitud
        decimales = fila-Decimales
        ayuda_valores = fila-AyudaValores
        tipo_control = fila-TipoControl
        activo = fila-Activo
      ) TO propuesto-campos.
      DATA(error) = ycl_dm_mnt_trans=>registrar(
        raiz = CONV string( yif_dm_constants=>c_entidad_config-campos )
        clave = CONV string( fila-CampoId ) ).
      IF error IS INITIAL.
        error = COND string( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_false
          THEN 'El mantenimiento RAP no esta habilitado o no tiene acceso'
          ELSE ycl_dm_mnt_model=>validar( anterior = anterior propuesto = propuesto ) ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = fila-%tky ) TO failed-campo.
        APPEND VALUE #( %tky = fila-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-campo.
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

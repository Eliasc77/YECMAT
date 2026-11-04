CLASS lcl_estado DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS leer IMPORTING flujo TYPE ymmt_dm_flujo-flujo_id borrador TYPE abp_behv_flag
      RETURNING VALUE(datos) TYPE ycl_dm_cfg_model=>ty_state.
ENDCLASS.
CLASS lcl_estado IMPLEMENTATION.
  METHOD leer.
    datos = ycl_dm_cfg_store=>read_state( ).
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE
      ENTITY Flujo ALL FIELDS WITH VALUE #( ( FlujoId = flujo %is_draft = borrador ) ) RESULT DATA(cabeceras)
      ENTITY Flujo BY \_Versiones ALL FIELDS
        WITH VALUE #( ( FlujoId = flujo %is_draft = borrador ) ) RESULT DATA(versiones).
    IF cabeceras IS INITIAL. RETURN. ENDIF.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE
      ENTITY Version BY \_Pasos ALL FIELDS WITH CORRESPONDING #( versiones ) RESULT DATA(pasos)
      ENTITY Version BY \_Reglas ALL FIELDS WITH CORRESPONDING #( versiones ) RESULT DATA(reglas).
    DELETE datos-flujos WHERE flujo_id = flujo.
    DELETE datos-versiones WHERE flujo_id = flujo.
    DELETE datos-pasos WHERE flujo_id = flujo.
    DELETE datos-reglas WHERE flujo_id = flujo.
    LOOP AT cabeceras INTO DATA(fila_flujo).
      APPEND VALUE #( mandt = sy-mandt
        flujo_id = fila_flujo-FlujoId
        descripcion = fila_flujo-Descripcion
        tipo_material = fila_flujo-TipoMaterial
        tipo_operacion = fila_flujo-TipoOperacion
        centro_criterio = fila_flujo-CentroCriterio
        activo = fila_flujo-Activo
      ) TO datos-flujos.
    ENDLOOP.
    LOOP AT versiones INTO DATA(fila_flujo_vr).
      APPEND VALUE #( mandt = sy-mandt
        flujo_id = fila_flujo_vr-FlujoId
        version = fila_flujo_vr-Version
        estado = fila_flujo_vr-Estado
        vigente_desde = fila_flujo_vr-VigenteDesde
        vigente_hasta = fila_flujo_vr-VigenteHasta
        creado_por = fila_flujo_vr-CreadoPor
        creado_el = fila_flujo_vr-CreadoEl
      ) TO datos-versiones.
    ENDLOOP.
    LOOP AT pasos INTO DATA(fila_paso).
      APPEND VALUE #( mandt = sy-mandt
        flujo_id = fila_paso-FlujoId
        version = fila_paso-Version
        paso_id = fila_paso-PasoId
        area = fila_paso-Area
        fase = fila_paso-Fase
        condicion_bpm = fila_paso-CondicionBpm
        orden = fila_paso-Orden
        obligatorio = fila_paso-Obligatorio
        activo = fila_paso-Activo
      ) TO datos-pasos.
    ENDLOOP.
    LOOP AT reglas INTO DATA(fila_regla).
      APPEND VALUE #( mandt = sy-mandt
        regla_uuid = fila_regla-ReglaUUID
        flujo_id = fila_regla-FlujoId
        version = fila_regla-Version
        area = fila_regla-Area
        campo_id = fila_regla-CampoId
        seccion_id = fila_regla-SeccionId
        estado_campo = fila_regla-EstadoCampo
        orden = fila_regla-Orden
        activo = fila_regla-Activo
      ) TO datos-reglas.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Flujo DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS precheck_create FOR PRECHECK IMPORTING entities FOR CREATE Flujo.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Flujo RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK Flujo.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Flujo RESULT result.
    METHODS validar FOR VALIDATE ON SAVE IMPORTING keys FOR Flujo~validar.
ENDCLASS.
CLASS lhc_Flujo IMPLEMENTATION.
  METHOD precheck_create.
    SET LOCKS OF yi_dm_cfg ENTITY Configuration
      FROM VALUE #( ( ConfigId = yif_dm_constants=>c_configuracion-id_global ) )
      FAILED DATA(fallos) REPORTED DATA(mensajes_bloqueo).
    IF fallos IS NOT INITIAL OR ycl_dm_mnt_acceso=>habilitado( ) = abap_false.
      LOOP AT entities INTO DATA(entity).
        APPEND VALUE #( %cid = entity-%cid ) TO failed-flujo.
        APPEND VALUE #( %cid = entity-%cid %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Mantenimiento no habilitado o configuracion bloqueada por otro usuario' ) ) TO reported-flujo.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Flujo
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    DATA(datos) = ycl_dm_cfg_store=>read_state( ).
    LOOP AT filas INTO DATA(fila).
      DATA(protegido) = ycl_dm_mnt_model=>flujo_protegido( datos = datos flujo = fila-FlujoId ).
      APPEND VALUE #( %tky = fila-%tky
        %field-Descripcion = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-TipoMaterial = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-TipoOperacion = COND #( WHEN protegido = abap_true
          THEN if_abap_behv=>fc-f-read_only ELSE if_abap_behv=>fc-f-unrestricted )
        %field-CentroCriterio = COND #( WHEN protegido = abap_true
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
        APPEND VALUE #( %tky = key-%tky ) TO failed-flujo.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Otro usuario esta modificando la configuracion; reintentar' ) ) TO reported-flujo.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
  METHOD get_global_authorizations.
    DATA(permiso) = COND #( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_true
      THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    result = VALUE #( %create = permiso %update = permiso ).
  ENDMETHOD.
  METHOD validar.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Flujo
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(anterior) = ycl_dm_cfg_store=>read_state( ).
      DATA(propuesto) = lcl_estado=>leer( flujo = fila-FlujoId borrador = fila-%is_draft ).
      DATA(error) = ycl_dm_mnt_trans=>registrar(
        raiz = CONV string( yif_dm_constants=>c_entidad_config-flujos )
        clave = CONV string( fila-FlujoId ) ).
      IF error IS INITIAL.
        error = COND string( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_false
          THEN 'El mantenimiento RAP no esta habilitado o no tiene acceso'
          ELSE ycl_dm_mnt_model=>validar( anterior = anterior propuesto = propuesto ) ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = fila-%tky ) TO failed-flujo.
        APPEND VALUE #( %tky = fila-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-flujo.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Version DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS iniciar FOR DETERMINE ON MODIFY IMPORTING keys FOR Version~iniciar.
    METHODS validar FOR VALIDATE ON SAVE IMPORTING keys FOR Version~validar.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Version RESULT result.
    METHODS Publicar FOR MODIFY IMPORTING keys FOR ACTION Version~Publicar RESULT result.
    METHODS Retirar FOR MODIFY IMPORTING keys FOR ACTION Version~Retirar RESULT result.
    METHODS Copiar FOR MODIFY IMPORTING keys FOR ACTION Version~Copiar RESULT result.
ENDCLASS.
CLASS lhc_Version IMPLEMENTATION.
  METHOD iniciar.
    GET TIME STAMP FIELD DATA(now).
    MODIFY ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
      UPDATE FIELDS ( Estado CreadoPor CreadoEl )
      WITH VALUE #( FOR key IN keys ( %tky = key-%tky
        Estado = yif_dm_constants=>c_estado_version-borrador
        CreadoPor = cl_abap_context_info=>get_user_technical_name( )
        CreadoEl = now
      ) ).
  ENDMETHOD.
  METHOD validar.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(anterior) = ycl_dm_cfg_store=>read_state( ).
      DATA(propuesto) = lcl_estado=>leer( flujo = fila-FlujoId borrador = fila-%is_draft ).
      DATA(error) = ycl_dm_mnt_trans=>registrar(
        raiz = CONV string( yif_dm_constants=>c_entidad_config-flujos )
        clave = CONV string( fila-FlujoId ) ).
      IF error IS INITIAL.
        error = COND string( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_false
          THEN 'El mantenimiento RAP no esta habilitado o no tiene acceso'
          ELSE ycl_dm_mnt_model=>validar( anterior = anterior propuesto = propuesto ) ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = fila-%tky ) TO failed-version.
        APPEND VALUE #( %tky = fila-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-version.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD get_instance_features.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    DATA(estado) = ycl_dm_cfg_store=>read_state( ).
    LOOP AT filas INTO DATA(fila).
      DATA(activa) = xsdbool( fila-%is_draft = if_abap_behv=>mk-off
        AND ycl_dm_mnt_acceso=>habilitado( ) = abap_true ).
      DATA(editable) = xsdbool( activa = abap_true
        AND fila-Estado = yif_dm_constants=>c_estado_version-borrador
        AND NOT line_exists( estado-used_versions[ flujo_id = fila-FlujoId version = fila-Version ] ) ).
      DATA(modificable) = ycl_dm_mnt_model=>version_editable(
        datos = estado flujo = fila-FlujoId version = fila-Version ).
      IF fila-%is_draft = if_abap_behv=>mk-on AND fila-Estado = yif_dm_constants=>c_estado_version-borrador
        AND NOT line_exists( estado-used_versions[ flujo_id = fila-FlujoId version = fila-Version ] ).
        modificable = abap_true.
      ENDIF.
      APPEND VALUE #( %tky = fila-%tky
        %field-VigenteDesde = COND #( WHEN modificable = abap_true
          THEN if_abap_behv=>fc-f-unrestricted ELSE if_abap_behv=>fc-f-read_only )
        %field-VigenteHasta = COND #( WHEN modificable = abap_true
          THEN if_abap_behv=>fc-f-unrestricted ELSE if_abap_behv=>fc-f-read_only )
        %assoc-_Pasos = COND #( WHEN modificable = abap_true
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %assoc-_Reglas = COND #( WHEN modificable = abap_true
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Publicar = COND #( WHEN editable = abap_true
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Retirar = COND #( WHEN activa = abap_true
          AND fila-Estado = yif_dm_constants=>c_estado_version-publicada
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Copiar = COND #( WHEN activa = abap_true
          THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD Publicar.
    LOOP AT keys INTO DATA(key).
      DATA(actual) = lcl_estado=>leer( flujo = key-FlujoId borrador = key-%is_draft ).
      DATA(command) = VALUE yd_dm_cfg_cmd(
        EntitySet = yif_dm_constants=>c_entidad_config-versiones
        Operation = yif_dm_constants=>c_operacion_config-publicar
        FlujoId = key-FlujoId Version = key-Version ).
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING error = DATA(error) ).
      IF key-%is_draft = if_abap_behv=>mk-on.
        error = 'Guardar los cambios antes de publicar'.
      ENDIF.
      IF ycl_dm_mnt_acceso=>habilitado( ) = abap_false.
        error = 'El mantenimiento RAP no esta habilitado o no tiene acceso'.
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = key-%tky ) TO failed-version.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-version.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
        UPDATE FIELDS ( Estado ) WITH VALUE #( ( %tky = key-%tky
          Estado = yif_dm_constants=>c_estado_version-publicada ) ) FAILED DATA(fallos).
      IF fallos IS NOT INITIAL.
        APPEND VALUE #( %tky = key-%tky ) TO failed-version.
      ENDIF.
    ENDLOOP.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    result = VALUE #( FOR fila IN filas ( %tky = fila-%tky %param = fila ) ).
  ENDMETHOD.

  METHOD Retirar.
    LOOP AT keys INTO DATA(key).
      DATA(actual) = lcl_estado=>leer( flujo = key-FlujoId borrador = key-%is_draft ).
      DATA(command) = VALUE yd_dm_cfg_cmd(
        EntitySet = yif_dm_constants=>c_entidad_config-versiones
        Operation = yif_dm_constants=>c_operacion_config-retirar
        FlujoId = key-FlujoId Version = key-Version ).
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING error = DATA(error) ).
      IF key-%is_draft = if_abap_behv=>mk-on.
        error = 'Guardar los cambios antes de retirar'.
      ENDIF.
      IF ycl_dm_mnt_acceso=>habilitado( ) = abap_false.
        error = 'El mantenimiento RAP no esta habilitado o no tiene acceso'.
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = key-%tky ) TO failed-version.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-version.
        CONTINUE.
      ENDIF.
      MODIFY ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
        UPDATE FIELDS ( Estado ) WITH VALUE #( ( %tky = key-%tky
          Estado = yif_dm_constants=>c_estado_version-retirada ) ) FAILED DATA(fallos).
      IF fallos IS NOT INITIAL. APPEND VALUE #( %tky = key-%tky ) TO failed-version. ENDIF.
    ENDLOOP.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    result = VALUE #( FOR fila IN filas ( %tky = fila-%tky %param = fila ) ).
  ENDMETHOD.

  METHOD Copiar.
    IF lines( keys ) <> 1.
      LOOP AT keys INTO DATA(invalida).
        APPEND VALUE #( %tky = invalida-%tky ) TO failed-version.
        APPEND VALUE #( %tky = invalida-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Seleccionar una sola version para copiar' ) ) TO reported-version.
      ENDLOOP.
      RETURN.
    ENDIF.
    LOOP AT keys INTO DATA(key).
      DATA(actual) = lcl_estado=>leer( flujo = key-FlujoId borrador = key-%is_draft ).
      DATA(command) = VALUE yd_dm_cfg_cmd(
        EntitySet = yif_dm_constants=>c_entidad_config-versiones
        Operation = yif_dm_constants=>c_operacion_config-copiar
        FlujoId = key-FlujoId Version = key-Version VersionDestino = key-%param-VersionDestino ).
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING next = DATA(copia) error = DATA(error) ).
      IF key-%is_draft = if_abap_behv=>mk-on.
        error = 'Guardar los cambios antes de copiar'.
      ENDIF.
      IF ycl_dm_mnt_acceso=>habilitado( ) = abap_false.
        error = 'El mantenimiento RAP no esta habilitado o no tiene acceso'.
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = key-%tky ) TO failed-version.
        APPEND VALUE #( %tky = key-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-version.
        CONTINUE.
      ENDIF.
      DATA(nueva) = copia-versiones[ flujo_id = key-FlujoId version = key-%param-VersionDestino ].
      DATA versiones TYPE TABLE FOR CREATE yi_dm_m_flujo\_Versiones.
      DATA pasos TYPE TABLE FOR CREATE yi_dm_m_flujo_vr\_Pasos.
      DATA reglas TYPE TABLE FOR CREATE yi_dm_m_flujo_vr\_Reglas.
      versiones = VALUE #( ( FlujoId = key-FlujoId %is_draft = if_abap_behv=>mk-off
        %target = VALUE #( ( %cid = 'COPIA_VERSION' Version = nueva-version
          VigenteDesde = nueva-vigente_desde VigenteHasta = nueva-vigente_hasta ) ) ) ).
      pasos = VALUE #( ( %cid_ref = 'COPIA_VERSION' %is_draft = if_abap_behv=>mk-off ) ).
      reglas = VALUE #( ( %cid_ref = 'COPIA_VERSION' %is_draft = if_abap_behv=>mk-off ) ).
      LOOP AT copia-pasos INTO DATA(paso) WHERE flujo_id = key-FlujoId AND version = nueva-version.
        APPEND VALUE #( %cid = |PASO_{ sy-tabix }| PasoId = paso-paso_id Area = paso-area
          Fase = paso-fase CondicionBpm = paso-condicion_bpm Orden = paso-orden
          Obligatorio = paso-obligatorio Activo = paso-activo ) TO pasos[ 1 ]-%target.
      ENDLOOP.
      LOOP AT copia-reglas INTO DATA(regla) WHERE flujo_id = key-FlujoId AND version = nueva-version.
        APPEND VALUE #( %cid = |REGLA_{ sy-tabix }| Area = regla-area CampoId = regla-campo_id
          SeccionId = regla-seccion_id EstadoCampo = regla-estado_campo Orden = regla-orden
          Activo = regla-activo ) TO reglas[ 1 ]-%target.
      ENDLOOP.
      "_ Una sola operacion EML enlaza version, pasos y reglas por sus CID.
      MODIFY ENTITIES OF yi_dm_m_flujo IN LOCAL MODE
        ENTITY Flujo CREATE BY \_Versiones FIELDS ( Version VigenteDesde VigenteHasta ) WITH versiones
        ENTITY Version CREATE BY \_Pasos
          FIELDS ( PasoId Area Fase CondicionBpm Orden Obligatorio Activo ) WITH pasos
        ENTITY Version CREATE BY \_Reglas
          FIELDS ( Area CampoId SeccionId EstadoCampo Orden Activo ) WITH reglas
        FAILED DATA(fallos).
      IF fallos IS NOT INITIAL. APPEND VALUE #( %tky = key-%tky ) TO failed-version. ENDIF.
    ENDLOOP.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Version
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    result = VALUE #( FOR fila IN filas ( %tky = fila-%tky %param = fila ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Paso DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Paso RESULT result.
    METHODS validar FOR VALIDATE ON SAVE IMPORTING keys FOR Paso~validar.
ENDCLASS.
CLASS lhc_Paso IMPLEMENTATION.
  METHOD get_instance_features.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Paso
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(datos) = lcl_estado=>leer( flujo = fila-FlujoId borrador = fila-%is_draft ).
      DATA(editable) = ycl_dm_mnt_model=>version_editable(
        datos = datos flujo = fila-FlujoId version = fila-Version ).
      APPEND VALUE #( %tky = fila-%tky %update = COND #( WHEN editable = abap_true
        THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD validar.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Paso
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(anterior) = ycl_dm_cfg_store=>read_state( ).
      DATA(propuesto) = lcl_estado=>leer( flujo = fila-FlujoId borrador = fila-%is_draft ).
      DATA(error) = ycl_dm_mnt_trans=>registrar(
        raiz = CONV string( yif_dm_constants=>c_entidad_config-flujos )
        clave = CONV string( fila-FlujoId ) ).
      IF error IS INITIAL.
        error = COND string( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_false
          THEN 'El mantenimiento RAP no esta habilitado o no tiene acceso'
          ELSE ycl_dm_mnt_model=>validar( anterior = anterior propuesto = propuesto ) ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = fila-%tky ) TO failed-paso.
        APPEND VALUE #( %tky = fila-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-paso.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_Regla DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Regla RESULT result.
    METHODS validar FOR VALIDATE ON SAVE IMPORTING keys FOR Regla~validar.
ENDCLASS.
CLASS lhc_Regla IMPLEMENTATION.
  METHOD get_instance_features.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Regla
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(datos) = lcl_estado=>leer( flujo = fila-FlujoId borrador = fila-%is_draft ).
      DATA(editable) = ycl_dm_mnt_model=>version_editable(
        datos = datos flujo = fila-FlujoId version = fila-Version ).
      APPEND VALUE #( %tky = fila-%tky %update = COND #( WHEN editable = abap_true
        THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled ) ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD validar.
    READ ENTITIES OF yi_dm_m_flujo IN LOCAL MODE ENTITY Regla
      ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(filas).
    LOOP AT filas INTO DATA(fila).
      DATA(anterior) = ycl_dm_cfg_store=>read_state( ).
      DATA(propuesto) = lcl_estado=>leer( flujo = fila-FlujoId borrador = fila-%is_draft ).
      DATA(error) = ycl_dm_mnt_trans=>registrar(
        raiz = CONV string( yif_dm_constants=>c_entidad_config-flujos )
        clave = CONV string( fila-FlujoId ) ).
      IF error IS INITIAL.
        error = COND string( WHEN ycl_dm_mnt_acceso=>habilitado( ) = abap_false
          THEN 'El mantenimiento RAP no esta habilitado o no tiene acceso'
          ELSE ycl_dm_mnt_model=>validar( anterior = anterior propuesto = propuesto ) ).
      ENDIF.
      IF error IS NOT INITIAL.
        APPEND VALUE #( %tky = fila-%tky ) TO failed-regla.
        APPEND VALUE #( %tky = fila-%tky %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error text = error ) ) TO reported-regla.
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

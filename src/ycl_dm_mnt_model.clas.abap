CLASS ycl_dm_mnt_model DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS validar_responsable IMPORTING datos TYPE ycl_dm_cfg_model=>ty_state
      flujo TYPE ymmt_dm_flujo-flujo_id version TYPE i RETURNING VALUE(error) TYPE string.
    CLASS-METHODS version_editable IMPORTING datos TYPE ycl_dm_cfg_model=>ty_state
      flujo TYPE ymmt_dm_flujo-flujo_id version TYPE i RETURNING VALUE(editable) TYPE abap_bool.
    CLASS-METHODS campo_protegido IMPORTING datos TYPE ycl_dm_cfg_model=>ty_state
      campo TYPE ymmt_dm_campo-campo_id RETURNING VALUE(protegido) TYPE abap_bool.
    CLASS-METHODS seccion_protegida IMPORTING datos TYPE ycl_dm_cfg_model=>ty_state
      seccion TYPE ymmt_dm_seccion-seccion_id RETURNING VALUE(protegida) TYPE abap_bool.
    CLASS-METHODS flujo_protegido IMPORTING datos TYPE ycl_dm_cfg_model=>ty_state
      flujo TYPE ymmt_dm_flujo-flujo_id RETURNING VALUE(protegido) TYPE abap_bool.
    CLASS-METHODS normalizar IMPORTING datos TYPE ycl_dm_cfg_model=>ty_state
      RETURNING VALUE(resultado) TYPE ycl_dm_cfg_model=>ty_state.
    CLASS-METHODS validar IMPORTING anterior TYPE ycl_dm_cfg_model=>ty_state
      propuesto TYPE ycl_dm_cfg_model=>ty_state RETURNING VALUE(error) TYPE string.
ENDCLASS.

CLASS ycl_dm_mnt_model IMPLEMENTATION.
  METHOD validar_responsable.
    LOOP AT datos-reglas INTO DATA(regla) WHERE flujo_id = flujo AND version = version AND activo = abap_true.
      IF regla-estado_campo <> yif_dm_constants=>c_estado_campo-obligatorio
        AND regla-estado_campo <> yif_dm_constants=>c_estado_campo-opcional. CONTINUE. ENDIF.
      LOOP AT datos-reglas INTO DATA(otra) WHERE flujo_id = flujo AND version = version
        AND campo_id = regla-campo_id AND area <> regla-area AND activo = abap_true.
        IF otra-estado_campo = yif_dm_constants=>c_estado_campo-obligatorio
          OR otra-estado_campo = yif_dm_constants=>c_estado_campo-opcional.
          error = |El campo { regla-campo_id } tiene mas de un area responsable de captura|. RETURN.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
  METHOD version_editable.
    READ TABLE datos-versiones WITH KEY flujo_id = flujo version = version INTO DATA(fila).
    editable = xsdbool( sy-subrc = 0 AND fila-estado = yif_dm_constants=>c_estado_version-borrador
      AND NOT line_exists( datos-used_versions[ flujo_id = flujo version = version ] ) ).
  ENDMETHOD.
  METHOD campo_protegido.
    IF line_exists( datos-used_fields[ table_line = campo ] ). protegido = abap_true. RETURN. ENDIF.
    LOOP AT datos-reglas INTO DATA(regla) WHERE campo_id = campo.
      IF version_editable( datos = datos flujo = regla-flujo_id version = regla-version ) = abap_false.
        protegido = abap_true. RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD seccion_protegida.
    LOOP AT datos-reglas INTO DATA(regla) WHERE seccion_id = seccion.
      IF version_editable( datos = datos flujo = regla-flujo_id version = regla-version ) = abap_false.
        protegida = abap_true. RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
  METHOD flujo_protegido.
    LOOP AT datos-versiones INTO DATA(fila) WHERE flujo_id = flujo.
      IF version_editable( datos = datos flujo = flujo version = fila-version ) = abap_false.
        protegido = abap_true. RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD normalizar.
    resultado = datos.
    LOOP AT resultado-campos ASSIGNING FIELD-SYMBOL(<campo>).
      CLEAR: <campo>-last_changed_at, <campo>-local_last_changed_at.
    ENDLOOP.
    LOOP AT resultado-secciones ASSIGNING FIELD-SYMBOL(<seccion>).
      CLEAR: <seccion>-last_changed_at, <seccion>-local_last_changed_at.
    ENDLOOP.
    LOOP AT resultado-flujos ASSIGNING FIELD-SYMBOL(<flujo>).
      CLEAR: <flujo>-last_changed_at, <flujo>-local_last_changed_at.
    ENDLOOP.
    LOOP AT resultado-versiones ASSIGNING FIELD-SYMBOL(<flujo_vr>).
      CLEAR: <flujo_vr>-last_changed_at, <flujo_vr>-local_last_changed_at.
    ENDLOOP.
    LOOP AT resultado-pasos ASSIGNING FIELD-SYMBOL(<paso>).
      CLEAR: <paso>-last_changed_at, <paso>-local_last_changed_at.
    ENDLOOP.
    LOOP AT resultado-reglas ASSIGNING FIELD-SYMBOL(<regla>).
      CLEAR: <regla>-last_changed_at, <regla>-local_last_changed_at.
    ENDLOOP.
  ENDMETHOD.

  METHOD validar.
    DATA(actual) = normalizar( anterior ).
    DATA(destino) = normalizar( propuesto ).
    DATA(origen) = actual.
    DATA command TYPE yd_dm_cfg_cmd.
    DATA(next) = actual.
    "_ No se admite borrar registros: conservar historial y desactivar cuando aplique.
    LOOP AT origen-campos INTO DATA(fila_campo).
      IF NOT line_exists( destino-campos[ campo_id = fila_campo-campo_id ] ).
        error = 'No se permite eliminar configuracion existente'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT destino-campos INTO fila_campo.
      READ TABLE origen-campos WITH KEY campo_id = fila_campo-campo_id INTO DATA(previo_campo).
      DATA(nuevo_campo) = xsdbool( sy-subrc <> 0 ).
      IF nuevo_campo = abap_false AND previo_campo = fila_campo. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-campos.
      command-Operation = COND #( WHEN nuevo_campo = abap_true
        THEN yif_dm_constants=>c_operacion_config-crear ELSE yif_dm_constants=>c_operacion_config-guardar ).
      command-CampoId = fila_campo-campo_id.
      command-Descripcion = fila_campo-descripcion.
      command-TablaSap = fila_campo-tabla_sap.
      command-CampoSap = fila_campo-campo_sap.
      command-TipoSegmento = fila_campo-tipo_segmento.
      command-TipoDato = fila_campo-tipo_dato.
      command-Longitud = fila_campo-longitud.
      command-Decimales = fila_campo-decimales.
      command-AyudaValores = fila_campo-ayuda_valores.
      command-TipoControl = fila_campo-tipo_control.
      command-Activo = fila_campo-activo.
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
    "_ No se admite borrar registros: conservar historial y desactivar cuando aplique.
    LOOP AT origen-secciones INTO DATA(fila_seccion).
      IF NOT line_exists( destino-secciones[ seccion_id = fila_seccion-seccion_id ] ).
        error = 'No se permite eliminar configuracion existente'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT destino-secciones INTO fila_seccion.
      READ TABLE origen-secciones WITH KEY seccion_id = fila_seccion-seccion_id INTO DATA(previo_seccion).
      DATA(nuevo_seccion) = xsdbool( sy-subrc <> 0 ).
      IF nuevo_seccion = abap_false AND previo_seccion = fila_seccion. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-secciones.
      command-Operation = COND #( WHEN nuevo_seccion = abap_true
        THEN yif_dm_constants=>c_operacion_config-crear ELSE yif_dm_constants=>c_operacion_config-guardar ).
      command-SeccionId = fila_seccion-seccion_id.
      command-Descripcion = fila_seccion-descripcion.
      command-Orden = fila_seccion-orden.
      command-Activo = fila_seccion-activo.
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
    "_ No se admite borrar registros: conservar historial y desactivar cuando aplique.
    LOOP AT origen-flujos INTO DATA(fila_flujo).
      IF NOT line_exists( destino-flujos[ flujo_id = fila_flujo-flujo_id ] ).
        error = 'No se permite eliminar configuracion existente'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT destino-flujos INTO fila_flujo.
      READ TABLE origen-flujos WITH KEY flujo_id = fila_flujo-flujo_id INTO DATA(previo_flujo).
      DATA(nuevo_flujo) = xsdbool( sy-subrc <> 0 ).
      IF nuevo_flujo = abap_false AND previo_flujo = fila_flujo. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-flujos.
      command-Operation = COND #( WHEN nuevo_flujo = abap_true
        THEN yif_dm_constants=>c_operacion_config-crear ELSE yif_dm_constants=>c_operacion_config-guardar ).
      command-FlujoId = fila_flujo-flujo_id.
      command-Descripcion = fila_flujo-descripcion.
      command-TipoMaterial = fila_flujo-tipo_material.
      command-TipoOperacion = fila_flujo-tipo_operacion.
      command-CentroCriterio = fila_flujo-centro_criterio.
      command-Activo = fila_flujo-activo.
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
    "_ No se admite borrar registros: conservar historial y desactivar cuando aplique.
    LOOP AT origen-versiones INTO DATA(fila_flujo_vr).
      IF NOT line_exists( destino-versiones[ flujo_id = fila_flujo_vr-flujo_id version = fila_flujo_vr-version ] ).
        error = 'No se permite eliminar configuracion existente'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT destino-versiones INTO fila_flujo_vr.
      READ TABLE origen-versiones WITH KEY flujo_id = fila_flujo_vr-flujo_id version = fila_flujo_vr-version INTO
        DATA(previo_flujo_vr).
      DATA(nuevo_flujo_vr) = xsdbool( sy-subrc <> 0 ).
      IF nuevo_flujo_vr = abap_true AND fila_flujo_vr-estado <> yif_dm_constants=>c_estado_version-borrador.
        error = 'Una version nueva debe iniciar en BORRADOR'. RETURN.
      ENDIF.
      IF nuevo_flujo_vr = abap_false AND fila_flujo_vr-vigente_desde = previo_flujo_vr-vigente_desde
        AND fila_flujo_vr-vigente_hasta = previo_flujo_vr-vigente_hasta. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-versiones.
      command-Operation = COND #( WHEN nuevo_flujo_vr = abap_true
        THEN yif_dm_constants=>c_operacion_config-crear ELSE yif_dm_constants=>c_operacion_config-guardar ).
      command-FlujoId = fila_flujo_vr-flujo_id.
      command-Version = fila_flujo_vr-version.
      command-VigenteDesde = fila_flujo_vr-vigente_desde.
      command-VigenteHasta = fila_flujo_vr-vigente_hasta.
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
    "_ No se admite borrar registros: conservar historial y desactivar cuando aplique.
    LOOP AT origen-pasos INTO DATA(fila_paso).
      IF NOT line_exists( destino-pasos[ flujo_id = fila_paso-flujo_id version = fila_paso-version paso_id =
        fila_paso-paso_id ] ).
        error = 'No se permite eliminar configuracion existente'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT destino-pasos INTO fila_paso.
      READ TABLE origen-pasos WITH KEY flujo_id = fila_paso-flujo_id version = fila_paso-version paso_id =
        fila_paso-paso_id INTO DATA(previo_paso).
      DATA(nuevo_paso) = xsdbool( sy-subrc <> 0 ).
      IF nuevo_paso = abap_false AND previo_paso = fila_paso. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-pasos.
      command-Operation = COND #( WHEN nuevo_paso = abap_true
        THEN yif_dm_constants=>c_operacion_config-crear ELSE yif_dm_constants=>c_operacion_config-guardar ).
      command-FlujoId = fila_paso-flujo_id.
      command-Version = fila_paso-version.
      command-PasoId = fila_paso-paso_id.
      command-Area = fila_paso-area.
      command-Fase = fila_paso-fase.
      command-CondicionBpm = fila_paso-condicion_bpm.
      command-Orden = fila_paso-orden.
      command-Obligatorio = fila_paso-obligatorio.
      command-Activo = fila_paso-activo.
      DATA(contexto_paso) = actual.
      DELETE contexto_paso-pasos WHERE flujo_id = fila_paso-flujo_id AND version = fila_paso-version.
      DELETE contexto_paso-reglas WHERE flujo_id = fila_paso-flujo_id AND version = fila_paso-version.
      LOOP AT destino-pasos INTO DATA(rel_paso_paso) WHERE flujo_id = fila_paso-flujo_id
        AND version = fila_paso-version.
        APPEND rel_paso_paso TO contexto_paso-pasos.
      ENDLOOP.
      LOOP AT destino-reglas INTO DATA(rel_regla_paso) WHERE flujo_id = fila_paso-flujo_id
        AND version = fila_paso-version.
        APPEND rel_regla_paso TO contexto_paso-reglas.
      ENDLOOP.
      DELETE contexto_paso-pasos WHERE flujo_id = fila_paso-flujo_id AND version = fila_paso-version
        AND paso_id = fila_paso-paso_id.
      IF nuevo_paso = abap_false. APPEND previo_paso TO contexto_paso-pasos. ENDIF.
      ycl_dm_cfg_model=>plan( EXPORTING current = contexto_paso command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
    "_ No se admite borrar registros: conservar historial y desactivar cuando aplique.
    LOOP AT origen-reglas INTO DATA(fila_regla).
      IF NOT line_exists( destino-reglas[ regla_uuid = fila_regla-regla_uuid ] ).
        error = 'No se permite eliminar configuracion existente'. RETURN.
      ENDIF.
    ENDLOOP.
    LOOP AT destino-reglas INTO fila_regla.
      READ TABLE origen-reglas WITH KEY regla_uuid = fila_regla-regla_uuid INTO DATA(previo_regla).
      DATA(nuevo_regla) = xsdbool( sy-subrc <> 0 ).
      IF nuevo_regla = abap_false AND previo_regla = fila_regla. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-reglas.
      command-Operation = COND #( WHEN nuevo_regla = abap_true
        THEN yif_dm_constants=>c_operacion_config-crear ELSE yif_dm_constants=>c_operacion_config-guardar ).
      command-FlujoId = fila_regla-flujo_id.
      command-Version = fila_regla-version.
      command-Area = fila_regla-area.
      command-CampoId = fila_regla-campo_id.
      command-SeccionId = fila_regla-seccion_id.
      command-EstadoCampo = fila_regla-estado_campo.
      command-Orden = fila_regla-orden.
      command-Activo = fila_regla-activo.
      DATA(contexto_regla) = actual.
      DELETE contexto_regla-pasos WHERE flujo_id = fila_regla-flujo_id AND version = fila_regla-version.
      DELETE contexto_regla-reglas WHERE flujo_id = fila_regla-flujo_id AND version = fila_regla-version.
      LOOP AT destino-pasos INTO DATA(rel_paso_regla) WHERE flujo_id = fila_regla-flujo_id
        AND version = fila_regla-version.
        APPEND rel_paso_regla TO contexto_regla-pasos.
      ENDLOOP.
      LOOP AT destino-reglas INTO DATA(rel_regla_regla) WHERE flujo_id = fila_regla-flujo_id
        AND version = fila_regla-version.
        APPEND rel_regla_regla TO contexto_regla-reglas.
      ENDLOOP.
      DELETE contexto_regla-reglas WHERE regla_uuid = fila_regla-regla_uuid.
      IF nuevo_regla = abap_false. APPEND previo_regla TO contexto_regla-reglas. ENDIF.
      ycl_dm_cfg_model=>plan( EXPORTING current = contexto_regla command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
    "_ Los cambios de estado se validan despues de los pasos y reglas del mismo guardado.
    LOOP AT destino-versiones INTO DATA(version_final).
      READ TABLE actual-versiones WITH KEY flujo_id = version_final-flujo_id
        version = version_final-version INTO DATA(version_actual).
      IF sy-subrc <> 0. error = 'Version no encontrada'. RETURN. ENDIF.
      IF version_actual-estado = version_final-estado. CONTINUE. ENDIF.
      CLEAR command.
      command-EntitySet = yif_dm_constants=>c_entidad_config-versiones.
      command-FlujoId = version_final-flujo_id.
      command-Version = version_final-version.
      CASE version_final-estado.
        WHEN yif_dm_constants=>c_estado_version-publicada.
          error = validar_responsable( datos = actual flujo = version_final-flujo_id
            version = version_final-version ).
          IF error IS NOT INITIAL. RETURN. ENDIF.
          command-Operation = yif_dm_constants=>c_operacion_config-publicar.
        WHEN yif_dm_constants=>c_estado_version-retirada.
          command-Operation = yif_dm_constants=>c_operacion_config-retirar.
        WHEN OTHERS.
          error = 'Transicion de estado no permitida'. RETURN.
      ENDCASE.
      ycl_dm_cfg_model=>plan( EXPORTING current = actual command = command
        IMPORTING next = next error = error ).
      IF error IS NOT INITIAL. RETURN. ENDIF.
      actual = next.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

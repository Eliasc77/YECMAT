
CLASS ycl_dm_cfg_model DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES: BEGIN OF ty_version_key,
             flujo_id TYPE ymmt_dm_flujo-flujo_id,
             version  TYPE ymmt_dm_flujo_vr-version,
           END OF ty_version_key.

    TYPES: BEGIN OF ty_state,
             campos        TYPE STANDARD TABLE OF ymmt_dm_campo WITH EMPTY KEY,
             secciones     TYPE STANDARD TABLE OF ymmt_dm_seccion WITH EMPTY KEY,
             flujos        TYPE STANDARD TABLE OF ymmt_dm_flujo WITH EMPTY KEY,
             versiones     TYPE STANDARD TABLE OF ymmt_dm_flujo_vr WITH EMPTY KEY,
             pasos         TYPE STANDARD TABLE OF ymmt_dm_paso WITH EMPTY KEY,
             reglas        TYPE STANDARD TABLE OF ymmt_dm_regla WITH EMPTY KEY,
             used_versions TYPE STANDARD TABLE OF ty_version_key WITH EMPTY KEY,
             used_fields   TYPE SORTED TABLE OF ymmt_dm_campo-campo_id WITH UNIQUE KEY table_line,
           END OF ty_state.

    CLASS-METHODS plan
      IMPORTING
        current TYPE ty_state
        command TYPE yd_dm_cfg_cmd
      EXPORTING
        next    TYPE ty_state
        error   TYPE string.

    CLASS-METHODS validate_version
      IMPORTING
                state        TYPE ty_state
                flow         TYPE ymmt_dm_flujo-flujo_id
                version      TYPE i
      RETURNING VALUE(error) TYPE string.

  PRIVATE SECTION.

    CLASS-METHODS valid_id
      IMPORTING value        TYPE clike
      RETURNING VALUE(valid) TYPE abap_bool.

    CLASS-METHODS valid_date
      IMPORTING value        TYPE clike
      RETURNING VALUE(valid) TYPE abap_bool.

    CLASS-METHODS editable
      IMPORTING
                state          TYPE ty_state
                flow           TYPE ymmt_dm_flujo-flujo_id
                version        TYPE i
      RETURNING VALUE(allowed) TYPE abap_bool.

ENDCLASS.


CLASS ycl_dm_cfg_model IMPLEMENTATION.

  METHOD valid_id.

    valid = xsdbool(
      value IS NOT INITIAL
      AND matches(
        val   = CONV string( value )
        regex = '^[A-Z0-9\_]+$'
      )
    ).

  ENDMETHOD.


  METHOD valid_date.

    DATA text TYPE string.

    text = value.

    IF strlen( text ) <> 8
       OR text CN '0123456789'
       OR text(4) = '0000'.
      RETURN.
    ENDIF.

    DATA(year)  = CONV i( text(4) ).
    DATA(month) = CONV i( text+4(2) ).
    DATA(day)   = CONV i( text+6(2) ).

    IF month < 1 OR month > 12 OR day < 1.
      RETURN.
    ENDIF.

    DATA(days) = COND i(
      WHEN month = 2 THEN 28
      WHEN month = 4 OR month = 6 OR month = 9 OR month = 11 THEN 30
      ELSE 31
    ).

    IF month = 2 AND
       ( year MOD 400 = 0 OR
       ( year MOD 4 = 0 AND year MOD 100 <> 0 ) ).
      days = 29.
    ENDIF.

    valid = xsdbool( day <= days ).

  ENDMETHOD.


  METHOD editable.

    READ TABLE state-versiones
      WITH KEY flujo_id = flow
               version  = version
      INTO DATA(row).

    allowed = xsdbool(
      sy-subrc = 0
      AND row-estado = 'BORRADOR'
      AND NOT line_exists(
        state-used_versions[
          flujo_id = flow
          version  = version
        ]
      )
    ).

  ENDMETHOD.


  METHOD plan.

    next = current.
    CLEAR error.

    IF command-Operation <> 'CREAR'
       AND command-Operation <> 'GUARDAR'
       AND command-Operation <> 'PUBLICAR'
       AND command-Operation <> 'RETIRAR'
       AND command-Operation <> 'COPIAR'.

      error = 'Operacion administrativa desconocida'.
      RETURN.

    ENDIF.

    IF command-EntitySet <> 'Versiones' AND
       command-Operation <> 'GUARDAR'   AND
       command-Operation <> 'CREAR'.

      error = 'La operacion solo se admite sobre versiones'.
      RETURN.

    ENDIF.

    IF command-Activo <> abap_true
       AND command-Activo <> abap_false.

      error = 'Activo debe ser booleano'.
      RETURN.

    ENDIF.

    DATA(exists) = abap_false.

    CASE command-EntitySet.

      WHEN 'Campos'.
        exists = xsdbool(
          line_exists(
            current-campos[ campo_id = command-CampoId ]
          )
        ).

      WHEN 'Secciones'.
        exists = xsdbool(
          line_exists(
            current-secciones[ seccion_id = command-SeccionId ]
          )
        ).

      WHEN 'Flujos'.
        exists = xsdbool(
          line_exists(
            current-flujos[ flujo_id = command-FlujoId ]
          )
        ).

      WHEN 'Versiones'.
        exists = xsdbool(
          line_exists(
            current-versiones[
              flujo_id = command-FlujoId
              version  = command-Version
            ]
          )
        ).

      WHEN 'Pasos'.
        exists = xsdbool(
          line_exists(
            current-pasos[
              flujo_id = command-FlujoId
              version  = command-Version
              paso_id  = command-PasoId
            ]
          )
        ).

      WHEN 'Reglas'.
        exists = xsdbool(
          line_exists(
            current-reglas[
              flujo_id = command-FlujoId
              version  = command-Version
              area     = command-Area
              campo_id = command-CampoId
            ]
          )
        ).

      WHEN OTHERS.
        error = 'Mantenimiento desconocido'.
        RETURN.

    ENDCASE.

    IF command-Operation = 'CREAR' AND exists = abap_true.
      error = 'Ya existe un registro con esa clave. Seleccionarlo y usar Editar'.
      RETURN.
    ENDIF.

    IF command-Operation <> 'CREAR' AND exists = abap_false.
      error = 'El registro no existe. Actualizar o usar Nuevo'.
      RETURN.
    ENDIF.

    TRY.

        CASE command-EntitySet.

          WHEN 'Campos'.

            IF valid_id( command-CampoId ) = abap_false
               OR command-Descripcion IS INITIAL
               OR valid_id( command-TablaSap ) = abap_false
               OR valid_id( command-CampoSap ) = abap_false.

              error = 'Campo: identificador, descripcion y mapeo SAP son obligatorios; usar claves en mayusculas'.
              RETURN.

            ENDIF.

            IF command-TipoSegmento <> 'GENERAL'
               AND command-TipoSegmento <> 'CENTRO'
               AND command-TipoSegmento <> 'ALMACEN'
               AND command-TipoSegmento <> 'VENTAS'
               AND command-TipoSegmento <> 'VALORACION'
               AND command-TipoSegmento <> 'UNIDAD'.

              error = 'Tipo de segmento desconocido'.
              RETURN.

            ENDIF.

            IF command-TipoDato <> 'CHAR'
               AND command-TipoDato <> 'STRING'
               AND command-TipoDato <> 'NUMC'
               AND command-TipoDato <> 'DEC'
               AND command-TipoDato <> 'CURR'
               AND command-TipoDato <> 'QUAN'
               AND command-TipoDato <> 'INT1'
               AND command-TipoDato <> 'INT2'
               AND command-TipoDato <> 'INT4'
               AND command-TipoDato <> 'DATS'
               AND command-TipoDato <> 'BOOL'
               AND command-TipoDato <> 'UNIT'
               AND command-TipoDato <> 'CUKY'
               AND command-TipoDato <> 'LANG'.

              error = 'Tipo de dato no soportado por la captura'.
              RETURN.

            ENDIF.

            IF command-Longitud < 1
               OR command-Longitud > 1333
               OR command-Decimales < 0
               OR command-Decimales > command-Longitud
               OR ( command-TipoDato <> 'DEC'
                    AND command-TipoDato <> 'CURR'
                    AND command-TipoDato <> 'QUAN'
                    AND command-Decimales <> 0 )
               OR ( command-TipoDato = 'DATS'
                    AND command-Longitud <> 8 )
               OR ( command-TipoDato = 'BOOL'
                    AND command-Longitud <> 1 ).

              error = 'Longitud o decimales incompatibles con el tipo de dato'.
              RETURN.

            ENDIF.

            IF command-TipoControl <> 'Input'
               AND command-TipoControl <> 'TextArea'
               AND command-TipoControl <> 'DatePicker'
               AND command-TipoControl <> 'CheckBox'
               AND command-TipoControl <> 'Decimal'
               AND command-TipoControl <> 'Integer'.

              error = 'Control de pantalla desconocido'.
              RETURN.

            ENDIF.

            DATA(field) = VALUE ymmt_dm_campo(
              mandt         = sy-mandt
              campo_id      = command-CampoId
              descripcion   = command-Descripcion
              tabla_sap     = command-TablaSap
              campo_sap     = command-CampoSap
              tipo_segmento = command-TipoSegmento
              tipo_dato     = command-TipoDato
              longitud      = command-Longitud
              decimales     = command-Decimales
              ayuda_valores = command-AyudaValores
              tipo_control  = command-TipoControl
              activo        = command-Activo
            ).

            READ TABLE next-campos
              WITH KEY campo_id = field-campo_id
              ASSIGNING FIELD-SYMBOL(<field>).

            IF sy-subrc = 0.

              IF <field> = field.
                RETURN.
              ENDIF.

              " Permitir cambiar solo la referencia de ayuda.
              DATA(field_comparison) = field.

              field_comparison-ayuda_valores = <field>-ayuda_valores.

              IF field_comparison = <field>.
                <field> = field.
                RETURN.
              ENDIF.


              IF line_exists(
                current-used_fields[
                  table_line = field-campo_id
                ]
              ).
                error = 'Campo con datos: crear otro CampoId para cambiar su definicion'.
                RETURN.
              ENDIF.

              LOOP AT current-reglas INTO DATA(reference)
                WHERE campo_id = field-campo_id.

                IF editable(
                  state   = current
                  flow    = reference-flujo_id
                  version = reference-version
                ) = abap_false.

                  error = 'Campo referenciado por una version publicada, retirada o usada: crear otro CampoId'.
                  RETURN.

                ENDIF.

              ENDLOOP.

              <field> = field.

            ELSE.

              APPEND field TO next-campos.

            ENDIF.


          WHEN 'Secciones'.

            IF valid_id( command-SeccionId ) = abap_false
               OR command-Descripcion IS INITIAL
               OR command-Orden < 0.

              error = 'Seccion: clave, descripcion y orden no negativo requeridos'.
              RETURN.

            ENDIF.

            DATA(section) = VALUE ymmt_dm_seccion(
              mandt       = sy-mandt
              seccion_id  = command-SeccionId
              descripcion = command-Descripcion
              orden       = command-Orden
              activo      = command-Activo
            ).

            READ TABLE next-secciones
              WITH KEY seccion_id = section-seccion_id
              ASSIGNING FIELD-SYMBOL(<section>).

            IF sy-subrc = 0.

              IF <section> = section.
                RETURN.
              ENDIF.

              LOOP AT current-reglas INTO reference
                WHERE seccion_id = section-seccion_id.

                IF editable(
                  state   = current
                  flow    = reference-flujo_id
                  version = reference-version
                ) = abap_false.

                  error = 'Seccion usada por una version protegida: crear otra SeccionId'.
                  RETURN.

                ENDIF.

              ENDLOOP.

              <section> = section.

            ELSE.

              APPEND section TO next-secciones.

            ENDIF.


          WHEN 'Flujos'.

            IF valid_id( command-FlujoId ) = abap_false
               OR command-Descripcion IS INITIAL
               OR valid_id( command-TipoMaterial ) = abap_false
               OR ( command-TipoOperacion <> 'C'
                    AND command-TipoOperacion <> 'M'
                    AND command-TipoOperacion <> 'I' )
               OR ( command-CentroCriterio IS NOT INITIAL
                    AND valid_id( command-CentroCriterio ) = abap_false ).

              error = 'Flujo: completar clave, descripcion, tipo de material y operacion C/M/I'.
              RETURN.

            ENDIF.

            DATA(flow) = VALUE ymmt_dm_flujo(
              mandt           = sy-mandt
              flujo_id        = command-FlujoId
              descripcion     = command-Descripcion
              tipo_material   = command-TipoMaterial
              tipo_operacion  = command-TipoOperacion
              centro_criterio = command-CentroCriterio
              activo          = command-Activo
            ).

            READ TABLE next-flujos
              WITH KEY flujo_id = flow-flujo_id
              ASSIGNING FIELD-SYMBOL(<flow>).

            IF sy-subrc = 0.

              DATA(frozen) = abap_false.

              IF line_exists(
                current-used_versions[
                  flujo_id = flow-flujo_id
                ]
              ).
                frozen = abap_true.
              ENDIF.

              LOOP AT current-versiones INTO DATA(version_row)
                WHERE flujo_id = flow-flujo_id.

                IF editable(
                  state   = current
                  flow    = version_row-flujo_id
                  version = version_row-version
                ) = abap_false.

                  frozen = abap_true.

                ENDIF.

              ENDLOOP.

              DATA(previous_flow) = <flow>.
              previous_flow-activo = flow-activo.

              IF frozen = abap_true AND previous_flow <> flow.

                error = 'Flujo publicado o usado: solo se permite activar/desactivar; crear otro flujo para cambiar criterios'.
                RETURN.

              ENDIF.

              <flow> = flow.

            ELSE.

              APPEND flow TO next-flujos.

            ENDIF.

            "Reactivating a flow must not introduce ambiguity with another active flow.
            IF flow-activo = abap_true.

              LOOP AT next-versiones INTO version_row
                WHERE flujo_id = flow-flujo_id
                  AND estado   = 'PUBLICADA'.

                error = validate_version(
                  state   = next
                  flow    = flow-flujo_id
                  version = version_row-version
                ).

                IF error IS NOT INITIAL.
                  RETURN.
                ENDIF.

              ENDLOOP.

            ENDIF.


          WHEN 'Versiones'.

            IF valid_id( command-FlujoId ) = abap_false
               OR command-Version < 1
               OR NOT line_exists(
                 current-flujos[
                   flujo_id = command-FlujoId
                 ]
               ).

              error = 'Version: flujo existente y numero positivo requeridos'.
              RETURN.

            ENDIF.

            READ TABLE next-versiones
              WITH KEY flujo_id = command-FlujoId
                       version  = command-Version
              ASSIGNING FIELD-SYMBOL(<version>).

            CASE command-Operation.

              WHEN 'CREAR' OR 'GUARDAR'.

                IF valid_date( command-VigenteDesde ) = abap_false
                   OR ( command-VigenteHasta IS NOT INITIAL
                        AND ( valid_date( command-VigenteHasta ) = abap_false
                              OR command-VigenteHasta < command-VigenteDesde ) ).

                  error = 'Vigencia invalida: desde obligatorio, hasta igual o posterior; fechas YYYYMMDD'.
                  RETURN.

                ENDIF.

                IF <version> IS ASSIGNED.

                  IF editable(
                    state   = current
                    flow    = command-FlujoId
                    version = command-Version
                  ) = abap_false.

                    error = 'Version protegida: copiar a una nueva version borrador'.
                    RETURN.

                  ENDIF.

                  <version>-vigente_desde = command-VigenteDesde.
                  <version>-vigente_hasta = command-VigenteHasta.

                ELSE.

                  GET TIME STAMP FIELD DATA(now).

                  APPEND VALUE #(
                    mandt         = sy-mandt
                    flujo_id      = command-FlujoId
                    version       = command-Version
                    estado        = 'BORRADOR'
                    vigente_desde = command-VigenteDesde
                    vigente_hasta = command-VigenteHasta
                    creado_por    = cl_abap_context_info=>get_user_technical_name( )
                    creado_el     = now
                  ) TO next-versiones.

                ENDIF.


              WHEN 'PUBLICAR'.

                IF <version> IS NOT ASSIGNED
                   OR editable(
                     state   = current
                     flow    = command-FlujoId
                     version = command-Version
                   ) = abap_false.

                  error = 'Solo se publica una version borrador sin solicitudes'.
                  RETURN.

                ENDIF.

                error = validate_version(
                  state   = current
                  flow    = command-FlujoId
                  version = command-Version
                ).

                IF error IS NOT INITIAL.
                  RETURN.
                ENDIF.

                <version>-estado = 'PUBLICADA'.


              WHEN 'RETIRAR'.

                IF <version> IS NOT ASSIGNED.
                  error = 'La version no existe'.
                  RETURN.
                ENDIF.

                IF <version>-estado <> 'PUBLICADA'.
                  error = 'Solo se retira una version publicada'.
                  RETURN.
                ENDIF.

                <version>-estado = 'RETIRADA'.


              WHEN 'COPIAR'.

                IF <version> IS NOT ASSIGNED
                   OR command-VersionDestino < 1
                   OR line_exists(
                     current-versiones[
                       flujo_id = command-FlujoId
                       version  = command-VersionDestino
                     ]
                   ).

                  error = 'Origen existente y version destino nueva positiva requeridos'.
                  RETURN.

                ENDIF.

                DATA(cloned_version) = <version>.

                cloned_version-version = command-VersionDestino.
                cloned_version-estado = 'BORRADOR'.
                cloned_version-creado_por = cl_abap_context_info=>get_user_technical_name( ).

                GET TIME STAMP FIELD cloned_version-creado_el.

                APPEND cloned_version TO next-versiones.

                LOOP AT current-pasos INTO DATA(cloned_step)
                  WHERE flujo_id = command-FlujoId
                    AND version  = command-Version.

                  cloned_step-version = command-VersionDestino.
                  APPEND cloned_step TO next-pasos.

                ENDLOOP.

                LOOP AT current-reglas INTO DATA(cloned_rule)
                  WHERE flujo_id = command-FlujoId
                    AND version  = command-Version.

                  cloned_rule-version = command-VersionDestino.
                  cloned_rule-regla_uuid = cl_system_uuid=>create_uuid_x16_static( ).

                  APPEND cloned_rule TO next-reglas.

                ENDLOOP.

            ENDCASE.


          WHEN 'Pasos'.

            IF editable(
              state   = current
              flow    = command-FlujoId
              version = command-Version
            ) = abap_false.

              error = 'Pasos editables solo en una version borrador sin solicitudes'.
              RETURN.

            ENDIF.

            IF valid_id( command-PasoId ) = abap_false
               OR valid_id( command-Area ) = abap_false
               OR command-Fase IS INITIAL
               OR command-Orden < 0
               OR ( command-CondicionBpm IS NOT INITIAL
                    AND command-CondicionBpm <> 'A'
                    AND command-CondicionBpm <> 'B' )
               OR ( command-Obligatorio <> abap_true
                    AND command-Obligatorio <> abap_false ).

              error = 'Paso: clave, area y fase requeridas; condicion A/B/vacia y orden no negativo'.
              RETURN.

            ENDIF.

            DATA(step) = VALUE ymmt_dm_paso(
              mandt         = sy-mandt
              flujo_id      = command-FlujoId
              version       = command-Version
              paso_id       = command-PasoId
              area          = command-Area
              fase          = command-Fase
              condicion_bpm = command-CondicionBpm
              orden         = command-Orden
              obligatorio   = command-Obligatorio
              activo        = command-Activo
            ).

            READ TABLE next-pasos
              WITH KEY flujo_id = step-flujo_id
                       version  = step-version
                       paso_id  = step-paso_id
              ASSIGNING FIELD-SYMBOL(<step>).

            IF sy-subrc = 0.
              <step> = step.
            ELSE.
              APPEND step TO next-pasos.
            ENDIF.

            LOOP AT next-reglas INTO reference
              WHERE flujo_id = step-flujo_id
                AND version  = step-version
                AND activo   = abap_true.

              IF NOT line_exists(
                next-pasos[
                  flujo_id = step-flujo_id
                  version  = step-version
                  area     = reference-area
                  activo   = abap_true
                ]
              ).

                error = 'No se puede dejar un area con reglas activas sin pasos activos'.
                RETURN.

              ENDIF.

            ENDLOOP.


          WHEN 'Reglas'.

            IF editable(
              state   = current
              flow    = command-FlujoId
              version = command-Version
            ) = abap_false.

              error = 'Reglas editables solo en una version borrador sin solicitudes'.
              RETURN.

            ENDIF.

            IF valid_id( command-Area ) = abap_false
               OR command-Orden < 0
               OR NOT line_exists(
                 current-campos[
                   campo_id = command-CampoId
                 ]
               )
               OR NOT line_exists(
                 current-secciones[
                   seccion_id = command-SeccionId
                 ]
               )
               OR ( command-EstadoCampo <> 'M'
                    AND command-EstadoCampo <> 'O'
                    AND command-EstadoCampo <> 'I'
                    AND command-EstadoCampo <> 'R' ).

              error = 'Regla: area, campo y seccion existentes, estado M/O/I/R y orden no negativo requeridos'.
              RETURN.

            ENDIF.

            IF command-Activo = abap_true
               AND ( NOT line_exists(
                       current-campos[
                         campo_id = command-CampoId
                         activo   = abap_true
                       ]
                     )
                     OR NOT line_exists(
                       current-secciones[
                         seccion_id = command-SeccionId
                         activo     = abap_true
                       ]
                     )
                     OR NOT line_exists(
                       current-pasos[
                         flujo_id = command-FlujoId
                         version  = command-Version
                         area     = command-Area
                         activo   = abap_true
                       ]
                     )
               ).

              error = 'Regla activa requiere campo, seccion y paso del area activos'.
              RETURN.

            ENDIF.

            " Un campo editable solo puede tener un area responsable.
            IF command-Activo = abap_true
               AND ( command-EstadoCampo = 'M'
                  OR command-EstadoCampo = 'O' ).

              LOOP AT current-reglas INTO DATA(existing_rule)
                WHERE flujo_id = command-FlujoId
                  AND version  = command-Version
                  AND campo_id = command-CampoId
                  AND area    <> command-Area
                  AND activo   = abap_true.

                IF existing_rule-estado_campo = 'M'
                   OR existing_rule-estado_campo = 'O'.

                  error =
                    |El campo { command-CampoId } ya es editable |
                    && |por el area { existing_rule-area }|.
                  RETURN.

                ENDIF.
              ENDLOOP.

            ENDIF.


            DATA(rule) = VALUE ymmt_dm_regla(
              mandt        = sy-mandt
              flujo_id     = command-FlujoId
              version      = command-Version
              area         = command-Area
              campo_id     = command-CampoId
              seccion_id   = command-SeccionId
              estado_campo = command-EstadoCampo
              orden        = command-Orden
              activo       = command-Activo
            ).

            READ TABLE next-reglas
              WITH KEY flujo_id = rule-flujo_id
                       version  = rule-version
                       area     = rule-area
                       campo_id = rule-campo_id
              ASSIGNING FIELD-SYMBOL(<rule>).

            IF sy-subrc = 0.

              rule-regla_uuid = <rule>-regla_uuid.
              <rule> = rule.

            ELSE.

              rule-regla_uuid = cl_system_uuid=>create_uuid_x16_static( ).
              APPEND rule TO next-reglas.

            ENDIF.


          WHEN OTHERS.

            error = 'Mantenimiento desconocido'.

        ENDCASE.

      CATCH cx_uuid_error INTO DATA(uuid_error).

        error = uuid_error->get_text( ).

    ENDTRY.

  ENDMETHOD.


  METHOD validate_version.

    READ TABLE state-versiones
      WITH KEY flujo_id = flow
               version  = version
      INTO DATA(row).
    IF sy-subrc <> 0.
      error = 'Version no encontrada'.
      RETURN.
    ENDIF.

    READ TABLE state-flujos
      WITH KEY flujo_id = flow
      INTO DATA(header).
    IF sy-subrc <> 0 OR
       header-activo <> abap_true.
      error = 'El flujo debe estar activo'.
      RETURN.
    ENDIF.

    IF valid_date( row-vigente_desde ) = abap_false
       OR ( row-vigente_hasta IS NOT INITIAL
            AND ( valid_date( row-vigente_hasta ) = abap_false
                  OR row-vigente_hasta < row-vigente_desde ) ).

      error = 'Vigencia invalida'.
      RETURN.

    ENDIF.

    DATA(until) = COND d(
      WHEN row-vigente_hasta IS INITIAL THEN '99991231'
      ELSE row-vigente_hasta
    ).

    LOOP AT state-versiones INTO DATA(other)
      WHERE estado = 'PUBLICADA'.

      IF other-flujo_id = flow AND other-version = version.
        CONTINUE.
      ENDIF.

      DATA(other_until) = COND d(
        WHEN other-vigente_hasta IS INITIAL THEN '99991231'
        ELSE other-vigente_hasta
      ).

      IF other-vigente_desde > until
         OR other_until < row-vigente_desde.
        CONTINUE.
      ENDIF.

      READ TABLE state-flujos
        WITH KEY flujo_id = other-flujo_id
        INTO DATA(other_header).

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF other-flujo_id = flow
         OR ( other_header-activo = abap_true
              AND other_header-tipo_material = header-tipo_material
              AND other_header-tipo_operacion = header-tipo_operacion
              AND ( other_header-centro_criterio = header-centro_criterio
                    OR other_header-centro_criterio IS INITIAL
                    OR header-centro_criterio IS INITIAL ) ).

        error = 'Vigencia solapada con otra version publicada del flujo o con otro flujo activo de los mismos criterios'.
        RETURN.

      ENDIF.

    ENDLOOP.

    DATA(count_a) = 0.
    DATA(count_b) = 0.

    LOOP AT state-pasos INTO DATA(step)
      WHERE flujo_id = flow
        AND version  = version
        AND activo   = abap_true.

      IF step-condicion_bpm IS INITIAL
         OR step-condicion_bpm = 'A'.
        count_a += 1.
      ENDIF.

      IF step-condicion_bpm IS INITIAL
         OR step-condicion_bpm = 'B'.
        count_b += 1.
      ENDIF.

    ENDLOOP.

    IF count_a = 0 OR count_b = 0.
      error = 'La version debe tener pasos activos aplicables a A y a B'.
      RETURN.
    ENDIF.

    DATA(rule_count) = 0.

    LOOP AT state-reglas INTO DATA(rule)
      WHERE flujo_id = flow
        AND version  = version
        AND activo   = abap_true.

      rule_count += 1.

      IF NOT line_exists(
           state-campos[
             campo_id = rule-campo_id
             activo   = abap_true
           ]
         )
         OR NOT line_exists(
           state-secciones[
             seccion_id = rule-seccion_id
             activo     = abap_true
           ]
         )
         OR NOT line_exists(
           state-pasos[
             flujo_id = flow
             version  = version
             area     = rule-area
             activo   = abap_true
           ]
         )
         OR ( rule-estado_campo <> 'M' AND
              rule-estado_campo <> 'O' AND
              rule-estado_campo <> 'I' AND
              rule-estado_campo <> 'R' ).

        error = 'Reglas activas con campo, seccion, area o estado invalidos'.
        RETURN.

      ENDIF.

    ENDLOOP.

    IF rule_count = 0.
      error = 'La version requiere al menos una regla activa'.
    ENDIF.

  ENDMETHOD.

ENDCLASS.


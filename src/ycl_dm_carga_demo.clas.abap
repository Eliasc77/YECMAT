CLASS ycl_dm_carga_demo DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.
CLASS ycl_dm_carga_demo IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA(desired) = ycl_dm_demo_config=>build( ).
    DATA existing TYPE ycl_dm_demo_config=>ty_config.
    "Only own configuration tables and the current client are read/written.
    SELECT * FROM ymmt_dm_flujo WHERE flujo_id = @ycl_dm_demo_config=>flujo_id
      INTO TABLE @existing-flujos.
    SELECT * FROM ymmt_dm_flujo_vr WHERE flujo_id = @ycl_dm_demo_config=>flujo_id
      AND version = @ycl_dm_demo_config=>version_id INTO TABLE @existing-versiones.
    SELECT * FROM ymmt_dm_paso WHERE flujo_id = @ycl_dm_demo_config=>flujo_id
      AND version = @ycl_dm_demo_config=>version_id INTO TABLE @existing-pasos.
    SELECT * FROM ymmt_dm_regla WHERE flujo_id = @ycl_dm_demo_config=>flujo_id
      AND version = @ycl_dm_demo_config=>version_id INTO TABLE @existing-reglas.
    DATA(catalog) = desired-campos.
    DATA(sections) = desired-secciones.
    IF catalog IS NOT INITIAL.
      SELECT * FROM ymmt_dm_campo FOR ALL ENTRIES IN @catalog
        WHERE campo_id = @catalog-campo_id INTO TABLE @existing-campos.
    ENDIF.
    IF sections IS NOT INITIAL.
      SELECT * FROM ymmt_dm_seccion FOR ALL ENTRIES IN @sections
        WHERE seccion_id = @sections-seccion_id INTO TABLE @existing-secciones.
    ENDIF.
    ycl_dm_demo_config=>plan( EXPORTING desired = desired existing = existing
      IMPORTING additions = DATA(additions) error = DATA(error) ).
    IF error IS NOT INITIAL.
      out->write( error ).
      out->write( 'Carga cancelada ANTES de escribir. No se sobrescriben configuraciones existentes.' ).
      RETURN.
    ENDIF.
    IF additions IS INITIAL.
      out->write( 'El perfil DEMO ya esta cargado completo. No se modifico ningun registro.' ).
      out->write( 'Siguiente paso: ejecutar YCL_DM_CREAR_SOL_DEMO.' ).
      RETURN.
    ENDIF.
    TRY.
        "Generate UUIDs before the first SQL write; existing logical rules are reused.
        LOOP AT additions-reglas ASSIGNING FIELD-SYMBOL(<rule>).
          <rule>-regla_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        ENDLOOP.
        "No ACCEPTING DUPLICATE KEYS: a conflict aborts the whole transaction.
        IF additions-flujos IS NOT INITIAL.
          INSERT ymmt_dm_flujo FROM TABLE @additions-flujos.
        ENDIF.
        IF additions-campos IS NOT INITIAL.
          INSERT ymmt_dm_campo FROM TABLE @additions-campos.
        ENDIF.
        IF additions-secciones IS NOT INITIAL.
          INSERT ymmt_dm_seccion FROM TABLE @additions-secciones.
        ENDIF.
        IF additions-versiones IS NOT INITIAL.
          INSERT ymmt_dm_flujo_vr FROM TABLE @additions-versiones.
        ENDIF.
        IF additions-pasos IS NOT INITIAL.
          INSERT ymmt_dm_paso FROM TABLE @additions-pasos.
        ENDIF.
        IF additions-reglas IS NOT INITIAL.
          INSERT ymmt_dm_regla FROM TABLE @additions-reglas.
        ENDIF.
        "Standalone console application owns this LUW; never call it from a RAP handler.
        COMMIT WORK AND WAIT.
      CATCH cx_uuid_error INTO DATA(uuid_error).
        ROLLBACK WORK.
        out->write( uuid_error->get_text( ) ). RETURN.
      CATCH cx_sy_open_sql_db INTO DATA(sql_error).
        ROLLBACK WORK.
        out->write( sql_error->get_text( ) ).
        out->write( 'Carga revertida. Otro proceso pudo cargar datos: revisar y reejecutar.' ).
        RETURN.
    ENDTRY.
    out->write( 'Configuracion DEMO guardada: DM_DEMO_ZFER / version 1 / ZFER / operacion C.' ).
    out->write( |Nuevos: flujos { lines( additions-flujos ) }, versiones { lines( additions-versiones ) }, pasos { lines( additions-pasos ) }| ).
    out->write( |Nuevos: campos { lines( additions-campos ) }, secciones { lines( additions-secciones ) }, reglas { lines( additions-reglas ) }| ).
    out->write( 'Siguiente paso: ejecutar YCL_DM_CREAR_SOL_DEMO con el mismo usuario de la preview.' ).
  ENDMETHOD.
ENDCLASS.

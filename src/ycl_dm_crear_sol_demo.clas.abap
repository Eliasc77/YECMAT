CLASS ycl_dm_crear_sol_demo DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.
CLASS ycl_dm_crear_sol_demo IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA(user) = cl_abap_context_info=>get_user_technical_name( ).
    DATA(number) = CONV ymmt_dm_sol-numero_solicitud( |D-{ user }-01| ).
    SELECT SINGLE * FROM ymmt_dm_sol WHERE numero_solicitud = @number INTO @DATA(existing).
    IF sy-subrc = 0.
      IF existing-creado_por <> user OR existing-flujo_id <> ycl_dm_demo_config=>flujo_id
        OR existing-version <> ycl_dm_demo_config=>version_id OR existing-tipo_material <> 'ZFER'
        OR existing-tipo_operacion <> yif_dm_constants=>c_operacion_material-crear.
        out->write( 'El numero de prueba ya corresponde a otra solicitud. No se modifica.' ). RETURN.
      ENDIF.
      out->write( 'La solicitud de prueba de este usuario ya existe. No se duplico ni reinicio.' ).
      out->write( |Numero: { existing-numero_solicitud } / Estado: { existing-estado }| ).
      out->write( |UUID: { existing-solicitud_uuid }| ). RETURN.
    ENDIF.
    SELECT SINGLE flujo_id FROM ymmt_dm_flujo_vr WHERE flujo_id = @ycl_dm_demo_config=>flujo_id
      AND version = @ycl_dm_demo_config=>version_id AND estado = @yif_dm_constants=>c_estado_version-publicada INTO
        @DATA(configured).
    IF sy-subrc <> 0.
      out->write( 'Primero ejecutar YCL_DM_CARGA_DEMO. La version DEMO no esta publicada.' ). RETURN.
    ENDIF.
    "Consume the base RAP BO via EML; no IN LOCAL MODE or authorization bypass.
    MODIFY ENTITIES OF yi_dm_sol ENTITY Solicitud
      CREATE FIELDS ( NumeroSolicitud TipoMaterial TipoOperacion FlujoId Version )
      WITH VALUE #( ( %cid = 'PRIMERA_SOLICITUD_DEMO' NumeroSolicitud = number
        TipoMaterial = 'ZFER' TipoOperacion = yif_dm_constants=>c_operacion_material-crear FlujoId =
          ycl_dm_demo_config=>flujo_id
        Version = ycl_dm_demo_config=>version_id ) )
      MAPPED DATA(mapped) FAILED DATA(failed) REPORTED DATA(reported).
    IF failed IS NOT INITIAL.
      LOOP AT reported-solicitud INTO DATA(message).
        IF message-%msg IS BOUND. out->write( message-%msg->if_message~get_text( ) ). ENDIF.
      ENDLOOP.
      out->write( 'CREATE rechazado por RAP. No se guardo la solicitud.' ).
      ROLLBACK ENTITIES. RETURN.
    ENDIF.
    COMMIT ENTITIES RESPONSE OF yi_dm_sol
      FAILED DATA(save_failed) REPORTED DATA(save_reported).
    IF save_failed IS NOT INITIAL.
      LOOP AT save_reported-solicitud INTO DATA(save_message).
        IF save_message-%msg IS BOUND. out->write( save_message-%msg->if_message~get_text( ) ). ENDIF.
      ENDLOOP.
      out->write( 'Validacion de guardado rechazada. Revisar los mensajes anteriores.' ).
      ROLLBACK ENTITIES. RETURN.
    ENDIF.
    SELECT SINGLE solicitud_uuid, estado FROM ymmt_dm_sol WHERE numero_solicitud = @number
      INTO @DATA(saved).
    IF sy-subrc <> 0.
      out->write( 'No se encontro la solicitud guardada. Revisar el log del runtime.' ). RETURN.
    ENDIF.
    out->write( |Solicitud guardada: { number } / Estado: { saved-estado }| ).
    out->write( |UUID: { saved-solicitud_uuid } / Creador: { user }| ).
    out->write( 'En la preview: borrar filtros, pulsar Go y seleccionar la solicitud.' ).
    out->write( 'Luego Iniciar flujo con ClasificacionBpm = B para generar las tareas.' ).
  ENDMETHOD.
ENDCLASS.

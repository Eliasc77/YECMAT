CLASS ltc_migracion DEFINITION FINAL FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS fixture RETURNING VALUE(state) TYPE ycl_dm_cfg_model=>ty_state.
    METHODS ayuda_en_campo_usado FOR TESTING.
    METHODS estructura_protegida FOR TESTING.
    METHODS alta_agregado FOR TESTING.
    METHODS publicar_borrador FOR TESTING.
    METHODS publicar_con_conflicto FOR TESTING.
    METHODS solo_lectura_compartida FOR TESTING.
    METHODS no_borrar FOR TESTING.
    METHODS ignorar_auditoria FOR TESTING.
    METHODS transferir_responsable FOR TESTING.
    METHODS reemplazar_paso FOR TESTING.
    METHODS una_raiz_por_guardado FOR TESTING.
ENDCLASS.
CLASS ltc_migracion IMPLEMENTATION.
  METHOD fixture.
    " Datos de prueba en memoria; no se escriben en las tablas de configuracion.
    state-flujos = VALUE #(
      (
        mandt = sy-mandt
        flujo_id = 'TEST'
        descripcion = 'Prueba'
        tipo_material = 'ZFER'
        tipo_operacion = yif_dm_constants=>c_operacion_material-crear
        activo = abap_true ) ).
    state-versiones = VALUE #(
      (
        mandt = sy-mandt
        flujo_id = 'TEST'
        version = 1
        estado = yif_dm_constants=>c_estado_version-publicada
        vigente_desde = '20200101'
        vigente_hasta = yif_dm_constants=>c_validacion-fecha_maxima ) ).
    state-campos = VALUE #(
      (
        mandt = sy-mandt
        campo_id = 'MAKT_MAKTX'
        descripcion = 'Descripcion'
        tabla_sap = 'MAKT'
        campo_sap = 'MAKTX'
        tipo_segmento = yif_dm_constants=>c_tipo_segmento-general
        tipo_dato = yif_dm_constants=>c_tipo_dato-char
        longitud = 40
        tipo_control = yif_dm_constants=>c_control_pantalla-entrada
        activo = abap_true ) ).
    state-secciones = VALUE #(
      (
        mandt = sy-mandt
        seccion_id = 'BASICOS'
        descripcion = 'Basicos'
        orden = 10
        activo = abap_true ) ).
    state-pasos = VALUE #(
      (
        mandt = sy-mandt
        flujo_id = 'TEST'
        version = 1
        paso_id = 'PCP'
        area = 'PCP'
        fase = yif_dm_constants=>c_fase-captura
        orden = 10
        obligatorio = abap_true
        activo = abap_true ) ).
    state-reglas = VALUE #(
      (
        mandt = sy-mandt
        regla_uuid = '00000000000000000000000000000001'
        flujo_id = 'TEST'
        version = 1
        area = 'PCP'
        campo_id = 'MAKT_MAKTX'
        seccion_id = 'BASICOS'
        estado_campo = yif_dm_constants=>c_estado_campo-obligatorio
        orden = 10
        activo = abap_true ) ).
  ENDMETHOD.
  METHOD ayuda_en_campo_usado.
    DATA(antes) = fixture( ).
    INSERT antes-campos[ 1 ]-campo_id INTO TABLE antes-used_fields.
    DATA(despues) = antes.
    despues-campos[ 1 ]-ayuda_valores = 'CatalogoPrueba'.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD estructura_protegida.
    DATA(antes) = fixture( ). DATA(despues) = antes.
    despues-campos[ 1 ]-longitud = 80.
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD alta_agregado.
    DATA antes TYPE ycl_dm_cfg_model=>ty_state.
    DATA(despues) = fixture( ).
    despues-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-borrador.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD publicar_borrador.
    DATA(antes) = fixture( ).
    antes-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-borrador.
    DATA(despues) = antes.
    despues-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-publicada.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD publicar_con_conflicto.
    DATA(antes) = fixture( ).
    antes-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-borrador.
    DATA(paso) = antes-pasos[ 1 ]. paso-area = 'OTRA'. paso-paso_id = 'OTRA'.
    APPEND paso TO antes-pasos.
    DATA(regla) = antes-reglas[ 1 ]. regla-area = 'OTRA'.
    regla-regla_uuid = '00000000000000000000000000000002'. APPEND regla TO antes-reglas.
    DATA(despues) = antes.
    despues-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-publicada.
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD solo_lectura_compartida.
    DATA(antes) = fixture( ).
    antes-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-borrador.
    DATA(despues) = antes.
    DATA(paso) = antes-pasos[ 1 ]. paso-area = 'OTRA'. paso-paso_id = 'OTRA'.
    APPEND paso TO despues-pasos.
    DATA(regla) = antes-reglas[ 1 ]. regla-area = 'OTRA'.
    regla-estado_campo = yif_dm_constants=>c_estado_campo-solo_lectura.
    regla-regla_uuid = '00000000000000000000000000000002'. APPEND regla TO despues-reglas.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD no_borrar.
    DATA(antes) = fixture( ). DATA(despues) = antes.
    CLEAR despues-reglas.
    cl_abap_unit_assert=>assert_not_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD ignorar_auditoria.
    DATA(antes) = fixture( ). DATA(despues) = antes.
    GET TIME STAMP FIELD despues-campos[ 1 ]-local_last_changed_at.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD transferir_responsable.
    DATA(antes) = fixture( ).
    antes-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-borrador.
    DATA(paso) = antes-pasos[ 1 ]. paso-area = 'OTRA'. paso-paso_id = 'OTRA'.
    APPEND paso TO antes-pasos.
    DATA(regla) = antes-reglas[ 1 ]. regla-area = 'OTRA'.
    regla-regla_uuid = '00000000000000000000000000000002'.
    regla-estado_campo = yif_dm_constants=>c_estado_campo-solo_lectura.
    APPEND regla TO antes-reglas.
    DATA(despues) = antes.
    despues-reglas[ 1 ]-estado_campo = yif_dm_constants=>c_estado_campo-solo_lectura.
    despues-reglas[ 2 ]-estado_campo = yif_dm_constants=>c_estado_campo-obligatorio.
    "_ La validacion no debe depender del orden de las reglas enviadas.
    SORT despues-reglas BY regla_uuid DESCENDING.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD reemplazar_paso.
    DATA(antes) = fixture( ).
    antes-versiones[ 1 ]-estado = yif_dm_constants=>c_estado_version-borrador.
    DATA(despues) = antes.
    despues-pasos[ 1 ]-activo = abap_false.
    DATA(paso) = antes-pasos[ 1 ]. paso-paso_id = 'REEMPLAZO'. APPEND paso TO despues-pasos.
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_model=>validar(
      anterior = antes propuesto = despues ) ).
  ENDMETHOD.
  METHOD una_raiz_por_guardado.
    ycl_dm_mnt_trans=>limpiar( ).
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_trans=>registrar( raiz = 'Flujos' clave = 'TEST' ) ).
    cl_abap_unit_assert=>assert_initial( ycl_dm_mnt_trans=>registrar( raiz = 'Flujos' clave = 'TEST' ) ).
    DATA(error) = ycl_dm_mnt_trans=>registrar( raiz = 'Campos' clave = 'MAKT_MAKTX' ).
    ycl_dm_mnt_trans=>limpiar( ).
    cl_abap_unit_assert=>assert_not_initial( error ).
  ENDMETHOD.
ENDCLASS.

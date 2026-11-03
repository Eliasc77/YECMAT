@EndUserText.label: 'DM comando de mantenimiento'
define abstract entity YD_DM_CFG_CMD {
  EntitySet : abap.char(12);
  Operation : abap.char(12);
  CampoId : ymme_dm_campo_id;
  Descripcion : abap.char(80);
  TablaSap : ymme_dm_nombre;
  CampoSap : ymme_dm_nombre;
  TipoSegmento : abap.char(10);
  TipoDato : abap.char(10);
  Longitud : abap.int4;
  Decimales : abap.int4;
  AyudaValores : abap.char(30);
  TipoControl : abap.char(20);
  Activo : abap_boolean;
  SeccionId : ymme_dm_seccion;
  Orden : abap.int4;
  FlujoId : ymme_dm_flujo_id;
  TipoMaterial : abap.char(4);
  TipoOperacion : abap.char(1);
  CentroCriterio : abap.char(4);
  Version : abap.int4;
  VigenteDesde : abap.char(8);
  VigenteHasta : abap.char(8);
  PasoId : ymme_dm_paso_id;
  Area : abap.char(10);
  Fase : abap.char(20);
  CondicionBpm : abap.char(1);
  Obligatorio : abap_boolean;
  EstadoCampo : abap.char(1);
  VersionDestino : abap.int4;
}

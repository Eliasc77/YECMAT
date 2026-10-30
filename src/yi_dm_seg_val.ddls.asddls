@EndUserText.label: 'DM SEG_VAL'
@AccessControl.authorizationCheck: #CHECK
define view entity YI_DM_SEG_VAL
  as select from ymmt_dm_seg_val as Data
  association to parent YI_DM_SEG as _Segmento
    on $projection.SegmentoUUID = _Segmento.SegmentoUUID
{
  key Data.segmento_uuid as SegmentoUUID,
      Data.area_valoracion as AreaValoracion,
      Data.tipo_valoracion as TipoValoracion,
      _Segmento
}

@EndUserText.label: 'DM SEG_UOM'
@AccessControl.authorizationCheck: #CHECK
define view entity YI_DM_SEG_UOM
  as select from ymmt_dm_seg_uom as Data
  association to parent YI_DM_SEG as _Segmento
    on $projection.SegmentoUUID = _Segmento.SegmentoUUID
{
  key Data.segmento_uuid as SegmentoUUID,
      Data.unidad_alternativa as UnidadAlternativa,
      _Segmento
}

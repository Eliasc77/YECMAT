@EndUserText.label: 'DM SEG_ALM'
@AccessControl.authorizationCheck: #CHECK
define view entity YI_DM_SEG_ALM
  as select from ymmt_dm_seg_alm as Data
  association to parent YI_DM_SEG as _Segmento
    on $projection.SegmentoUUID = _Segmento.SegmentoUUID
{
  key Data.segmento_uuid as SegmentoUUID,
      Data.centro as Centro,
      Data.almacen as Almacen,
      _Segmento
}

@EndUserText.label: 'DM SEG_CEN'
@AccessControl.authorizationCheck: #CHECK
define view entity YI_DM_SEG_CEN
  as select from ymmt_dm_seg_cen as Data
  association to parent YI_DM_SEG as _Segmento
    on $projection.SegmentoUUID = _Segmento.SegmentoUUID
{
  key Data.segmento_uuid as SegmentoUUID,
      Data.centro as Centro,
      _Segmento
}

@EndUserText.label: 'DM SEG_VEN'
@AccessControl.authorizationCheck: #CHECK
define view entity YI_DM_SEG_VEN
  as select from ymmt_dm_seg_ven as Data
  association to parent YI_DM_SEG as _Segmento
    on $projection.SegmentoUUID = _Segmento.SegmentoUUID
{
  key Data.segmento_uuid as SegmentoUUID,
      Data.org_ventas as OrgVentas,
      Data.canal as Canal,
      _Segmento
}

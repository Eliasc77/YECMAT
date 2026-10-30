@EndUserText.label: 'DM SEG_VEN'
@AccessControl.authorizationCheck: #CHECK
define view entity YC_DM_SEG_VEN
  provider contract transactional_query
  as projection on YI_DM_SEG_VEN
{
  key SegmentoUUID,
      OrgVentas,
      Canal,
      _Segmento : redirected to parent YC_DM_SEG
}

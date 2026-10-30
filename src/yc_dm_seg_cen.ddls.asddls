@EndUserText.label: 'DM SEG_CEN'
@AccessControl.authorizationCheck: #CHECK
define view entity YC_DM_SEG_CEN
  provider contract transactional_query
  as projection on YI_DM_SEG_CEN
{
  key SegmentoUUID,
      Centro,
      _Segmento : redirected to parent YC_DM_SEG
}

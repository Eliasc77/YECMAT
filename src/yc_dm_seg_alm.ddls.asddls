@EndUserText.label: 'DM SEG_ALM'
@AccessControl.authorizationCheck: #CHECK
define view entity YC_DM_SEG_ALM
  provider contract transactional_query
  as projection on YI_DM_SEG_ALM
{
  key SegmentoUUID,
      Centro,
      Almacen,
      _Segmento : redirected to parent YC_DM_SEG
}

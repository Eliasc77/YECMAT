@EndUserText.label: 'DM SEG_VAL'
@AccessControl.authorizationCheck: #CHECK
define view entity YC_DM_SEG_VAL
  provider contract transactional_query
  as projection on YI_DM_SEG_VAL
{
  key SegmentoUUID,
      AreaValoracion,
      TipoValoracion,
      _Segmento : redirected to parent YC_DM_SEG
}

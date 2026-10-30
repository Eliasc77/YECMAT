@EndUserText.label: 'DM SEG_UOM'
@AccessControl.authorizationCheck: #CHECK
define view entity YC_DM_SEG_UOM
  provider contract transactional_query
  as projection on YI_DM_SEG_UOM
{
  key SegmentoUUID,
      UnidadAlternativa,
      _Segmento : redirected to parent YC_DM_SEG
}

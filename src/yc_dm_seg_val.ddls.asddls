@EndUserText.label: 'DM SEG_VAL'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity YC_DM_SEG_VAL
 
  as projection on YI_DM_SEG_VAL
{
  key SegmentoUUID,
      AreaValoracion,
      TipoValoracion,
      _Segmento : redirected to parent YC_DM_SEG
}

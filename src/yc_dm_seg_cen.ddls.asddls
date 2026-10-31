@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'YC_DM_SEG_CEN'
@Metadata.allowExtensions: true
define view entity YC_DM_SEG_CEN as projection on YI_DM_SEG_CEN
{
  key SegmentoUUID,
      Centro,
      _Segmento : redirected to parent YC_DM_SEG
}

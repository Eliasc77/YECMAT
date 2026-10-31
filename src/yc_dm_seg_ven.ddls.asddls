@EndUserText.label: 'DM SEG_VEN'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity YC_DM_SEG_VEN
 
  as projection on YI_DM_SEG_VEN
{
  key SegmentoUUID,
      OrgVentas,
      Canal,
      _Segmento : redirected to parent YC_DM_SEG
}

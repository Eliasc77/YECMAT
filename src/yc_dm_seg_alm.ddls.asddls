@EndUserText.label: 'DM SEG_ALM'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity YC_DM_SEG_ALM
 
  as projection on YI_DM_SEG_ALM
{
  key SegmentoUUID,
      Centro,
      Almacen,
      _Segmento : redirected to parent YC_DM_SEG
}

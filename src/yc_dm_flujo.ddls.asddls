@EndUserText.label: 'DM FLUJO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_DM_FLUJO
  as select from YI_DM_FLUJO
{
  key FlujoId,
      Descripcion,
      TipoMaterial,
      TipoOperacion,
      CentroCriterio,
      Activo
}

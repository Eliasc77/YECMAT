@EndUserText.label: 'DM FLUJO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
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

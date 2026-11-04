@EndUserText.label: 'DM Flujos'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity YC_DM_M_FLUJO
  provider contract transactional_query
  as projection on YI_DM_M_FLUJO
{
  key FlujoId,
      Descripcion,
      TipoMaterial,
      TipoOperacion,
      CentroCriterio,
      Activo,
      LastChangedAt,
      LocalLastChangedAt,
      _Versiones : redirected to composition child YC_DM_M_FLUJO_VR
}

@EndUserText.label: 'DM Pasos'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_DM_M_PASO
  provider contract transactional_query
  as projection on YI_DM_M_PASO
{
  key FlujoId,
  key Version,
  key PasoId,
      Area,
      Fase,
      CondicionBpm,
      Orden,
      Obligatorio,
      Activo,
      LastChangedAt,
      LocalLastChangedAt,
      _Version : redirected to parent YC_DM_M_FLUJO_VR,
      _Flujo : redirected to YC_DM_M_FLUJO
}

@EndUserText.label: 'DM Versiones'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_DM_M_FLUJO_VR
  provider contract transactional_query
  as projection on YI_DM_M_FLUJO_VR
{
  key FlujoId,
  key Version,
      Estado,
      VigenteDesde,
      VigenteHasta,
      CreadoPor,
      CreadoEl,
      LastChangedAt,
      LocalLastChangedAt,
      _Flujo : redirected to parent YC_DM_M_FLUJO,
      _Pasos : redirected to composition child YC_DM_M_PASO,
      _Reglas : redirected to composition child YC_DM_M_REGLA
}

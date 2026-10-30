@EndUserText.label: 'DM FLUJO_VR'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YC_DM_FLUJO_VR
  as select from YI_DM_FLUJO_VR
{
  key FlujoId,
  key Version,
      Estado,
      VigenteDesde,
      VigenteHasta,
      CreadoPor,
      CreadoEl
}

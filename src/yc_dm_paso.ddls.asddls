@EndUserText.label: 'DM PASO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YC_DM_PASO
  as select from YI_DM_PASO
{
  key FlujoId,
  key Version,
  key PasoId,
      Area,
      Fase,
      CondicionBpm,
      Orden,
      Obligatorio,
      Activo
}

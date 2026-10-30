@EndUserText.label: 'DM TAREA'
@AccessControl.authorizationCheck: #CHECK
define root view entity YC_DM_TAREA
  provider contract transactional_query
  as projection on YI_DM_TAREA
{
  key TareaUUID,
      SolicitudUUID,
      FlujoId,
      Version,
      PasoId,
      Area,
      Estado,
      Responsable,
      CreadoEl,
      LastChangedAt,
      _Solicitud : redirected to YC_DM_SOL,
      _Paso : redirected to YC_DM_PASO
}

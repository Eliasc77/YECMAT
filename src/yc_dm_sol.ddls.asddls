@EndUserText.label: 'DM SOL'
@AccessControl.authorizationCheck: #CHECK
define root view entity YC_DM_SOL
  provider contract transactional_query
  as projection on YI_DM_SOL
{
  key SolicitudUUID,
      NumeroSolicitud,
      TipoMaterial,
      TipoOperacion,
      Material,
      FlujoId,
      Version,
      Estado,
      CreadoPor,
      CreadoEl,
      ClasificacionBpm,
      LastChangedAt,
      _Version : redirected to YC_DM_FLUJO_VR,
      _Segmentos : redirected to YC_DM_SEG,
      _Tareas : redirected to YC_DM_TAREA,
      _Acceso
}

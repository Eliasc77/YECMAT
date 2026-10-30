@EndUserText.label: 'DM miembros de solicitud'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_SOL_USR
  as select from ymmt_dm_sol
{
  key solicitud_uuid as SolicitudUUID,
  key creado_por as Usuario
}
union select from ymmt_dm_tarea
{
  solicitud_uuid as SolicitudUUID,
  responsable as Usuario
}
where responsable <> ''

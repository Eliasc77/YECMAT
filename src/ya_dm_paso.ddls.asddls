@EndUserText.label: 'DM mantenimiento PASO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_PASO
  as select from ymmt_dm_paso as Data
    inner join ymmt_dm_cfg_usr as Access
      on Access.user_name = $session.user and Access.active = 'X'
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
  key Data.paso_id as PasoId,
      Data.area as Area,
      Data.fase as Fase,
      Data.condicion_bpm as CondicionBpm,
      Data.orden as Orden,
      Data.obligatorio as Obligatorio,
      Data.activo as Activo
}

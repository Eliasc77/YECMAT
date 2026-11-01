@EndUserText.label: 'DM mantenimiento REGLA'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_REGLA
  as select from ymmt_dm_regla as Data
    inner join ymmt_dm_cfg_usr as Access
      on Access.user_name = $session.user and Access.active = 'X'
{
  key Data.regla_uuid as ReglaUUID,
      Data.flujo_id as FlujoId,
      Data.version as Version,
      Data.area as Area,
      Data.campo_id as CampoId,
      Data.seccion_id as SeccionId,
      Data.estado_campo as EstadoCampo,
      Data.orden as Orden,
      Data.activo as Activo
}

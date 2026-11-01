@EndUserText.label: 'DM mantenimiento SECCION'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_SECCION
  as select from ymmt_dm_seccion as Data
    inner join ymmt_dm_cfg_usr as Access
      on Access.user_name = $session.user and Access.active = 'X'
{
  key Data.seccion_id as SeccionId,
      Data.descripcion as Descripcion,
      Data.orden as Orden,
      Data.activo as Activo
}

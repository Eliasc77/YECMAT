@EndUserText.label: 'DM mantenimiento FLUJO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_FLUJO
  as select from ymmt_dm_flujo as Data
    inner join ymmt_dm_cfg_usr as Access
      on Access.user_name = $session.user and Access.active = 'X'
{
  key Data.flujo_id as FlujoId,
      Data.descripcion as Descripcion,
      Data.tipo_material as TipoMaterial,
      Data.tipo_operacion as TipoOperacion,
      Data.centro_criterio as CentroCriterio,
      Data.activo as Activo
}

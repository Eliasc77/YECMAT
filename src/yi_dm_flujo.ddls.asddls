@EndUserText.label: 'DM FLUJO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_FLUJO
  as select from ymmt_dm_flujo as Data
{
  key Data.flujo_id as FlujoId,
      Data.descripcion as Descripcion,
      Data.tipo_material as TipoMaterial,
      Data.tipo_operacion as TipoOperacion,
      Data.centro_criterio as CentroCriterio,
      Data.activo as Activo
}

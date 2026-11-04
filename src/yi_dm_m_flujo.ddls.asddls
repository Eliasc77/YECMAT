@EndUserText.label: 'DM Flujos - mantenimiento'
// TODO IAM: aplicar la DCL de administrador antes de productivo.
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity YI_DM_M_FLUJO
  as select from ymmt_dm_flujo as Data
  composition [0..*] of YI_DM_M_FLUJO_VR as _Versiones
{
  key Data.flujo_id as FlujoId,
      Data.descripcion as Descripcion,
      Data.tipo_material as TipoMaterial,
      Data.tipo_operacion as TipoOperacion,
      Data.centro_criterio as CentroCriterio,
      Data.activo as Activo,
      @Semantics.systemDateTime.lastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.local_last_changed_at as LocalLastChangedAt,
      _Versiones
}

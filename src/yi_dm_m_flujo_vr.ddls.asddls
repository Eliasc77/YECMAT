@EndUserText.label: 'DM Versiones - mantenimiento'
// TODO IAM: aplicar la DCL de administrador antes de productivo.
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_M_FLUJO_VR
  as select from ymmt_dm_flujo_vr as Data
  association to parent YI_DM_M_FLUJO as _Flujo on $projection.FlujoId = _Flujo.FlujoId
  composition [0..*] of YI_DM_M_PASO as _Pasos
  composition [0..*] of YI_DM_M_REGLA as _Reglas
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
      Data.estado as Estado,
      Data.vigente_desde as VigenteDesde,
      Data.vigente_hasta as VigenteHasta,
      @Semantics.user.createdBy: true
      Data.creado_por as CreadoPor,
      @Semantics.systemDateTime.createdAt: true
      Data.creado_el as CreadoEl,
      @Semantics.systemDateTime.lastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.local_last_changed_at as LocalLastChangedAt,
      _Flujo,
      _Pasos,
      _Reglas
}

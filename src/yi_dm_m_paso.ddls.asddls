@EndUserText.label: 'DM Pasos - mantenimiento'
// TODO IAM: aplicar la DCL de administrador antes de productivo.
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_M_PASO
  as select from ymmt_dm_paso as Data
  association to parent YI_DM_M_FLUJO_VR as _Version on $projection.FlujoId = _Version.FlujoId and $projection.Version = _Version.Version
  association [1..1] to YI_DM_M_FLUJO as _Flujo on $projection.FlujoId = _Flujo.FlujoId
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
  key Data.paso_id as PasoId,
      Data.area as Area,
      Data.fase as Fase,
      Data.condicion_bpm as CondicionBpm,
      Data.orden as Orden,
      Data.obligatorio as Obligatorio,
      Data.activo as Activo,
      @Semantics.systemDateTime.lastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.local_last_changed_at as LocalLastChangedAt,
      _Version,
      _Flujo
}

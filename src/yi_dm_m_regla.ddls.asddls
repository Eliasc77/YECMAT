@EndUserText.label: 'DM Reglas - mantenimiento'
// TODO IAM: aplicar la DCL de administrador antes de productivo.
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_M_REGLA
  as select from ymmt_dm_regla as Data
  association to parent YI_DM_M_FLUJO_VR as _Version on $projection.FlujoId = _Version.FlujoId and $projection.Version = _Version.Version
  association [1..1] to YI_DM_M_FLUJO as _Flujo on $projection.FlujoId = _Flujo.FlujoId
  association [0..1] to YI_DM_M_CAMPO as _Campo on $projection.CampoId = _Campo.CampoId
  association [0..1] to YI_DM_M_SECCION as _Seccion on $projection.SeccionId = _Seccion.SeccionId
{
  key Data.regla_uuid as ReglaUUID,
      Data.flujo_id as FlujoId,
      Data.version as Version,
      Data.area as Area,
      Data.campo_id as CampoId,
      Data.seccion_id as SeccionId,
      Data.estado_campo as EstadoCampo,
      Data.orden as Orden,
      Data.activo as Activo,
      @Semantics.systemDateTime.lastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.local_last_changed_at as LocalLastChangedAt,
      _Version,
      _Flujo,
      _Campo,
      _Seccion
}

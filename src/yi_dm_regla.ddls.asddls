@EndUserText.label: 'DM REGLA'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_REGLA
  as select from ymmt_dm_regla as Data
  association [1..1] to YI_DM_FLUJO_VR as _Version
    on $projection.FlujoId = _Version.FlujoId and $projection.Version = _Version.Version
  association [1..1] to YI_DM_CAMPO as _Campo
    on $projection.CampoId = _Campo.CampoId
  association [1..1] to YI_DM_SECCION as _Seccion
    on $projection.SeccionId = _Seccion.SeccionId
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
      _Version,
      _Campo,
      _Seccion
}

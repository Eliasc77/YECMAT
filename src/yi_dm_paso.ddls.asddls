@EndUserText.label: 'DM PASO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_PASO
  as select from ymmt_dm_paso as Data
  association [1..1] to YI_DM_FLUJO_VR as _Version
    on $projection.FlujoId = _Version.FlujoId and $projection.Version = _Version.Version
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
      _Version
}

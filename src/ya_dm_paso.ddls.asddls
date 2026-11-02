@EndUserText.label: 'DM mantenimiento PASO'
// TEMPORAL: sin filtro de administrador DM; acceso autenticado del servicio.
// TODO IAM: activar #CHECK y la DCL de lectura ACTVT 03 (ver documentacion).
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_PASO
  as select from ymmt_dm_paso as Data
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
  key Data.paso_id as PasoId,
      Data.area as Area,
      Data.fase as Fase,
      Data.condicion_bpm as CondicionBpm,
      Data.orden as Orden,
      Data.obligatorio as Obligatorio,
      Data.activo as Activo
}

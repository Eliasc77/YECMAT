@EndUserText.label: 'DM mantenimiento REGLA'
// TEMPORAL: sin filtro de administrador DM; acceso autenticado del servicio.
// TODO IAM: activar #CHECK y la DCL de lectura ACTVT 03 (ver documentacion).
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_REGLA
  as select from ymmt_dm_regla as Data
{
  key Data.regla_uuid as ReglaUUID,
      Data.flujo_id as FlujoId,
      Data.version as Version,
      Data.area as Area,
      Data.campo_id as CampoId,
      Data.seccion_id as SeccionId,
      Data.estado_campo as EstadoCampo,
      Data.orden as Orden,
      Data.activo as Activo
}

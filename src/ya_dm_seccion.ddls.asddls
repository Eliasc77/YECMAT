@EndUserText.label: 'DM mantenimiento SECCION'
// TEMPORAL: sin filtro de administrador DM; acceso autenticado del servicio.
// TODO IAM: activar #CHECK y la DCL de lectura ACTVT 03 (ver documentacion).
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_SECCION
  as select from ymmt_dm_seccion as Data
{
  key Data.seccion_id as SeccionId,
      Data.descripcion as Descripcion,
      Data.orden as Orden,
      Data.activo as Activo
}

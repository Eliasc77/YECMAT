@EndUserText.label: 'DM mantenimiento FLUJO'
// TEMPORAL: sin filtro de administrador DM; acceso autenticado del servicio.
// TODO IAM: activar #CHECK y la DCL de lectura ACTVT 03 (ver documentacion).
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_FLUJO
  as select from ymmt_dm_flujo as Data
{
  key Data.flujo_id as FlujoId,
      Data.descripcion as Descripcion,
      Data.tipo_material as TipoMaterial,
      Data.tipo_operacion as TipoOperacion,
      Data.centro_criterio as CentroCriterio,
      Data.activo as Activo
}

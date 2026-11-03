@EndUserText.label: 'DM mantenimiento FLUJO_VR'
// TEMPORAL: sin filtro de administrador DM; acceso autenticado del servicio.
// TODO IAM: activar #CHECK y la DCL de lectura ACTVT 03 (ver documentacion).
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_FLUJO_VR
  as select from ymmt_dm_flujo_vr as Data
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
      Data.estado as Estado,
      Data.vigente_desde as VigenteDesde,
      Data.vigente_hasta as VigenteHasta,
      @Semantics.user.createdBy: true
      Data.creado_por as CreadoPor,
      @Semantics.systemDateTime.createdAt: true
      Data.creado_el as CreadoEl
}

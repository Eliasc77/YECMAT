@EndUserText.label: 'DM Secciones - mantenimiento'
// TODO IAM: aplicar la DCL de administrador antes de productivo.
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity YI_DM_M_SECCION
  as select from ymmt_dm_seccion as Data
{
  key Data.seccion_id as SeccionId,
      Data.descripcion as Descripcion,
      Data.orden as Orden,
      Data.activo as Activo,
      @Semantics.systemDateTime.lastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.local_last_changed_at as LocalLastChangedAt
}

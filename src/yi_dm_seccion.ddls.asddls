@EndUserText.label: 'DM SECCION'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_SECCION
  as select from ymmt_dm_seccion as Data
{
  key Data.seccion_id as SeccionId,
      Data.descripcion as Descripcion,
      Data.orden as Orden,
      Data.activo as Activo
}

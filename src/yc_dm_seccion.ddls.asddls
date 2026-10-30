@EndUserText.label: 'DM SECCION'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YC_DM_SECCION
  as select from YI_DM_SECCION
{
  key SeccionId,
      Descripcion,
      Orden,
      Activo
}

@EndUserText.label: 'DM SECCION'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_DM_SECCION
  as select from YI_DM_SECCION
{
  key SeccionId,
      Descripcion,
      Orden,
      Activo
}

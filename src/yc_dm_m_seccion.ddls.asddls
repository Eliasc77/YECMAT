@EndUserText.label: 'DM Secciones'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity YC_DM_M_SECCION
  provider contract transactional_query
  as projection on YI_DM_M_SECCION
{
  key SeccionId,
      Descripcion,
      Orden,
      Activo,
      LastChangedAt,
      LocalLastChangedAt
}

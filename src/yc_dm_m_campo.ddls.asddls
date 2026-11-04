@EndUserText.label: 'DM Campos'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity YC_DM_M_CAMPO
  provider contract transactional_query
  as projection on YI_DM_M_CAMPO
{
  key CampoId,
      Descripcion,
      TablaSap,
      CampoSap,
      TipoSegmento,
      TipoDato,
      Longitud,
      Decimales,
      AyudaValores,
      TipoControl,
      Activo,
      LastChangedAt,
      LocalLastChangedAt
}

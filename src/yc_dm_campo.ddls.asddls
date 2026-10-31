@EndUserText.label: 'DM CAMPO'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_DM_CAMPO
  as select from YI_DM_CAMPO
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
      Activo
}

@EndUserText.label: 'DM REGLA'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YC_DM_REGLA
  as select from YI_DM_REGLA
{
  key ReglaUUID,
      FlujoId,
      Version,
      Area,
      CampoId,
      SeccionId,
      EstadoCampo,
      Orden,
      Activo
}

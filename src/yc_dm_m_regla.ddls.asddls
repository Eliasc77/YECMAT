@EndUserText.label: 'DM Reglas'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity YC_DM_M_REGLA
  provider contract transactional_query
  as projection on YI_DM_M_REGLA
{
  key ReglaUUID,
      FlujoId,
      Version,
      Area,
      CampoId,
      SeccionId,
      EstadoCampo,
      Orden,
      Activo,
      LastChangedAt,
      LocalLastChangedAt,
      _Version : redirected to parent YC_DM_M_FLUJO_VR,
      _Flujo : redirected to YC_DM_M_FLUJO,
      _Campo : redirected to YC_DM_M_CAMPO,
      _Seccion : redirected to YC_DM_M_SECCION
}

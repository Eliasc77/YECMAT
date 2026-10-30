@EndUserText.label: 'DM SEG'
@AccessControl.authorizationCheck: #CHECK
define root view entity YC_DM_SEG
  provider contract transactional_query
  as projection on YI_DM_SEG
{
  key SegmentoUUID,
      SolicitudUUID,
      TipoSegmento,
      Estado,
      ContextoClave,
      LastChangedAt,
      _Solicitud : redirected to YC_DM_SOL,
      _Centro : redirected to composition child YC_DM_SEG_CEN,
      _Almacen : redirected to composition child YC_DM_SEG_ALM,
      _Ventas : redirected to composition child YC_DM_SEG_VEN,
      _Valoracion : redirected to composition child YC_DM_SEG_VAL,
      _Unidad : redirected to composition child YC_DM_SEG_UOM
}

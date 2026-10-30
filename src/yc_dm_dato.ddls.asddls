@EndUserText.label: 'DM DATO'
@AccessControl.authorizationCheck: #CHECK
define root view entity YC_DM_DATO
  provider contract transactional_query
  as projection on YI_DM_DATO
{
  key SegmentoUUID,
  key CampoId,
      Valor,
      ModificadoPor,
      ModificadoEl,
      _Segmento : redirected to YC_DM_SEG,
      _Campo : redirected to YC_DM_CAMPO,
      _Acceso
}

@EndUserText.label: 'DM DATO'
@AccessControl.authorizationCheck: #CHECK
define root view entity YI_DM_DATO
  as select from ymmt_dm_dato as Data
  association [1..1] to YI_DM_SEG as _Segmento
    on $projection.SegmentoUUID = _Segmento.SegmentoUUID
  association [1..1] to YI_DM_CAMPO as _Campo
    on $projection.CampoId = _Campo.CampoId
  association [0..1] to YI_DM_DATO_USR as _Acceso
    on $projection.SegmentoUUID = _Acceso.SegmentoUUID and $projection.CampoId = _Acceso.CampoId and _Acceso.Usuario = $session.user
{
  key Data.segmento_uuid as SegmentoUUID,
  key Data.campo_id as CampoId,
      Data.valor as Valor,
      @Semantics.user.lastChangedBy: true
      Data.modificado_por as ModificadoPor,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.modificado_el as ModificadoEl,
      _Segmento,
      _Campo,
      _Acceso
}

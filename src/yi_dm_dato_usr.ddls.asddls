@EndUserText.label: 'DM acceso por campo y contexto'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_DATO_USR
  as select distinct from ymmt_dm_seg as S
    inner join ymmt_dm_sol as H on H.solicitud_uuid = S.solicitud_uuid
    inner join ymmt_dm_campo as C on C.tipo_segmento = S.tipo_segmento
    inner join ymmt_dm_regla as R on R.flujo_id = H.flujo_id
      and R.version = H.version and R.campo_id = C.campo_id
{
  key S.segmento_uuid as SegmentoUUID,
  key C.campo_id as CampoId,
  key H.creado_por as Usuario
}
where R.activo = 'X' and C.activo = 'X' and R.estado_campo <> 'I'
union select distinct from ymmt_dm_seg as S
    inner join ymmt_dm_sol as H on H.solicitud_uuid = S.solicitud_uuid
    inner join ymmt_dm_campo as C on C.tipo_segmento = S.tipo_segmento
    inner join ymmt_dm_regla as R on R.flujo_id = H.flujo_id
      and R.version = H.version and R.campo_id = C.campo_id
    inner join ymmt_dm_tarea as T on T.solicitud_uuid = H.solicitud_uuid and T.area = R.area
{
  key S.segmento_uuid as SegmentoUUID,
  key C.campo_id as CampoId,
  key T.responsable as Usuario
}
where R.activo = 'X' and C.activo = 'X' and R.estado_campo <> 'I' and T.responsable <> ''

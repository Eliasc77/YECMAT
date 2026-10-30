@EndUserText.label: 'DM SEG'
@AccessControl.authorizationCheck: #CHECK
define root view entity YI_DM_SEG
  as select from ymmt_dm_seg as Data
  association [1..1] to YI_DM_SOL as _Solicitud
    on $projection.SolicitudUUID = _Solicitud.SolicitudUUID
  composition [0..1] of YI_DM_SEG_CEN as _Centro
  composition [0..1] of YI_DM_SEG_ALM as _Almacen
  composition [0..1] of YI_DM_SEG_VEN as _Ventas
  composition [0..1] of YI_DM_SEG_VAL as _Valoracion
  composition [0..1] of YI_DM_SEG_UOM as _Unidad
{
  key Data.segmento_uuid as SegmentoUUID,
      Data.solicitud_uuid as SolicitudUUID,
      Data.tipo_segmento as TipoSegmento,
      Data.estado as Estado,
      Data.contexto_clave as ContextoClave,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      _Solicitud,
      _Centro,
      _Almacen,
      _Ventas,
      _Valoracion,
      _Unidad
}

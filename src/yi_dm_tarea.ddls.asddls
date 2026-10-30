@EndUserText.label: 'DM TAREA'
@AccessControl.authorizationCheck: #CHECK
define root view entity YI_DM_TAREA
  as select from ymmt_dm_tarea as Data
  association [1..1] to YI_DM_SOL as _Solicitud
    on $projection.SolicitudUUID = _Solicitud.SolicitudUUID
  association [1..1] to YI_DM_PASO as _Paso
    on $projection.FlujoId = _Paso.FlujoId and $projection.Version = _Paso.Version and $projection.PasoId = _Paso.PasoId
{
  key Data.tarea_uuid as TareaUUID,
      Data.solicitud_uuid as SolicitudUUID,
      Data.flujo_id as FlujoId,
      Data.version as Version,
      Data.paso_id as PasoId,
      Data.area as Area,
      Data.estado as Estado,
      Data.responsable as Responsable,
      @Semantics.systemDateTime.createdAt: true
      Data.creado_el as CreadoEl,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      _Solicitud,
      _Paso
}

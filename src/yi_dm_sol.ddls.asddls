@EndUserText.label: 'DM SOL'
@AccessControl.authorizationCheck: #CHECK
define root view entity YI_DM_SOL
  as select from ymmt_dm_sol as Data
  association [1..1] to YI_DM_FLUJO_VR as _Version
    on $projection.FlujoId = _Version.FlujoId and $projection.Version = _Version.Version
  association [0..*] to YI_DM_SEG as _Segmentos
    on $projection.SolicitudUUID = _Segmentos.SolicitudUUID
  association [0..*] to YI_DM_TAREA as _Tareas
    on $projection.SolicitudUUID = _Tareas.SolicitudUUID
  association [0..1] to YI_DM_SOL_USR as _Acceso
    on $projection.SolicitudUUID = _Acceso.SolicitudUUID and _Acceso.Usuario = $session.user
{
  key Data.solicitud_uuid as SolicitudUUID,
      Data.numero_solicitud as NumeroSolicitud,
      Data.tipo_material as TipoMaterial,
      Data.tipo_operacion as TipoOperacion,
      Data.material as Material,
      Data.flujo_id as FlujoId,
      Data.version as Version,
      Data.estado as Estado,
      @Semantics.user.createdBy: true
      Data.creado_por as CreadoPor,
      @Semantics.systemDateTime.createdAt: true
      Data.creado_el as CreadoEl,
      Data.clasificacion_bpm as ClasificacionBpm,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Data.last_changed_at as LastChangedAt,
      _Version,
      _Segmentos,
      _Tareas,
      _Acceso
}

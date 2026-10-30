@EndUserText.label: 'DM FLUJO_VR'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_FLUJO_VR
  as select from ymmt_dm_flujo_vr as Data
  association [1..1] to YI_DM_FLUJO as _Flujo
    on $projection.FlujoId = _Flujo.FlujoId
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
      Data.estado as Estado,
      Data.vigente_desde as VigenteDesde,
      Data.vigente_hasta as VigenteHasta,
      @Semantics.user.createdBy: true
      Data.creado_por as CreadoPor,
      @Semantics.systemDateTime.createdAt: true
      Data.creado_el as CreadoEl,
      _Flujo
}

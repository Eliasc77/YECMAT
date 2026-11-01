@EndUserText.label: 'DM mantenimiento FLUJO_VR'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YA_DM_FLUJO_VR
  as select from ymmt_dm_flujo_vr as Data
    inner join ymmt_dm_cfg_usr as Access
      on Access.user_name = $session.user and Access.active = 'X'
{
  key Data.flujo_id as FlujoId,
  key Data.version as Version,
      Data.estado as Estado,
      Data.vigente_desde as VigenteDesde,
      Data.vigente_hasta as VigenteHasta,
      @Semantics.user.createdBy: true
      Data.creado_por as CreadoPor,
      @Semantics.systemDateTime.createdAt: true
      Data.creado_el as CreadoEl
}

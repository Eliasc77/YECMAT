@EndUserText.label: 'DM administracion de configuracion'
@AccessControl.authorizationCheck: #CHECK
define root view entity YI_DM_CFG as select from ymmt_dm_cfg_ctl
{
  key config_id as ConfigId,
      revision as Revision,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at as LastChangedAt
}

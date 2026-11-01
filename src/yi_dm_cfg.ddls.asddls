@EndUserText.label: 'DM administracion de configuracion'
@AccessControl.authorizationCheck: #CHECK
define root view entity YI_DM_CFG as select from ymmt_dm_cfg_ctl
  association [0..1] to YI_DM_CFG_USR as _Access
    on _Access.UserName = $session.user and _Access.Active = 'X'
{
  key config_id as ConfigId,
      revision as Revision,
      @Semantics.user.lastChangedBy: true
      last_changed_by as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at as LastChangedAt,
      _Access
}

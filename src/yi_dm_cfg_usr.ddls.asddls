@EndUserText.label: 'DM administradores habilitados'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity YI_DM_CFG_USR as select from ymmt_dm_cfg_usr {
  key user_name as UserName,
      active as Active
}

@EndUserText.label: 'DM administracion'
@AccessControl.authorizationCheck: #CHECK
define root view entity YC_DM_CFG
  provider contract transactional_query
  as projection on YI_DM_CFG {
  key ConfigId,
      Revision,
      LastChangedBy,
      LastChangedAt
}

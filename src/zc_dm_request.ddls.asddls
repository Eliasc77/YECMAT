@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'DM Solicitudes - consumo'
@Metadata.allowExtensions: true
define root view entity ZC_DM_Request
  provider contract transactional_query
  as projection on ZI_DM_Request
{
  key RequestUUID,
      RequestNo,
      Operation,
      Plant,
      MaterialType,
      Material,
      FlowType,
      Status,
      ParallelStartedAt,
      MaterialCreatedAt,
      ErrorText,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,
      _AreaTasks : redirected to ZC_DM_AreaTask,
      _FieldValues : redirected to ZC_DM_FieldValue
}

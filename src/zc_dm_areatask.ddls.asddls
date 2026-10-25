@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'DM Tareas - consumo'
@Metadata.allowExtensions: true
define root view entity ZC_DM_AreaTask
  provider contract transactional_query
  as projection on ZI_DM_AreaTask
{
  key AreaTaskUUID,
      RequestUUID,
      Area,
      TrafficLight,
      EnabledAt,
      StartedAt,
      FinishedAt,
      DueAt,
      ResponsibleUser,
      LastChangedBy,
      LastChangedAt
}

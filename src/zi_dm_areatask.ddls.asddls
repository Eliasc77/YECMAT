@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'DM Tarea de área'
define root view entity ZI_DM_AreaTask
  as select from zdm_req_a
{
  key area_task_uuid       as AreaTaskUUID,
      request_uuid         as RequestUUID,
      area                 as Area,
      traffic_light        as TrafficLight,
      enabled_at           as EnabledAt,
      started_at           as StartedAt,
      finished_at          as FinishedAt,
      due_at               as DueAt,
      responsible_user     as ResponsibleUser,
      last_changed_by      as LastChangedBy,
      last_changed_at      as LastChangedAt
}

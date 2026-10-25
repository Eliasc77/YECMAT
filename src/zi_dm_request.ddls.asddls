// YECMAT RAP - interfaz de solicitudes
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'DM Solicitud'
define root view entity ZI_DM_Request
  as select from zdm_req_h
  association [0..*] to ZI_DM_AreaTask as _AreaTasks
    on $projection.RequestUUID = _AreaTasks.RequestUUID
  association [0..*] to ZI_DM_FieldValue as _FieldValues
    on $projection.RequestUUID = _FieldValues.RequestUUID
{
  key request_uuid          as RequestUUID,
      request_no            as RequestNo,
      operation             as Operation,
      plant                 as Plant,
      material_type         as MaterialType,
      material              as Material,
      flow_type             as FlowType,
      status                as Status,
      parallel_started_at   as ParallelStartedAt,
      material_created_at   as MaterialCreatedAt,
      error_text            as ErrorText,
      created_by            as CreatedBy,
      created_at            as CreatedAt,
      last_changed_by       as LastChangedBy,
      last_changed_at       as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt,
      _AreaTasks,
      _FieldValues
}

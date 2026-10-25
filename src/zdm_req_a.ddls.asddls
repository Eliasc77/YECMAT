@EndUserText.label : 'DM tarea por área'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zdm_req_a {
  key client            : abap.clnt not null;
  key area_task_uuid    : sysuuid_x16 not null;
  request_uuid          : sysuuid_x16;
  area                  : abap.char(5);
  traffic_light         : abap.char(1);
  enabled_at            : abap.utclong;
  started_at            : abap.utclong;
  finished_at           : abap.utclong;
  due_at                : abap.utclong;
  responsible_user      : abap.char(12);
  last_changed_by       : abp_locinst_lastchange_user;
  last_changed_at       : abp_locinst_lastchange_tstmpl;
}

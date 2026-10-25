@EndUserText.label : 'DM solicitud de material'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zdm_req_h {
  key client            : abap.clnt not null;
  key request_uuid      : sysuuid_x16 not null;
  request_no            : abap.char(20);
  operation             : abap.char(1);
  plant                 : werks_d;
  material_type         : mtart;
  material              : matnr;
  flow_type             : abap.char(1);
  status                : abap.char(12);
  parallel_started_at   : abap.utclong;
  material_created_at   : abap.utclong;
  error_text            : abap.char(255);
  created_by            : abp_creation_user;
  created_at            : abp_creation_tstmpl;
  last_changed_by       : abp_lastchange_user;
  last_changed_at       : abp_lastchange_tstmpl;
}

@EndUserText.label : 'DM valor de campo por área'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zdm_req_f {
  key client            : abap.clnt not null;
  key field_value_uuid  : sysuuid_x16 not null;
  request_uuid          : sysuuid_x16;
  area                  : abap.char(5);
  field_name            : abap.char(40);
  field_value           : abap.string(0);
  value_unit            : msehi;
  last_changed_by       : abp_lastchange_user;
  last_changed_at       : abp_lastchange_tstmpl;
}
